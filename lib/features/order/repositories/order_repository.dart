/// Order Repository
///
/// Firestore와 연동하여 주문 데이터를 관리합니다.
/// 동시성 제어 및 서브컬렉션 관리를 포함합니다.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order_model.dart';
import '../models/order_enums.dart';

/// Order Repository Provider
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

/// 주문 데이터 관리 Repository
class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🏷️ 컬렉션 참조
  CollectionReference get _ordersCollection => _firestore.collection('orders');
  CollectionReference get _webhookLogsCollection =>
      _firestore.collection('webhook_logs');
  CollectionReference get _productsCollection =>
      _firestore.collection('products');
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// 📦 주문 상품 서브컬렉션 참조
  CollectionReference _getOrderedProductsCollection(String orderId) =>
      _ordersCollection.doc(orderId).collection('ordered_products');

  // ✅ CREATE - 주문 생성 (트랜잭션)
  ///
  /// 재고 확인 및 차감, 주문 생성을 하나의 트랜잭션으로 처리합니다.
  Future<OrderModel> createOrder({
    required String userId,
    required List<Map<String, dynamic>> cartItems, // {productId, quantity}
    required DeliveryAddress? deliveryAddress,
    String? orderNote,
  }) async {
    return await _firestore.runTransaction<OrderModel>((transaction) async {
      // 1️⃣ 재고 확인 및 차감
      final List<OrderedProduct> orderedProducts = [];
      int totalProductAmount = 0;
      bool hasDeliveryItems = false;

      for (final item in cartItems) {
        final productId = item['productId'] as String;
        final quantity = item['quantity'] as int;

        // 상품 정보 조회
        final productDoc =
            await transaction.get(_productsCollection.doc(productId));
        if (!productDoc.exists) {
          throw Exception('상품을 찾을 수 없습니다: $productId');
        }

        final productData = productDoc.data() as Map<String, dynamic>;
        final currentStock = productData['stock'] as int? ?? 0;
        final price = productData['price'] as int;
        final deliveryType =
            DeliveryType.fromString(productData['deliveryType'] as String);

        // 재고 확인
        if (currentStock < quantity) {
          throw Exception(
              '재고가 부족합니다. 상품: ${productData['name']}, 요청: $quantity, 재고: $currentStock');
        }

        // 재고 차감
        transaction.update(_productsCollection.doc(productId), {
          'stock': currentStock - quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 배송 여부 확인
        if (deliveryType == DeliveryType.delivery) {
          hasDeliveryItems = true;
        }

        // 주문 상품 생성
        final orderedProduct = OrderedProduct(
          productId: productId,
          productName: productData['name'] as String,
          productDescription: productData['description'] as String,
          productImageUrl: productData['imageUrl'] as String,
          unitPrice: price,
          quantity: quantity,
          totalPrice: price * quantity,
          deliveryType: deliveryType,
        );

        orderedProducts.add(orderedProduct);
        totalProductAmount += orderedProduct.totalPrice;
      }

      // 2️⃣ 배송비 계산
      int totalDeliveryFee = 0;
      if (hasDeliveryItems) {
        totalDeliveryFee = 3000; // 주문당 3,000원 (픽업만 있으면 0원)
      }

      // 3️⃣ 주문 생성
      final order = OrderModel.create(
        userId: userId,
        totalProductAmount: totalProductAmount,
        totalDeliveryFee: totalDeliveryFee,
        deliveryAddress: deliveryAddress,
        orderNote: orderNote,
      );

      // 4️⃣ Firestore 저장
      // 주문 저장
      transaction.set(_ordersCollection.doc(order.orderId), order.toMap());

      // 주문 상품 저장 (서브컬렉션)
      for (int i = 0; i < orderedProducts.length; i++) {
        final orderedProduct = orderedProducts[i];
        transaction.set(
          _getOrderedProductsCollection(order.orderId).doc('item_$i'),
          orderedProduct.toMap(),
        );
      }

      // 5️⃣ 사용자의 주문 목록에 추가 (역정규화)
      transaction.update(_usersCollection.doc(userId), {
        'orderIds': FieldValue.arrayUnion([order.orderId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return order;
    });
  }

  // 📖 READ - 주문 조회
  ///
  /// 주문 ID로 주문 상세 정보를 조회합니다.
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _ordersCollection.doc(orderId).get();
      if (!doc.exists) return null;

      return OrderModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('주문 조회 실패: $e');
    }
  }

  /// 주문 상품 목록 조회 (서브컬렉션)
  Future<List<OrderedProduct>> getOrderedProducts(String orderId) async {
    try {
      final snapshot = await _getOrderedProductsCollection(orderId).get();

      return snapshot.docs.map((doc) {
        return OrderedProduct.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('주문 상품 조회 실패: $e');
    }
  }

  /// 주문 + 주문 상품 통합 조회
  Future<Map<String, dynamic>?> getOrderWithProducts(String orderId) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) return null;

      final orderedProducts = await getOrderedProducts(orderId);

      return {
        'order': order,
        'orderedProducts': orderedProducts,
      };
    } catch (e) {
      throw Exception('주문 상세 조회 실패: $e');
    }
  }

  /// 사용자별 주문 목록 조회 (페이지네이션)
  Future<List<OrderModel>> getUserOrders({
    required String userId,
    int limit = 20,
    DocumentSnapshot? lastDoc,
    OrderStatus? statusFilter,
  }) async {
    try {
      Query query = _ordersCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      // 상태 필터링
      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.value);
      }

      // 페이지네이션
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      query = query.limit(limit);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('사용자 주문 목록 조회 실패: $e');
    }
  }

  // ✏️ UPDATE - 주문 상태 업데이트
  ///
  /// 주문 상태를 업데이트합니다. 상태 전환 규칙을 확인합니다.
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? reason,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 현재 주문 조회
        final orderDoc = await transaction.get(_ordersCollection.doc(orderId));
        if (!orderDoc.exists) {
          throw Exception('주문을 찾을 수 없습니다: $orderId');
        }

        final currentOrder =
            OrderModel.fromMap(orderDoc.data() as Map<String, dynamic>);

        // 상태 전환 가능한지 확인
        if (!currentOrder.canTransitionTo(newStatus)) {
          throw Exception(
              '상태 전환이 불가능합니다: ${currentOrder.status.displayName} → ${newStatus.displayName}');
        }

        // 업데이트 데이터 준비
        final updateData = <String, dynamic>{
          'status': newStatus.value,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // 취소의 경우 추가 정보
        if (newStatus == OrderStatus.cancelled) {
          updateData['cancelReason'] = reason;
          updateData['canceledAt'] = FieldValue.serverTimestamp();
        }

        // 주문 업데이트
        transaction.update(_ordersCollection.doc(orderId), updateData);
      });
    } catch (e) {
      throw Exception('주문 상태 업데이트 실패: $e');
    }
  }

  /// 결제 정보 업데이트
  Future<void> updatePaymentInfo({
    required String orderId,
    required PaymentInfo paymentInfo,
  }) async {
    try {
      await _ordersCollection.doc(orderId).update({
        'paymentInfo': paymentInfo.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('결제 정보 업데이트 실패: $e');
    }
  }

  /// 픽업 인증 업데이트
  Future<void> updatePickupVerification({
    required String orderId,
    required String pickupImageUrl,
  }) async {
    try {
      await _ordersCollection.doc(orderId).update({
        'pickupImageUrl': pickupImageUrl,
        'isPickupVerified': true,
        'pickupVerifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('픽업 인증 업데이트 실패: $e');
    }
  }

  /// 개별 상품 상태 업데이트
  Future<void> updateOrderedProductStatus({
    required String orderId,
    required String productDocId,
    required OrderItemStatus newStatus,
    String? pickupImageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'itemStatus': newStatus.value,
      };

      if (pickupImageUrl != null) {
        updateData['pickupImageUrl'] = pickupImageUrl;
        updateData['isPickupVerified'] = true;
        updateData['pickupVerifiedAt'] = FieldValue.serverTimestamp();
      }

      await _getOrderedProductsCollection(orderId)
          .doc(productDocId)
          .update(updateData);
    } catch (e) {
      throw Exception('주문 상품 상태 업데이트 실패: $e');
    }
  }

  // ❌ CANCEL - 주문 취소
  ///
  /// 주문을 취소하고 재고를 복구합니다.
  Future<void> cancelOrder({
    required String orderId,
    required String cancelReason,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 1️⃣ 주문 조회
        final orderDoc = await transaction.get(_ordersCollection.doc(orderId));
        if (!orderDoc.exists) {
          throw Exception('주문을 찾을 수 없습니다: $orderId');
        }

        final order =
            OrderModel.fromMap(orderDoc.data() as Map<String, dynamic>);

        // 취소 가능한지 확인
        if (!order.isCancellable) {
          throw Exception('취소할 수 없는 주문입니다: ${order.status.displayName}');
        }

        // 2️⃣ 재고 복구
        final orderedProductsSnapshot =
            await _getOrderedProductsCollection(orderId).get();

        for (final doc in orderedProductsSnapshot.docs) {
          final orderedProduct =
              OrderedProduct.fromMap(doc.data() as Map<String, dynamic>);

          // 상품 재고 복구
          final productDoc = await transaction
              .get(_productsCollection.doc(orderedProduct.productId));
          if (productDoc.exists) {
            final currentStock =
                (productDoc.data() as Map<String, dynamic>)['stock'] as int;
            transaction
                .update(_productsCollection.doc(orderedProduct.productId), {
              'stock': currentStock + orderedProduct.quantity,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        // 3️⃣ 주문 상태 업데이트
        transaction.update(_ordersCollection.doc(orderId), {
          'status': OrderStatus.cancelled.value,
          'cancelReason': cancelReason,
          'canceledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('주문 취소 실패: $e');
    }
  }

  // 🎣 WEBHOOK - 웹훅 로그 관리
  ///
  /// 웹훅 로그를 저장합니다.
  Future<void> saveWebhookLog(OrderWebhookLog log) async {
    try {
      await _webhookLogsCollection.doc(log.logId).set(log.toMap());
    } catch (e) {
      throw Exception('웹훅 로그 저장 실패: $e');
    }
  }

  /// 웹훅 로그 업데이트
  Future<void> updateWebhookLog({
    required String logId,
    required bool isProcessed,
    String? processResult,
    String? errorMessage,
    int? retryCount,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'isProcessed': isProcessed,
        'processedAt': FieldValue.serverTimestamp(),
      };

      if (processResult != null) updateData['processResult'] = processResult;
      if (errorMessage != null) updateData['errorMessage'] = errorMessage;
      if (retryCount != null) updateData['retryCount'] = retryCount;

      await _webhookLogsCollection.doc(logId).update(updateData);
    } catch (e) {
      throw Exception('웹훅 로그 업데이트 실패: $e');
    }
  }

  /// 처리되지 않은 웹훅 로그 조회
  Future<List<OrderWebhookLog>> getUnprocessedWebhookLogs({
    int limit = 50,
  }) async {
    try {
      final snapshot = await _webhookLogsCollection
          .where('isProcessed', isEqualTo: false)
          .orderBy('receivedAt')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return OrderWebhookLog.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('미처리 웹훅 로그 조회 실패: $e');
    }
  }

  // 📊 STATISTICS - 통계 조회
  ///
  /// 사용자별 주문 통계
  Future<Map<String, dynamic>> getUserOrderStats(String userId) async {
    try {
      final ordersSnapshot =
          await _ordersCollection.where('userId', isEqualTo: userId).get();

      final orders = ordersSnapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      // 통계 계산
      int totalOrders = orders.length;
      int completedOrders =
          orders.where((o) => o.status == OrderStatus.finished).length;
      int canceledOrders =
          orders.where((o) => o.status == OrderStatus.cancelled).length;
      int totalAmount = orders.fold(0, (sum, order) => sum + order.totalAmount);

      return {
        'totalOrders': totalOrders,
        'completedOrders': completedOrders,
        'canceledOrders': canceledOrders,
        'totalAmount': totalAmount,
        'averageOrderAmount': totalOrders > 0 ? totalAmount / totalOrders : 0,
      };
    } catch (e) {
      throw Exception('주문 통계 조회 실패: $e');
    }
  }

  // 🔍 SEARCH - 검색 기능
  ///
  /// 주문 ID나 결제 키로 주문 검색
  Future<OrderModel?> searchOrderByPaymentKey(String paymentKey) async {
    try {
      final snapshot = await _ordersCollection
          .where('paymentInfo.paymentKey', isEqualTo: paymentKey)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return OrderModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('결제 키로 주문 검색 실패: $e');
    }
  }
}
