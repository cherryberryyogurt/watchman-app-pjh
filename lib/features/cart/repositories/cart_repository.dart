import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // Import for Completer and TimeoutException
import '../models/cart_item_model.dart';
import '../../products/models/product_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Ref 사용을 위해 추가
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:gonggoo_app/features/auth/providers/auth_providers.dart';
import '../exceptions/cart_exceptions.dart';

part 'cart_repository.g.dart';

/// FirebaseFirestore 인스턴스를 제공하는 Provider입니다.
/// 테스트 시 Mock 객체로 대체하기 용이하도록 별도 Provider로 분리합니다.
@riverpod
FirebaseFirestore firebaseFirestore(Ref ref) {
  return FirebaseFirestore.instance;
}

/// CartRepository 인스턴스를 제공하는 Provider입니다.
@riverpod
CartRepository cartRepository(Ref ref) {
  return CartRepository(ref.watch(firebaseFirestoreProvider), ref);
}

class CartRepository {
  final FirebaseFirestore _firestore;
  final Ref _ref; // 다른 Provider를 읽기 위해 Ref 사용

  CartRepository(this._firestore, this._ref);

  final FirebaseAuth _auth = FirebaseAuth.instance;

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
      print('Error fetching cart items: $e');
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
        print('🛒 CartRepository: Checking email verification...');
        final isEmailVerified =
            await _ref.read(safeIsCurrentUserEmailVerifiedProvider.future);
        print('🛒 CartRepository: Email verification result: $isEmailVerified');

        // 개발 환경에서는 이메일 인증 우회 옵션 (필요시 주석 해제)
        const bool isDebugMode = true; // 개발 시에만 true로 설정
        if (!isEmailVerified && !isDebugMode) {
          // if (!isEmailVerified) {
          print('🛒 CartRepository: Email not verified, throwing exception');
          throw EmailNotVerifiedException();
        }

        print('🛒 CartRepository: Adding item to cart: ${item.productName}');
        // Firestore에 아이템 추가
        await cartColRef.doc(item.id).set(item);

        // 성공 시 로그 출력 및 반환
        print(
            '🛒 CartRepository: Successfully added item to cart on attempt $attempt');
        return;
      } catch (e) {
        print('🛒 CartRepository: Attempt $attempt failed with error: $e');

        // EmailNotVerifiedException과 UserNotLoggedInException은 retry하지 않음
        if (e is EmailNotVerifiedException || e is UserNotLoggedInException) {
          rethrow;
        }

        // 마지막 시도인 경우 오류 throw
        if (attempt == maxRetries) {
          print('🛒 CartRepository: All $maxRetries attempts failed');
          throw FirestoreOperationException('장바구니에 아이템을 추가하는데 실패했습니다.', e);
        }

        // 다음 시도 전 잠시 대기
        await Future.delayed(retryDelay);
      }
    }
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
      print('Error updating cart item quantity: $e');
      throw FirestoreOperationException('장바구니 아이템 수량을 업데이트하는데 실패했습니다.', e);
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
      print('Error removing cart item: $e');
      throw FirestoreOperationException('장바구니에서 아이템을 삭제하는데 실패했습니다.', e);
    }
  }

  /// 상품 모델과 수량을 받아 장바구니에 추가합니다.
  /// 이미 해당 상품이 장바구니에 있으면 수량을 증가시키고, 없으면 새로 추가합니다.
  Future<void> addToCart(ProductModel product, int quantity) async {
    // 안전한 UID 프로바이더 사용
    final uid = await _ref.read(safeCurrentUserUidProvider.future);
    print('🛒 CartRepository: Current UID: $uid');

    // Firebase Auth에서 직접 확인
    final authUser = FirebaseAuth.instance.currentUser;
    print('🛒 CartRepository: Firebase Auth UID: ${authUser?.uid}');
    print('🛒 CartRepository: Firebase Auth Email: ${authUser?.email}');
    print(
        '🛒 CartRepository: Firebase Auth EmailVerified: ${authUser?.emailVerified}');

    // 이메일 인증 여부 확인 (안전한 provider 사용)
    print('🛒 CartRepository: Checking email verification...');
    final isEmailVerified =
        await _ref.read(safeIsCurrentUserEmailVerifiedProvider.future);
    print('🛒 CartRepository: Email verification result: $isEmailVerified');

    if (uid == null) {
      throw UserNotLoggedInException();
    }

    try {
      // 먼저 기존 장바구니 아이템들을 확인
      final existingItems = await getCartItems();
      final existingItem = existingItems
          .where((item) => item.productId == product.id && !item.isDeleted)
          .firstOrNull;

      if (existingItem != null) {
        // 기존 아이템이 있으면 수량 증가
        print(
            '🛒 CartRepository: Found existing item, updating quantity from ${existingItem.quantity} to ${existingItem.quantity + quantity}');
        await updateCartItemQuantity(
            existingItem.id, existingItem.quantity + quantity);
        print('🛒 CartRepository: Successfully updated existing item quantity');
      } else {
        // 기존 아이템이 없으면 새로 추가
        print('🛒 CartRepository: No existing item found, adding new item');

        // 현재 시간을 Timestamp로 생성
        final now = Timestamp.now();

        // CartItemModel 생성
        final cartItem = CartItemModel(
          id: product.id, // 상품 ID를 카트 아이템 ID로 사용
          productId: product.id,
          productName: product.name,
          quantity: quantity,
          productPrice: product.price,
          thumbnailUrl: product.thumbnailUrl,
          productOrderUnit: product.orderUnit,
          addedAt: now,
          productDeliveryType: product.deliveryType,
          locationTagId: product.locationTagId, // 🔄 픽업 지역 태그 ID
          pickupInfoId: null, // TODO: 픽업 정보 ID 구현 필요
          productStartDate: product.startDate,
          productEndDate: product.endDate,
          isSelected: false, // 기본적으로 선택되지 않음
          isDeleted: false, // 기본적으로 삭제되지 않음
        );

        // 기존 addItemToCart 메서드 호출
        await addItemToCart(cartItem);
        print('🛒 CartRepository: Successfully added new item to cart');
      }
    } catch (e) {
      print('🛒 CartRepository: Error in addToCart: $e');
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
      print('Error clearing cart: $e');
      throw FirestoreOperationException('장바구니를 비우는데 실패했습니다.', e);
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

      print(
          '🛒 CartRepository: Successfully removed ${cartItemIds.length} selected items');
    } catch (e) {
      print('🛒 CartRepository: Error removing selected items: $e');
      throw FirestoreOperationException('선택된 상품들을 삭제하는데 실패했습니다.', e);
    }
  }
}
