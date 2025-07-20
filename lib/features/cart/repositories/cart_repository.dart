import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // Import for Completer and TimeoutException
import '../models/cart_item_model.dart';
import '../../products/models/product_model.dart';
import '../../order/models/order_unit_model.dart'; // 🆕 OrderUnitModel import
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Ref 사용을 위해 추가
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:gonggoo_app/features/auth/providers/auth_providers.dart';
import '../exceptions/cart_exceptions.dart';
import '../../../core/providers/firebase_providers.dart';

part 'cart_repository.g.dart';

/// CartRepository 인스턴스를 제공하는 Provider입니다.
@riverpod
CartRepository cartRepository(Ref ref) {
  return CartRepository(
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
    ref: ref,
  );
}

class CartRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Ref _ref; // 다른 Provider를 읽기 위해 Ref 사용

  /// 의존성 주입을 지원하는 생성자
  CartRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required Ref ref,
  })  : _firestore = firestore,
        _auth = auth,
        _ref = ref;

  // Get collection reference
  CollectionReference get _cartsCollection => _firestore.collection('carts');

  Future<CollectionReference<CartItemModel>?> _userCartCollectionRef() async {
    final uid = await _ref.read(safeCurrentUserUidProvider.future);
    if (uid == null) {
      return null;
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .withConverter<CartItemModel>(
          fromFirestore: (snapshot, _) =>
              CartItemModel.fromFirestore(snapshot.data()!, snapshot.id),
          toFirestore: (cartItem, _) => cartItem.toFirestore(),
        );
  }

  Future<List<CartItemModel>> getCartItems() async {
    final cartColRef = await _userCartCollectionRef();
    if (cartColRef == null) {
      // 로그인하지 않은 경우, 빈 리스트 반환 (UI에서 오류 대신 빈 화면 표시 용이)
      return [];
    }
    try {
      final snapshot = await cartColRef
          .where('isDeleted', isEqualTo: false)
          .orderBy('addedAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      // Firestore 작업 오류 로깅 및 재throw
      throw FirestoreOperationException('장바구니 아이템을 불러오는데 실패했습니다.', e);
    }
  }

  Future<void> addItemToCart(CartItemModel item) async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final cartColRef = await _userCartCollectionRef();
        if (cartColRef == null) {
          throw UserNotLoggedInException();
        }

        // 이메일 인증 여부 확인 (안전한 provider 사용)
        // TODO: 이메일 인증 확인 로직 추가
        // if (!emailVerified) {
        //   throw EmailNotVerifiedException();
        // }

        // TODO: 실제 장바구니 추가 로직 구현
        await cartColRef.add(item);

        // 성공 시 로그 출력 및 반환
        return;
      } catch (e) {
        if (attempt == maxRetries) {
          throw FirestoreOperationException('장바구니에 아이템을 추가하는데 실패했습니다.', e);
        }

        // 다음 시도 전 잠시 대기
        await Future.delayed(retryDelay);
      }
    }

    // 모든 재시도가 실패한 경우
    throw FirestoreOperationException('장바구니에 아이템을 추가하는데 실패했습니다.');
  }

  /// 장바구니 아이템의 수량을 업데이트합니다.
  Future<void> updateCartItemQuantity(
      String cartItemId, int newQuantity) async {
    final cartColRef = await _userCartCollectionRef();
    if (cartColRef == null) {
      throw UserNotLoggedInException();
    }
    // 이메일 인증 여부 확인 (선택적: 업데이트 시에도 필요하다면 추가)
    // if (!_ref.read(isCurrentUserEmailVerifiedProvider)) {
    //   throw EmailNotVerifiedException();
    // }

    if (newQuantity <= 0) {
      // 수량이 0 이하이면 아이템 삭제 로직 호출 또는 예외 발생
      await removeCartItem(cartItemId);
      return;
      // throw ArgumentError('수량은 1 이상이어야 합니다.');
    }
    try {
      await cartColRef.doc(cartItemId).update({'quantity': newQuantity});
    } catch (e) {
      throw FirestoreOperationException('장바구니 아이템 수량 업데이트에 실패했습니다.', e);
    }
  }

  /// 장바구니에서 특정 아이템을 삭제합니다.
  Future<void> removeCartItem(String cartItemId) async {
    final cartColRef = await _userCartCollectionRef();
    if (cartColRef == null) {
      throw UserNotLoggedInException();
    }
    try {
      await cartColRef.doc(cartItemId).update({'isDeleted': true});
    } catch (e) {
      throw FirestoreOperationException('장바구니 아이템 삭제에 실패했습니다.', e);
    }
  }

  /// 상품 모델과 수량을 받아 장바구니에 추가합니다.
  /// 이미 해당 상품이 장바구니에 있으면 수량을 증가시키고, 없으면 새로 추가합니다.
  Future<void> addToCart(ProductModel product, int quantity) async {
    // 안전한 UID 프로바이더 사용
    final uid = await _ref.read(safeCurrentUserUidProvider.future);

    // TODO: 이메일 인증 여부 확인 (안전한 provider 사용)
    // if (!emailVerified) {
    //   throw EmailNotVerifiedException();
    // }

    try {
      // 먼저 기존 장바구니 아이템들을 확인
      final existingItems = await getCartItems();
      final existingItem = existingItems
          .where((item) => item.productId == product.id && !item.isDeleted)
          .firstOrNull;

      if (existingItem != null) {
        // 기존 아이템이 있으면 수량 증가
        await updateCartItemQuantity(
            existingItem.id, existingItem.quantity + quantity);
      } else {
        // 현재 시간을 Timestamp로 생성
        final now = Timestamp.now();

        // CartItemModel 생성
        final cartItem = CartItemModel(
          id: '', // 빈 ID로 시작 (Firestore에서 자동 생성)
          productId: product.id,
          productName: product.name,
          quantity: quantity,
          productPrice: product.defaultOrderUnit.price,
          thumbnailUrl: product.mainImageUrl, // 🆕 helper 메서드 사용
          productOrderUnit: product.defaultOrderUnit.unit,
          addedAt: now,
          productDeliveryType: product.deliveryType,
          // locationTagId: product.defaultLocationTagName, // 🔄 픽업 지역 태그 ID
          // pickupInfoId: product.isPickupDelivery && product.hasPickupPoints
          //     ? product.availablePickupPointIds.first
          //     : null, // 🆕 픽업 배송인 경우 첫 번째 픽업 포인트 사용
          productStartDate: product.startDate,
          productEndDate: product.endDate,
          isSelected: false, // 기본적으로 선택되지 않음
          isDeleted: false, // 기본적으로 삭제되지 않음
          isTaxFree: product.isTaxFree, // 🔧 상품의 면세 여부 전달
        );

        // 기존 addItemToCart 메서드 호출
        await addItemToCart(cartItem);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 🆕 선택된 OrderUnit으로 장바구니에 추가합니다.
  Future<void> addToCartWithOrderUnit(ProductModel product,
      OrderUnitModel selectedOrderUnit, int quantity) async {
    try {
      // 재고 확인 - 새로운 per-unit 재고 시스템 사용
      if (selectedOrderUnit.stock < quantity) {
        throw Exception(
            '선택한 단위의 재고가 부족합니다. (현재: ${selectedOrderUnit.stock}개, 요청: ${quantity}개)');
      }

      // 먼저 기존 장바구니 아이템들을 확인 (같은 OrderUnit의 아이템 찾기)
      final existingItems = await getCartItems();
      final existingItem = existingItems
          .where((item) =>
              item.productId == product.id &&
              !item.isDeleted &&
              item.productPrice == selectedOrderUnit.price &&
              item.productOrderUnit == selectedOrderUnit.unit)
          .firstOrNull;

      if (existingItem != null) {
        // 기존 아이템이 있으면 재고 확인 후 수량 증가
        final newQuantity = existingItem.quantity + quantity;
        if (selectedOrderUnit.stock < newQuantity) {
          throw Exception(
              '선택한 단위의 재고가 부족합니다. (현재: ${selectedOrderUnit.stock}개, 요청: ${newQuantity}개)');
        }
        await updateCartItemQuantity(existingItem.id, newQuantity);
      } else {
        // 현재 시간을 Timestamp로 생성
        final now = Timestamp.now();

        // CartItemModel 생성 (선택된 OrderUnit 사용)
        final cartItem = CartItemModel(
          id: '', // 빈 ID로 시작 (Firestore에서 자동 생성)
          productId: product.id,
          productName: product.name,
          quantity: quantity,
          productPrice: selectedOrderUnit.price, // 🆕 선택된 OrderUnit의 가격
          thumbnailUrl: product.mainImageUrl,
          productOrderUnit: selectedOrderUnit.unit, // 🆕 선택된 OrderUnit의 단위
          addedAt: now,
          productDeliveryType: product.deliveryType,
          productStartDate: product.startDate,
          productEndDate: product.endDate,
          isSelected: false,
          isDeleted: false,
          isTaxFree: product.isTaxFree, // 🔧 상품의 면세 여부 전달
        );

        // 기존 addItemToCart 메서드 호출
        await addItemToCart(cartItem);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 사용자의 장바구니 전체를 비웁니다.
  Future<void> clearCart() async {
    final cartColRef = await _userCartCollectionRef();
    if (cartColRef == null) {
      throw UserNotLoggedInException();
    }
    try {
      final snapshot = await cartColRef.get();
      // WriteBatch를 사용하여 여러 문서를 한 번의 작업으로 삭제 (원자적 작업)
      WriteBatch batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isDeleted': true});
      }
      await batch.commit();
    } catch (e) {
      throw FirestoreOperationException('장바구니 전체 비우기에 실패했습니다.', e);
    }
  }

  /// 선택된 장바구니 항목들을 삭제합니다.
  Future<void> removeSelectedItems(List<String> cartItemIds) async {
    final cartColRef = await _userCartCollectionRef();
    if (cartColRef == null) {
      throw UserNotLoggedInException();
    }

    if (cartItemIds.isEmpty) {
      return; // 삭제할 항목이 없으면 아무것도 하지 않음
    }

    try {
      // WriteBatch를 사용하여 여러 항목을 원자적으로 삭제
      WriteBatch batch = _firestore.batch();

      for (String cartItemId in cartItemIds) {
        final docRef = cartColRef.doc(cartItemId);
        batch.update(docRef, {'isDeleted': true});
      }

      await batch.commit();
    } catch (e) {
      throw FirestoreOperationException('선택된 장바구니 아이템 삭제에 실패했습니다.', e);
    }
  }

  /// 주문한 상품들을 장바구니에서 삭제합니다.
  /// 🆕 orderedUnit 정보를 기반으로 정확한 아이템을 삭제합니다.
  Future<void> removeOrderedItems(
      List<Map<String, dynamic>> orderedItems) async {
    final cartColRef = await _userCartCollectionRef();
    if (cartColRef == null) {
      throw UserNotLoggedInException();
    }

    if (orderedItems.isEmpty) {
      return; // 삭제할 항목이 없으면 아무것도 하지 않음
    }

    try {
      // 모든 장바구니 아이템 조회
      final snapshot =
          await cartColRef.where('isDeleted', isEqualTo: false).get();

      if (snapshot.docs.isEmpty) {
        return; // 삭제할 항목이 없으면 종료
      }

      // WriteBatch를 사용하여 여러 항목을 원자적으로 삭제
      WriteBatch batch = _firestore.batch();

      for (final orderedItem in orderedItems) {
        final productId = orderedItem['productId'] as String;
        final orderedUnit = orderedItem['orderedUnit'] as Map<String, dynamic>;
        final unit = orderedUnit['unit'] as String;
        final price = orderedUnit['price'] as int;
        final quantity = orderedUnit['quantity'] as int;

        // 해당 상품의 동일한 OrderUnit을 가진 장바구니 아이템 찾기
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['productId'] == productId &&
              data['productOrderUnit'] == unit &&
              data['productPrice'] == price) {
            final cartQuantity = data['quantity'] as int;
            if (cartQuantity <= quantity) {
              // 장바구니 수량이 주문 수량보다 적거나 같으면 완전 삭제
              batch.update(doc.reference, {'isDeleted': true});
            } else {
              // 장바구니 수량이 더 많으면 수량만 감소
              batch
                  .update(doc.reference, {'quantity': cartQuantity - quantity});
            }
            break; // 해당 아이템을 찾았으므로 다음 주문 아이템으로
          }
        }
      }

      await batch.commit();
    } catch (e) {
      throw FirestoreOperationException('주문된 아이템 삭제에 실패했습니다.', e);
    }
  }
}
