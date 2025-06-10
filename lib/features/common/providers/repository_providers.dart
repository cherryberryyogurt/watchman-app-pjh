import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Repository imports
import '../../location/repositories/location_tag_repository.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../products/repositories/product_repository.dart';

part 'repository_providers.g.dart';

// 🏷️ LocationTagRepository Provider
@riverpod
LocationTagRepository locationTagRepository(LocationTagRepositoryRef ref) {
  return LocationTagRepository(
    firestore: FirebaseFirestore.instance,
  );
}

// 🔐 AuthRepository Provider (LocationTagRepository 의존성 포함)
@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  final locationTagRepository = ref.watch(locationTagRepositoryProvider);

  return AuthRepository(
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    locationTagRepository: locationTagRepository,
  );
}

// 🛍️ ProductRepository Provider (LocationTagRepository 의존성 포함)
@riverpod
ProductRepository productRepository(ProductRepositoryRef ref) {
  final locationTagRepository = ref.watch(locationTagRepositoryProvider);

  return ProductRepository(
    firestore: FirebaseFirestore.instance,
    locationTagRepository: locationTagRepository,
  );
}

// 🔥 Firebase 인스턴스 Provider들 (필요시 사용)
@riverpod
FirebaseFirestore firebaseFirestore(FirebaseFirestoreRef ref) {
  return FirebaseFirestore.instance;
}

@riverpod
FirebaseAuth firebaseAuth(FirebaseAuthRef ref) {
  return FirebaseAuth.instance;
}
