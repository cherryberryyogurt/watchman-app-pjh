import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // Import for Completer and TimeoutException
import '../models/cart_model.dart';
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
FirebaseFirestore firebaseFirestore(FirebaseFirestoreRef ref) {
  return FirebaseFirestore.instance;
}

/// CartRepository 인스턴스를 제공하는 Provider입니다.
@riverpod
CartRepository cartRepository(CartRepositoryRef ref) {
  return CartRepository(ref.watch(firebaseFirestoreProvider), ref);
}

class CartRepository {
  final FirebaseFirestore _firestore;
  final Ref _ref; // 다른 Provider를 읽기 위해 Ref 사용

  CartRepository(this._firestore, this._ref);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Get collection reference
  CollectionReference get _cartsCollection => _firestore.collection('carts');
  
  // Get current user ID with retry mechanism
  Future<String?> _getCurrentUserId({Duration timeoutDuration = const Duration(seconds: 5)}) async {
    // Try to get the current user directly
    String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      print("CartRepository: User ID available immediately: $userId");
      return userId;
    }

    print("CartRepository: User ID not immediately available. Listening to authStateChanges...");
    
    // If not available, listen to authStateChanges for a non-null user
    // with a timeout.
    try {
      final firebaseUser = await _auth
          .authStateChanges()
          .firstWhere((user) => user != null)
          .timeout(timeoutDuration, onTimeout: () {
            print("CartRepository: Timeout waiting for auth state change.");
            throw TimeoutException(
                'Timeout waiting for user to be authenticated.');
          });
      
      userId = firebaseUser?.uid;
      if (userId != null) {
        print("CartRepository: User ID obtained from authStateChanges: $userId");
      } else {
        print("CartRepository: authStateChanges emitted null user after timeout or completion.");
      }
      return userId;
    } catch (e) {
      print("CartRepository: Error or timeout waiting for auth state: $e");
      // If timeout or any other error, currentUser might still be null or updated by now.
      // Fallback to checking currentUser directly one last time.
      userId = _auth.currentUser?.uid;
      if (userId != null) {
        print("CartRepository: User ID obtained on final fallback check: $userId");
      } else {
        print("CartRepository: User ID still null on final fallback check.");
      }
      return userId;
    }
  }
  
  /// 현재 로그인된 사용자의 장바구니 컬렉션 참조를 반환합니다.
  /// 사용자가 로그인하지 않은 경우 null을 반환합니다.
  /// 
  /// race condition 처리를 위해 safeCurrentUserUidProvider를 사용합니다.
  Future<CollectionReference<CartItemModel>?> _userCartCollectionRef() async {
    // 향상된 안전한 UID 프로바이더 사용
    final uid = await _ref.read(safeCurrentUserUidProvider.future);
    if (uid == null) {
      return null;
    }
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('cart')
        .withConverter<CartItemModel>(
          fromFirestore: (snapshot, _) => CartItemModel.fromFirestore(snapshot.data()!, snapshot.id),
          toFirestore: (cartItem, _) => cartItem.toFirestore(),
        );
  }
  
  /// 사용자의 장바구니 아이템 목록을 가져옵니다.
  /// 로그인하지 않은 경우 빈 리스트를 반환합니다.
  Future<List<CartItemModel>> getCartItems() async {
    final cartColRef = await _userCartCollectionRef();
    if (cartColRef == null) {
      // 로그인하지 않은 경우, 빈 리스트 반환 (UI에서 오류 대신 빈 화면 표시 용이)
      return [];
    }
    try {
      final snapshot = await cartColRef.orderBy('addedAt', descending: true).get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      // Firestore 작업 오류 로깅 및 재throw
      print('Error fetching cart items: $e');
      throw FirestoreOperationException('장바구니 아이템을 불러오는데 실패했습니다.', e);
    }
  }
  
  /// 장바구니에 아이템을 추가합니다.
  /// 로그인이 되어 있지 않거나 이메일 인증이 완료되지 않은 경우 예외를 발생시킵니다.
  Future<void> addItemToCart(CartItemModel item) async {
    final cartColRef = await _userCartCollectionRef();
    if (cartColRef == null) {
      throw UserNotLoggedInException();
    }
    // 이메일 인증 여부 확인
    final isEmailVerified = _ref.read(isCurrentUserEmailVerifiedProvider);
    if (!isEmailVerified) {
      throw EmailNotVerifiedException();
    }

    try {
      // Firestore에 아이템 추가 (add는 자동 생성 ID 사용)
      await cartColRef.doc(item.id).set(item); // 상품 ID를 문서 ID로 사용하려면 doc(item.productId) 또는 item.id 사용
                                           // CartItemModel의 id가 Firestore 문서 ID를 의미한다면 doc(item.id).set(item)
    } catch (e) {
      print('Error adding item to cart: $e');
      throw FirestoreOperationException('장바구니에 아이템을 추가하는데 실패했습니다.', e);
    }
  }
  
  /// 장바구니 아이템의 수량을 업데이트합니다.
  Future<void> updateCartItemQuantity(String cartItemId, int newQuantity) async {
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
      await cartColRef.doc(cartItemId).delete();
    } catch (e) {
      print('Error removing cart item: $e');
      throw FirestoreOperationException('장바구니에서 아이템을 삭제하는데 실패했습니다.', e);
    }
  }
  
  /// 상품 모델과 수량을 받아 장바구니에 추가합니다.
  Future<void> addToCart(ProductModel product, int quantity) async {
    // 안전한 UID 프로바이더 사용
    final uid = await _ref.read(safeCurrentUserUidProvider.future);
    if (uid == null) {
      throw UserNotLoggedInException();
    }
    
    // 현재 시간을 Timestamp로 생성
    final now = Timestamp.now();
    
    // CartItemModel 생성
    final cartItem = CartItemModel(
      id: product.id,  // 상품 ID를 카트 아이템 ID로 사용
      productId: product.id,
      productName: product.name,
      quantity: quantity,
      productPrice: product.price,
      thumbnailUrl: product.thumbnailUrl,
      productOrderUnit: product.orderUnit,
      addedAt: now,
      productDeliveryType: product.deliveryType,
      productPickupInfo: product.pickupInfo,
      productStartDate: product.startDate,
      productEndDate: product.endDate,
      isSelected: false,  // 기본적으로 선택되지 않음
    );
    
    // 기존 addItemToCart 메서드 호출
    await addItemToCart(cartItem);
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
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error clearing cart: $e');
      throw FirestoreOperationException('장바구니를 비우는데 실패했습니다.', e);
    }
  }
} 