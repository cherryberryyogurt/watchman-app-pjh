/// Order Repository
///
/// Firestore와 연동하여 주문 데이터를 관리합니다.
/// 동시성 제어 및 서브컬렉션 관리를 포함합니다.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../models/payment_info_model.dart';
import '../models/order_webhook_log_model.dart';
import '../models/order_enums.dart';
import '../../cart/models/cart_item_model.dart';

/// 페이지네이션된 주문 쿼리 결과를 담는 클래스
class OrderQueryResult {
  final List<OrderModel> orders;
  final DocumentSnapshot? lastDocument;

  OrderQueryResult({required this.orders, this.lastDocument});
}

/// Order Repository Provider
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

/// 주문 데이터 관리 Repository
class OrderRepository {
  final FirebaseFirestore _firestore;

  /// 의존성 주입을 지원하는 생성자
  OrderRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

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

  // ✅ CREATE - 주문 생성
  ///
  /// 웹 환경에서는 배치 쓰기를, 모바일에서는 트랜잭션을 사용합니다.
  Future<OrderModel> createOrder({
    required String userId,
    required String userName,
    String? userContact,
    String? locationTagId,
    String? locationTagName,
    required List<Map<String, dynamic>> cartItems, // {productId, quantity}
    required String deliveryType, // 사용자가 선택한 배송 유형
    required DeliveryAddress? deliveryAddress,
    String? orderNote,
    Map<String, dynamic>? selectedPickupPointInfo,
  }) async {
    if (kIsWeb) {
      return _createOrderWithBatch(
        userId: userId,
        userName: userName,
        userContact: userContact,
        locationTagId: locationTagId,
        locationTagName: locationTagName,
        cartItems: cartItems,
        deliveryType: deliveryType,
        deliveryAddress: deliveryAddress,
        orderNote: orderNote,
        selectedPickupPointInfo: selectedPickupPointInfo,
      );
    } else {
      return _createOrderWithTransaction(
        userId: userId,
        userName: userName,
        userContact: userContact,
        locationTagId: locationTagId,
        locationTagName: locationTagName,
        cartItems: cartItems,
        deliveryType: deliveryType,
        deliveryAddress: deliveryAddress,
        orderNote: orderNote,
        selectedPickupPointInfo: selectedPickupPointInfo,
      );
    }
  }

  /// 웹 환경용 배치 주문 생성 (per-unit 재고 관리)
  Future<OrderModel> _createOrderWithBatch({
    required String userId,
    required String userName,
    String? userContact,
    String? locationTagId,
    String? locationTagName,
    required List<Map<String, dynamic>> cartItems,
    required String deliveryType, // 사용자가 선택한 배송 유형
    required DeliveryAddress? deliveryAddress,
    String? orderNote,
    Map<String, dynamic>? selectedPickupPointInfo,
  }) async {
    debugPrint('💻 웹 환경: 배치로 주문 생성 (per-unit 재고)');
    debugPrint('🔄 Firestore 배치 시작 (3단계 분리 구조)');

    try {
      // 🔍 1단계: 모든 읽기 작업 먼저 완료
      debugPrint('📋 1단계: 모든 읽기 작업 시작 (${cartItems.length}개 상품)');

      // 모든 상품 문서 읽기
      final List<DocumentSnapshot> productDocs = [];
      for (final item in cartItems) {
        final productId = item['productId'] as String;
        debugPrint('🔍 상품 문서 읽기: $productId');
        final productDoc = await _productsCollection.doc(productId).get();
        productDocs.add(productDoc);
      }

      // 사용자 문서 읽기 (이미 전달받은 정보를 사용하므로 실제로는 읽지 않음)
      debugPrint(
          '✅ 사용자 정보 (전달받음): 이름=$userName, 연락처=$userContact, 위치=${locationTagName ?? "미설정"}');
      final userDoc = await _usersCollection.doc(userId).get();

      debugPrint('✅ 1단계 완료: 모든 읽기 작업 완료');

      // 🔄 2단계: 메모리에서 데이터 검증 및 처리 (쓰기 작업 없음)
      debugPrint('📋 2단계: 데이터 검증 및 처리 시작');

      final List<OrderedProduct> orderedProducts = [];
      final List<Map<String, dynamic>> stockUpdates = [];
      final List<CartItemModel> cartItemModels = [];
      bool hasDeliveryItems = false;

      for (int i = 0; i < cartItems.length; i++) {
        final item = cartItems[i];
        final productDoc = productDocs[i];
        final productId = item['productId'] as String;
        final cartItemId = item['id'] as String;
        final quantity = item['quantity'] as int;
        final price = item['price'] as int;

        // 상품 존재 확인
        if (!productDoc.exists) {
          debugPrint('❌ 상품을 찾을 수 없음: $productId');
          throw Exception('상품을 찾을 수 없습니다: $productId');
        }

        final productData = productDoc.data() as Map<String, dynamic>;
        final deliveryType =
            DeliveryType.fromString(productData['deliveryType'] as String);
        final isTaxFree = item['isTaxFree'] as bool? ?? false;
        final selectedUnit = item['selectedUnit'] as String? ??
            item['productOrderUnit'] as String? ??
            '1개';

        // per-unit 재고 확인
        final orderUnits =
            List<Map<String, dynamic>>.from(productData['orderUnits'] ?? []);
        Map<String, dynamic>? targetUnit;
        String? targetUnitId;
        for (final unitData in orderUnits) {
          if (unitData['unit'] == selectedUnit) {
            targetUnit = unitData;
            targetUnitId = unitData['id'] as String?;
            break;
          }
        }

        if (targetUnit == null) {
          final productName = productData['name'] ?? productId;
          throw Exception(
              '상품 "$productName"에서 주문 단위 "$selectedUnit"를 찾을 수 없습니다.');
        }

        final currentStock = targetUnit['stock'] as int? ?? 0;
        final unitPrice = targetUnit['price'] as int? ?? price;

        // 재고 확인
        if (currentStock < quantity) {
          final productName = productData['name'] ?? productId;
          debugPrint(
              '❌ 재고 부족: $productName ($selectedUnit) (현재: ${currentStock}개, 요청: ${quantity}개)');
          throw Exception(
              '상품 "$productName" ($selectedUnit)의 재고가 부족합니다. (현재: ${currentStock}개, 요청: ${quantity}개)');
        }

        // 배송 여부 확인
        if (deliveryType == DeliveryType.delivery) {
          hasDeliveryItems = true;
        }

        // CartItemModel 생성 (세금 계산용)
        final cartItemModel = CartItemModel(
          id: cartItemId,
          productId: productId,
          productName: item['productName'] as String? ??
              productData['name'] as String? ??
              '상품명 없음',
          quantity: quantity,
          productPrice: unitPrice,
          thumbnailUrl: item['thumbnailUrl'] as String?,
          productOrderUnit: selectedUnit,
          addedAt: Timestamp.now(),
          productDeliveryType: deliveryType.value,
          isTaxFree: isTaxFree,
        );
        cartItemModels.add(cartItemModel);

        // 주문 상품 생성 (메모리 작업만)
        final orderedProduct = OrderedProduct(
          cartItemId: cartItemId,
          productId: productId,
          productName: cartItemModel.productName,
          productDescription: productData['description'] as String? ?? '',
          productImageUrl: cartItemModel.thumbnailUrl ??
              productData['imageUrl'] as String? ??
              '',
          orderedUnit: {
            'id': targetUnitId,
            'unit': selectedUnit,
            'quantity': quantity,
            'price': unitPrice,
            'stock': currentStock,
          },
          totalPrice: unitPrice * quantity,
          deliveryType: deliveryType,
          isTaxFree: isTaxFree,
        );

        orderedProducts.add(orderedProduct);

        // 재고 업데이트 정보 저장 (아직 실행하지 않음)
        stockUpdates.add({
          'productId': productId,
          'unit': selectedUnit,
          'newStock': currentStock - quantity,
        });

        debugPrint(
            '✅ 상품 검증 완료: ${orderedProduct.productName} ($selectedUnit × ${quantity}개, ${unitPrice}원, 면세: ${isTaxFree})');
      }

      // 배송비 계산
      int totalDeliveryFee = 0; // TODO:도서산간 배송비 계산 로직 추가 필요

      // 📦 상품 요약 정보 계산 (비정규화)
      String? representativeProductName;
      int totalProductCount = 0;

      if (orderedProducts.isNotEmpty) {
        // 첫 번째 상품명을 대표 상품명으로 설정
        representativeProductName = orderedProducts.first.productName;

        // 전체 상품 개수 계산 (수량 합계)
        totalProductCount = orderedProducts.fold(
            0, (sum, product) => sum + (product.orderedUnit['quantity'] as num).toInt());
      }

      // 주문 생성 (세금 계산 포함)
      final order = OrderModel.withTaxCalculation(
        userId: userId,
        userName: userName,
        userContact: userContact,
        locationTagId: locationTagId,
        locationTagName: locationTagName,
        items: cartItemModels,
        deliveryFee: totalDeliveryFee,
        deliveryType: deliveryType,
        deliveryAddress: deliveryAddress,
        orderNote: orderNote,
        representativeProductName: representativeProductName,
        totalProductCount: totalProductCount,
        selectedPickupPointInfo: selectedPickupPointInfo,
      );

      debugPrint(
          '✅ 2단계 완료: 주문 정보 생성 완료 (총 ${orderedProducts.length}개 상품, 총액: ${order.totalAmount}원, 면세액: ${order.taxFreeAmount}원)');

      // ✏️ 3단계: 모든 쓰기 작업 수행 (배치)
      debugPrint('📋 3단계: 모든 쓰기 작업 시작 (배치)');
      final batch = _firestore.batch();

      // 상품 재고 업데이트 (per-unit)
      // 배치에서는 미리 읽은 데이터를 사용하여 업데이트
      final Map<String, List<Map<String, dynamic>>> productOrderUnitsMap = {};
      final Map<String, Map<String, int>> stockDeductions = {}; // productId -> {unit -> totalQuantity}

      // 기존에 읽은 productDocs에서 orderUnits 정보 추출
      for (int i = 0; i < cartItems.length; i++) {
        final productId = cartItems[i]['productId'] as String;
        final productDoc = productDocs[i];
        if (productDoc.exists) {
          final productData = productDoc.data() as Map<String, dynamic>;
          if (!productOrderUnitsMap.containsKey(productId)) {
            productOrderUnitsMap[productId] =
                List<Map<String, dynamic>>.from(productData['orderUnits'] ?? []);
          }
        }
      }

      // 모든 재고 업데이트를 제품별, 단위별로 집계
      for (final update in stockUpdates) {
        final productId = update['productId'] as String;
        final unit = update['unit'] as String;
        final currentStock = update['newStock'] as int;
        final originalQuantity = cartItems.firstWhere(
          (item) => item['productId'] == productId && 
                   (item['selectedUnit'] ?? item['productOrderUnit'] ?? '1개') == unit
        )['quantity'] as int;

        stockDeductions.putIfAbsent(productId, () => {});
        stockDeductions[productId]!.putIfAbsent(unit, () => 0);
        stockDeductions[productId]![unit] = stockDeductions[productId]![unit]! + originalQuantity;
      }

      // 제품별로 한 번씩만 업데이트 수행
      for (final productId in stockDeductions.keys) {
        final orderUnits = productOrderUnitsMap[productId];
        if (orderUnits != null) {
          // 해당 제품의 모든 단위 재고를 한 번에 업데이트
          final updatedOrderUnits = orderUnits.map((unitData) {
            final unitMap = Map<String, dynamic>.from(unitData);
            final unit = unitMap['unit'] as String;
            if (stockDeductions[productId]!.containsKey(unit)) {
              final currentStock = unitMap['stock'] as int;
              final deductionAmount = stockDeductions[productId]![unit]!;
              unitMap['stock'] = currentStock - deductionAmount;
              debugPrint('📝 재고 업데이트: $productId ($unit) ${currentStock} → ${currentStock - deductionAmount}개 (차감: ${deductionAmount}개)');
            }
            return unitMap;
          }).toList();

          batch.update(_productsCollection.doc(productId), {
            'orderUnits': updatedOrderUnits,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 주문 저장 (DeliveryAddress 객체 직렬화 처리)
      final orderData = order.toMap();
      if (order.selectedPickupPointInfo != null) {
        orderData['selectedPickupPointInfo'] = order.selectedPickupPointInfo;
      }
      if (orderData['deliveryAddress'] != null &&
          orderData['deliveryAddress'] is DeliveryAddress) {
        orderData['deliveryAddress'] =
            (orderData['deliveryAddress'] as DeliveryAddress).toMap();
      }
      batch.set(_ordersCollection.doc(order.orderId), orderData);
      debugPrint('📝 주문 저장: ${order.orderId}');

      // 주문 상품 저장 (서브컬렉션)
      for (int i = 0; i < orderedProducts.length; i++) {
        final orderedProduct = orderedProducts[i];
        batch.set(
          _getOrderedProductsCollection(order.orderId).doc('item_$i'),
          orderedProduct.toMap(),
        );
      }
      debugPrint('📝 주문 상품 저장: ${orderedProducts.length}개');

      // 사용자 문서 업데이트
      if (userDoc.exists) {
        batch.update(_usersCollection.doc(userId), {
          'orderIds': FieldValue.arrayUnion([order.orderId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('📝 사용자 문서 업데이트: $userId');
      } else {
        batch.set(_usersCollection.doc(userId), {
          'orderIds': [order.orderId],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('📝 사용자 문서 생성: $userId');
      }

      // 배치 실행
      await batch.commit();

      debugPrint('✅ 3단계 완료: 모든 쓰기 작업 완료');
      debugPrint('🎉 배치 쓰기 성공: 주문 ${order.orderId} 생성 완료');

      return order;
    } catch (e, stackTrace) {
      debugPrint('❌ 배치 쓰기 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      rethrow;
    }
  }

  /// 모바일 환경용 트랜잭션 주문 생성 (per-unit 재고 관리)
  Future<OrderModel> _createOrderWithTransaction({
    required String userId,
    required String userName,
    String? userContact,
    String? locationTagId,
    String? locationTagName,
    required List<Map<String, dynamic>> cartItems,
    required String deliveryType, // 사용자가 선택한 배송 유형
    required DeliveryAddress? deliveryAddress,
    String? orderNote,
    Map<String, dynamic>? selectedPickupPointInfo,
  }) async {
    debugPrint('📱 모바일 환경: 트랜잭션으로 주문 생성 (per-unit 재고)');
    debugPrint('🔄 Firestore 트랜잭션 시작 (3단계 분리 구조)');

    return await _firestore.runTransaction<OrderModel>((transaction) async {
      // 🔍 1단계: 모든 읽기 작업 먼저 완료
      debugPrint('📋 1단계: 모든 읽기 작업 시작 (${cartItems.length}개 상품)');

      // 모든 상품 문서 읽기
      final List<DocumentSnapshot> productDocs = [];
      for (final item in cartItems) {
        final productId = item['productId'] as String;
        debugPrint('🔍 상품 문서 읽기: $productId');
        final productDoc =
            await transaction.get(_productsCollection.doc(productId));
        productDocs.add(productDoc);
      }

      // 사용자 문서 읽기 (이미 전달받은 정보를 사용하므로 실제로는 읽지 않음)
      debugPrint(
          '✅ 사용자 정보 (전달받음): 이름=$userName, 연락처=$userContact, 위치=${locationTagName ?? "미설정"}');
      final userDoc = await transaction.get(_usersCollection.doc(userId));

      debugPrint('✅ 1단계 완료: 모든 읽기 작업 완료');

      // 🔄 2단계: 메모리에서 데이터 검증 및 처리 (쓰기 작업 없음)
      debugPrint('📋 2단계: 데이터 검증 및 처리 시작');

      final List<OrderedProduct> orderedProducts = [];
      final List<Map<String, dynamic>> stockUpdates = [];
      final List<CartItemModel> cartItemModels = [];
      bool hasDeliveryItems = false;

      for (int i = 0; i < cartItems.length; i++) {
        final item = cartItems[i];
        final productDoc = productDocs[i];
        final productId = item['productId'] as String;
        final cartItemId = item['id'] as String;
        final quantity = item['quantity'] as int;
        final price = item['price'] as int;

        // 상품 존재 확인
        if (!productDoc.exists) {
          debugPrint('❌ 상품을 찾을 수 없음: $productId');
          throw Exception('상품을 찾을 수 없습니다: $productId');
        }

        final productData = productDoc.data() as Map<String, dynamic>;
        final deliveryType =
            DeliveryType.fromString(productData['deliveryType'] as String);
        final isTaxFree = item['isTaxFree'] as bool? ?? false;
        final selectedUnit = item['selectedUnit'] as String? ??
            item['productOrderUnit'] as String? ??
            '1개';

        // per-unit 재고 확인
        final orderUnits =
            List<Map<String, dynamic>>.from(productData['orderUnits'] ?? []);
        Map<String, dynamic>? targetUnit;
        String? targetUnitId;
        for (final unitData in orderUnits) {
          if (unitData['unit'] == selectedUnit) {
            targetUnit = unitData;
            targetUnitId = unitData['id'] as String?;
            break;
          }
        }

        if (targetUnit == null) {
          final productName = productData['name'] ?? productId;
          throw Exception(
              '상품 "$productName"에서 주문 단위 "$selectedUnit"를 찾을 수 없습니다.');
        }

        final currentStock = targetUnit['stock'] as int? ?? 0;
        final unitPrice = targetUnit['price'] as int? ?? price;

        // 재고 확인
        if (currentStock < quantity) {
          final productName = productData['name'] ?? productId;
          debugPrint(
              '❌ 재고 부족: $productName ($selectedUnit) (현재: ${currentStock}개, 요청: ${quantity}개)');
          throw Exception(
              '상품 "$productName" ($selectedUnit)의 재고가 부족합니다. (현재: ${currentStock}개, 요청: ${quantity}개)');
        }

        // 배송 여부 확인
        if (deliveryType == DeliveryType.delivery) {
          hasDeliveryItems = true;
        }

        // CartItemModel 생성 (세금 계산용)
        final cartItemModel = CartItemModel(
          id: cartItemId,
          productId: productId,
          productName: item['productName'] as String? ??
              productData['name'] as String? ??
              '상품명 없음',
          quantity: quantity,
          productPrice: unitPrice,
          thumbnailUrl: item['thumbnailUrl'] as String?,
          productOrderUnit: selectedUnit,
          addedAt: Timestamp.now(),
          productDeliveryType: deliveryType.value,
          isTaxFree: isTaxFree,
        );
        cartItemModels.add(cartItemModel);

        // 주문 상품 생성 (메모리 작업만)
        final orderedProduct = OrderedProduct(
          cartItemId: cartItemId,
          productId: productId,
          productName: cartItemModel.productName,
          productDescription: productData['description'] as String? ?? '',
          productImageUrl: cartItemModel.thumbnailUrl ??
              productData['imageUrl'] as String? ??
              '',
          orderedUnit: {
            'id': targetUnitId,
            'unit': selectedUnit,
            'quantity': quantity,
            'price': unitPrice,
            'stock': currentStock,
          },
          totalPrice: unitPrice * quantity,
          deliveryType: deliveryType,
          isTaxFree: isTaxFree,
        );

        orderedProducts.add(orderedProduct);

        // 재고 업데이트 정보 저장 (아직 실행하지 않음)
        stockUpdates.add({
          'productId': productId,
          'unit': selectedUnit,
          'newStock': currentStock - quantity,
        });

        debugPrint(
            '✅ 상품 검증 완료: ${orderedProduct.productName} ($selectedUnit × ${quantity}개, ${unitPrice}원, 면세: ${isTaxFree})');
      }

      // 배송비 계산
      int totalDeliveryFee = 0; // TODO:도서산간 배송비 계산 로직 추가 필요

      // 📦 상품 요약 정보 계산 (비정규화)
      String? representativeProductName;
      int totalProductCount = 0;

      if (orderedProducts.isNotEmpty) {
        // 첫 번째 상품명을 대표 상품명으로 설정
        representativeProductName = orderedProducts.first.productName;

        // 전체 상품 개수 계산 (수량 합계)
        totalProductCount = orderedProducts.fold(
            0, (sum, product) => sum + (product.orderedUnit['quantity'] as num).toInt());
      }

      // 주문 생성 (세금 계산 포함)
      final order = OrderModel.withTaxCalculation(
        userId: userId,
        userName: userName,
        userContact: userContact,
        locationTagId: locationTagId,
        locationTagName: locationTagName,
        items: cartItemModels,
        deliveryFee: totalDeliveryFee,
        deliveryType: deliveryType,
        deliveryAddress: deliveryAddress,
        orderNote: orderNote,
        representativeProductName: representativeProductName,
        totalProductCount: totalProductCount,
        selectedPickupPointInfo: selectedPickupPointInfo,
      );

      debugPrint(
          '✅ 2단계 완료: 주문 정보 생성 완료 (총 ${orderedProducts.length}개 상품, 총액: ${order.totalAmount}원, 면세액: ${order.taxFreeAmount}원)');

      // ✏️ 3단계: 모든 쓰기 작업 수행
      debugPrint('📋 3단계: 모든 쓰기 작업 시작');

      // 상품 재고 업데이트 (per-unit)
      final Map<String, Map<String, int>> stockDeductions = {}; // productId -> {unit -> totalQuantity}
      final Set<String> processedProducts = {};

      // 모든 재고 업데이트를 제품별, 단위별로 집계
      for (final update in stockUpdates) {
        final productId = update['productId'] as String;
        final unit = update['unit'] as String;
        final currentStock = update['newStock'] as int;
        final originalQuantity = cartItems.firstWhere(
          (item) => item['productId'] == productId && 
                   (item['selectedUnit'] ?? item['productOrderUnit'] ?? '1개') == unit
        )['quantity'] as int;

        stockDeductions.putIfAbsent(productId, () => {});
        stockDeductions[productId]!.putIfAbsent(unit, () => 0);
        stockDeductions[productId]![unit] = stockDeductions[productId]![unit]! + originalQuantity;
      }

      // 제품별로 한 번씩만 업데이트 수행
      for (final productId in stockDeductions.keys) {
        if (processedProducts.contains(productId)) continue;
        processedProducts.add(productId);

        // 트랜잭션에서 상품 문서 다시 읽기
        final productDoc =
            await transaction.get(_productsCollection.doc(productId));
        if (productDoc.exists) {
          final productData = productDoc.data() as Map<String, dynamic>;
          final orderUnits =
              List<Map<String, dynamic>>.from(productData['orderUnits'] ?? []);

          // 해당 제품의 모든 단위 재고를 한 번에 업데이트
          final updatedOrderUnits = orderUnits.map((unitData) {
            final unitMap = Map<String, dynamic>.from(unitData);
            final unit = unitMap['unit'] as String;
            if (stockDeductions[productId]!.containsKey(unit)) {
              final currentStock = unitMap['stock'] as int;
              final deductionAmount = stockDeductions[productId]![unit]!;
              unitMap['stock'] = currentStock - deductionAmount;
              debugPrint('📝 재고 업데이트: $productId ($unit) ${currentStock} → ${currentStock - deductionAmount}개 (차감: ${deductionAmount}개)');
            }
            return unitMap;
          }).toList();

          transaction.update(_productsCollection.doc(productId), {
            'orderUnits': updatedOrderUnits,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 주문 저장 (DeliveryAddress 객체 직렬화 처리)
      final orderData = order.toMap();
      if (order.selectedPickupPointInfo != null) {
        orderData['selectedPickupPointInfo'] = order.selectedPickupPointInfo;
      }
      if (orderData['deliveryAddress'] != null &&
          orderData['deliveryAddress'] is DeliveryAddress) {
        orderData['deliveryAddress'] =
            (orderData['deliveryAddress'] as DeliveryAddress).toMap();
      }
      transaction.set(_ordersCollection.doc(order.orderId), orderData);
      debugPrint('📝 주문 저장: ${order.orderId}');

      // 주문 상품 저장 (서브컬렉션)
      for (int i = 0; i < orderedProducts.length; i++) {
        final orderedProduct = orderedProducts[i];
        transaction.set(
          _getOrderedProductsCollection(order.orderId).doc('item_$i'),
          orderedProduct.toMap(),
        );
      }
      debugPrint('📝 주문 상품 저장: ${orderedProducts.length}개');

      // 사용자 문서 업데이트
      if (userDoc.exists) {
        transaction.update(_usersCollection.doc(userId), {
          'orderIds': FieldValue.arrayUnion([order.orderId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('📝 사용자 문서 업데이트: $userId');
      } else {
        transaction.set(_usersCollection.doc(userId), {
          'orderIds': [order.orderId],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('📝 사용자 문서 생성: $userId');
      }

      debugPrint('✅ 3단계 완료: 모든 쓰기 작업 완료');
      debugPrint('🎉 트랜잭션 성공: 주문 ${order.orderId} 생성 완료');

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
  Future<OrderQueryResult> getUserOrders({
    required String userId,
    int limit = 20,
    DocumentSnapshot? lastDoc,
    OrderStatus? statusFilter,
  }) async {
    try {
      debugPrint('🔍 getUserOrders 시작');
      debugPrint('🔍 userId: $userId');
      debugPrint('🔍 limit: $limit');
      debugPrint('🔍 lastDoc: $lastDoc');
      debugPrint('🔍 statusFilter: $statusFilter');

      Query query = _ordersCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      debugPrint('🔍 기본 쿼리 생성 완료: userId = $userId');

      // 상태 필터링
      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.value);
        debugPrint('🔍 상태 필터 추가: ${statusFilter.value}');
      }

      // 페이지네이션
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
        debugPrint('🔍 페이지네이션 시작점 설정');
      }

      query = query.limit(limit);
      debugPrint('🔍 limit 설정: $limit');

      debugPrint('🔍 Firestore 쿼리 실행 시작...');
      final snapshot = await query.get();
      debugPrint('🔍 Firestore 쿼리 실행 완료');
      debugPrint('🔍 조회된 문서 수: ${snapshot.docs.length}');

      // 조회된 문서들의 기본 정보 출력
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data() as Map<String, dynamic>;
        debugPrint(
            '🔍 문서 $i: ID=${doc.id}, userId=${data['userId']}, status=${data['status']}, totalAmount=${data['totalAmount']}');
      }

      final List<OrderModel> orders = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('🔍 OrderModel 변환 중: ${doc.id}');

        try {
          // 🔍 필수 필드 검증 및 디버깅
          final orderId = data['orderId'];
          final userId = data['userId'];
          final status = data['status'];
          final createdAt = data['createdAt'];
          final updatedAt = data['updatedAt'];

          debugPrint(
              '🔍 필수 필드 체크: orderId=$orderId, userId=$userId, status=$status');
          debugPrint('🔍 시간 필드 체크: createdAt=$createdAt, updatedAt=$updatedAt');

          // 필수 필드가 null인 경우 에러 로그
          if (orderId == null) {
            debugPrint('❌ orderId가 null입니다: ${doc.id}');
            throw Exception('orderId가 null입니다');
          }
          if (userId == null) {
            debugPrint('❌ userId가 null입니다: ${doc.id}');
            throw Exception('userId가 null입니다');
          }
          if (status == null) {
            debugPrint('❌ status가 null입니다: ${doc.id}');
            throw Exception('status가 null입니다');
          }
          if (createdAt == null) {
            debugPrint('❌ createdAt가 null입니다: ${doc.id}');
            throw Exception('createdAt가 null입니다');
          }
          if (updatedAt == null) {
            debugPrint('❌ updatedAt가 null입니다: ${doc.id}');
            throw Exception('updatedAt가 null입니다');
          }

          final order = OrderModel.fromMap(data);
          orders.add(order);
          debugPrint('✅ OrderModel 변환 성공: ${doc.id}');
        } catch (e) {
          debugPrint('❌ OrderModel 변환 실패: ${doc.id}, 에러: $e');
          debugPrint('❌ 문서 데이터: $data');

          // 실패한 주문은 건너뛰고 계속 진행
          debugPrint('⚠️ 주문 ${doc.id} 건너뛰기');
        }
      }

      // 페이지네이션을 위한 마지막 문서 추출
      final lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      debugPrint('🔍 getUserOrders 완료 - 반환할 주문 수: ${orders.length}');
      debugPrint('🔍 lastDocument: ${lastDocument?.id}');

      return OrderQueryResult(orders: orders, lastDocument: lastDocument);
    } catch (e) {
      debugPrint('🔍 getUserOrders 에러: $e');
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

  // ❌ CANCEL - 주문 취소 (Firebase Function 호출)
  ///
  /// Firebase Function을 통해 주문을 취소합니다.
  /// 결제 취소, 재고 복구, 주문 상태 업데이트가 서버에서 트랜잭션으로 처리됩니다.
  Future<Map<String, dynamic>> cancelOrder({
    required String orderId,
    required String cancelReason,
    String? paymentKey,
    int? cancelAmount,
  }) async {
    try {
      // 1️⃣ 주문 정보 조회 (paymentKey가 없는 경우)
      if (paymentKey == null) {
        final orderDoc = await _ordersCollection.doc(orderId).get();
        if (!orderDoc.exists) {
          throw Exception('주문을 찾을 수 없습니다: $orderId');
        }

        final order =
            OrderModel.fromMap(orderDoc.data() as Map<String, dynamic>);
        paymentKey = order.paymentInfo?.paymentKey;

        if (paymentKey == null) {
          throw Exception('결제 키를 찾을 수 없습니다');
        }
      }

      // 2️⃣ Firebase Function 호출
      final callable =
          FirebaseFunctions.instance.httpsCallable('cancelPayment');

      final result = await callable.call<Map<String, dynamic>>({
        'paymentKey': paymentKey,
        'orderId': orderId,
        'cancelReason': cancelReason,
        if (cancelAmount != null) 'cancelAmount': cancelAmount,
      });

      debugPrint('✅ 주문 취소 성공: ${result.data}');
      return result.data;
    } catch (e) {
      debugPrint('❌ 주문 취소 실패: $e');
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

  /// 부분 환불 기록 추가 및 결제 정보 업데이트
  ///
  /// 부분 환불이 처리될 때 환불 기록을 저장하고 잔액을 업데이트합니다.
  Future<void> addRefundRecord({
    required String orderId,
    required int refundAmount,
    required String refundReason,
    required Map<String, dynamic> refundResult,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 1️⃣ 주문 조회
        final orderDoc = await transaction.get(_ordersCollection.doc(orderId));
        if (!orderDoc.exists) {
          throw Exception('주문을 찾을 수 없습니다: $orderId');
        }

        final orderData = orderDoc.data() as Map<String, dynamic>;
        final currentOrder = OrderModel.fromMap(orderData);

        // 2️⃣ 현재 결제 정보 확인
        final currentPaymentInfo = currentOrder.paymentInfo;
        if (currentPaymentInfo == null) {
          throw Exception('결제 정보를 찾을 수 없습니다');
        }

        // 3️⃣ 잔액 업데이트
        final currentBalance = currentPaymentInfo.balanceAmount ?? 0;
        final newBalance = currentBalance - refundAmount;

        if (newBalance < 0) {
          throw Exception('환불 금액이 잔액을 초과합니다');
        }

        // 4️⃣ 환불 기록 저장 (서브컬렉션)
        final refundDoc =
            _ordersCollection.doc(orderId).collection('refunds').doc();

        final refundRecord = {
          'refundId': refundDoc.id,
          'refundAmount': refundAmount,
          'refundReason': refundReason,
          'refundResult': refundResult,
          'refundedAt': FieldValue.serverTimestamp(),
          'balanceBeforeRefund': currentBalance,
          'balanceAfterRefund': newBalance,
        };

        transaction.set(refundDoc, refundRecord);

        // 5️⃣ 주문의 결제 정보 업데이트
        final updatedPaymentInfo = currentPaymentInfo.toMap();
        updatedPaymentInfo['balanceAmount'] = newBalance;

        // 환불 내역 배열에 추가 (옵션)
        final refundHistory =
            orderData['refundHistory'] as List<dynamic>? ?? [];
        refundHistory.add({
          'refundId': refundDoc.id,
          'amount': refundAmount,
          'reason': refundReason,
          'refundedAt': DateTime.now().toIso8601String(),
          'status': refundResult['status'] ?? 'COMPLETED',
        });

        // 6️⃣ 주문 문서 업데이트
        transaction.update(_ordersCollection.doc(orderId), {
          'paymentInfo': updatedPaymentInfo,
          'refundHistory': refundHistory,
          'totalRefundedAmount': FieldValue.increment(refundAmount),
          'lastRefundedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint(
            '✅ 부분 환불 기록 완료: orderId=$orderId, refundAmount=$refundAmount, newBalance=$newBalance');
      });
    } catch (e) {
      debugPrint('❌ 부분 환불 기록 실패: $e');
      throw Exception('부분 환불 기록 실패: $e');
    }
  }

  /// 주문의 환불 기록 조회
  Future<List<Map<String, dynamic>>> getRefundHistory(String orderId) async {
    try {
      final snapshot = await _ordersCollection
          .doc(orderId)
          .collection('refunds')
          .orderBy('refundedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['refundId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('환불 기록 조회 실패: $e');
    }
  }

  /// 🆕 재고 복구 및 주문 삭제 (트랜잭션)
  ///
  /// pending 상태의 주문을 삭제하고 per-unit 재고를 복구합니다.
  Future<void> deleteOrderAndRestoreStock({
    required String orderId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 1. 주문 정보 조회
        final orderDoc = await transaction.get(_ordersCollection.doc(orderId));
        if (!orderDoc.exists) {
          throw Exception('주문을 찾을 수 없습니다: $orderId');
        }

        final orderData = orderDoc.data() as Map<String, dynamic>;
        final order = OrderModel.fromMap(orderData);

        // 2. pending 상태 확인
        if (order.status != OrderStatus.pending) {
          throw Exception('대기 중인 주문만 삭제할 수 있습니다.');
        }

        // 3. 결제 정보 확인 (결제 완료된 주문은 삭제 불가)
        if (order.paymentInfo != null && order.paymentInfo!.isSuccessful) {
          throw Exception('결제 완료된 주문은 삭제할 수 없습니다.');
        }

        // 4. 주문 상품 조회
        final orderedProductsSnapshot =
            await _getOrderedProductsCollection(orderId).get();
        final List<Map<String, dynamic>> stockUpdates = [];

        for (final doc in orderedProductsSnapshot.docs) {
          final productData = doc.data() as Map<String, dynamic>;
          final orderedUnit =
              productData['orderedUnit'] as Map<String, dynamic>;

          stockUpdates.add({
            'productId': productData['productId'],
            'unit': orderedUnit['unit'],
            'quantity': orderedUnit['quantity'],
          });
        }

        // 5. 각 상품의 재고 복구
        for (final update in stockUpdates) {
          final productId = update['productId'] as String;
          final unit = update['unit'] as String;
          final quantity = update['quantity'] as int;

          // 상품 문서 조회
          final productDoc =
              await transaction.get(_productsCollection.doc(productId));
          if (!productDoc.exists) {
            throw Exception('상품을 찾을 수 없습니다: $productId');
          }

          final productData = productDoc.data() as Map<String, dynamic>;
          final orderUnits =
              List<Map<String, dynamic>>.from(productData['orderUnits'] ?? []);

          // 해당 unit 찾아서 재고 복구
          bool unitFound = false;
          final updatedOrderUnits = orderUnits.map((unitData) {
            final unitMap = Map<String, dynamic>.from(unitData);
            if (unitMap['unit'] == unit) {
              unitFound = true;
              final currentStock = unitMap['stock'] as int? ?? 0;
              unitMap['stock'] = currentStock + quantity;
            }
            return unitMap;
          }).toList();

          if (!unitFound) {
            throw Exception('주문 단위를 찾을 수 없습니다: $productId - $unit');
          }

          // 상품 업데이트
          transaction.update(_productsCollection.doc(productId), {
            'orderUnits': updatedOrderUnits,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // 6. 주문 문서 삭제
        transaction.delete(_ordersCollection.doc(orderId));

        // 7. 주문 상품 서브컬렉션 삭제
        for (final doc in orderedProductsSnapshot.docs) {
          transaction.delete(doc.reference);
        }
      });
    } catch (e) {
      throw Exception('주문 삭제 및 재고 복구 실패: $e');
    }
  }
}
