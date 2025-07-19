import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Repository imports
import '../../features/location/repositories/location_tag_repository.dart';
import '../../features/auth/repositories/auth_repository.dart';
import '../../features/products/repositories/product_repository.dart';
import '../../features/order/repositories/refund_repository.dart';

// Firebase Provider imports
import 'firebase_providers.dart';

part 'repository_providers.g.dart';

// 🏷️ LocationTagRepository Provider
@riverpod
LocationTagRepository locationTagRepository(Ref ref) {
  final firestore = ref.watch(firestoreProvider);

  return LocationTagRepository(
    firestore: firestore,
  );
}

// 🔐 AuthRepository Provider (LocationTagRepository 의존성 포함)
@riverpod
AuthRepository authRepository(Ref ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);

  return AuthRepository(
    firebaseAuth: firebaseAuth,
    firestore: firestore,
  );
}

// 🛍️ ProductRepository Provider (LocationTagRepository 의존성 포함)
@riverpod
ProductRepository productRepository(Ref ref) {
  final firestore = ref.watch(firestoreProvider);

  return ProductRepository(
    firestore: firestore,
  );
}

// 🔄 RefundRepository Provider
@riverpod
RefundRepository refundRepository(Ref ref) {
  final firestore = ref.watch(firestoreProvider);

  return RefundRepository(
    firestore,
  );
}

// 🔥 Firebase 인스턴스 Provider들은 이제 core/providers/firebase_providers.dart에서 관리됩니다.
//
// 기존 Provider들과의 호환성을 위해 유지하지만,
// 새로운 코드에서는 firebase_providers.dart의 Provider들을 사용하세요.
@riverpod
FirebaseFirestore firebaseFirestore(Ref ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore;
}

@riverpod
FirebaseAuth firebaseAuth(Ref ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return firebaseAuth;
}
