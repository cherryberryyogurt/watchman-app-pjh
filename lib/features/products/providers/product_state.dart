import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../auth/providers/auth_state.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';
import '../../../core/providers/repository_providers.dart' as common_providers;

part 'product_state.g.dart';

enum ProductLoadStatus {
  initial,
  loading,
  loaded,
  error,
}

enum ProductActionType {
  none,
  loadByLocationTag,
  loadDetails,
}

class ProductState {
  final ProductLoadStatus status;
  final List<ProductModel> products;
  final ProductModel? selectedProduct;
  final String? errorMessage;
  final bool hasMore;
  final bool isLoadingMore;
  final DocumentSnapshot? lastDocument;
  final String currentLocation;
  final GeoPoint? currentCoordinates;
  final String currentLocationTag;
  final String currentCategory;
  final ProductActionType currentAction;
  final bool isDetailLoading;

  bool get isLoading =>
      status == ProductLoadStatus.loading || isLoadingMore || isDetailLoading;

  const ProductState({
    required this.status,
    required this.products,
    this.selectedProduct,
    this.errorMessage,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.lastDocument,
    this.currentLocation = '전체',
    this.currentCoordinates,
    this.currentLocationTag = '전체',
    this.currentCategory = '전체',
    this.currentAction = ProductActionType.none,
    this.isDetailLoading = false,
  });

  ProductState copyWith({
    ProductLoadStatus? status,
    List<ProductModel>? products,
    ProductModel? selectedProduct,
    String? errorMessage,
    bool? hasMore,
    bool? isLoadingMore,
    DocumentSnapshot? lastDocument,
    String? currentLocation,
    GeoPoint? currentCoordinates,
    String? currentLocationTag,
    String? currentCategory,
    ProductActionType? currentAction,
    bool? isDetailLoading,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastDocument: lastDocument ?? this.lastDocument,
      currentLocation: currentLocation ?? this.currentLocation,
      currentCoordinates: currentCoordinates ?? this.currentCoordinates,
      currentLocationTag: currentLocationTag ?? this.currentLocationTag,
      currentCategory: currentCategory ?? this.currentCategory,
      currentAction: currentAction ?? this.currentAction,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
    );
  }
}

// ProductRepository 프로바이더 -> core/providers/repository_providers.dart 에서 관리
// @riverpod
// ProductRepository productRepository(Ref ref) {
//   return ProductRepository();
// }

// 상품 상태 노티파이어
@riverpod
class Product extends _$Product {
  ProductRepository get _productRepository =>
      ref.read(common_providers.productRepositoryProvider);

  @override
  ProductState build() {
    return const ProductState(
      status: ProductLoadStatus.initial,
      products: [],
    );
  }

  // 모든 상품 로드
  Future<void> loadProducts() async {
    final authState = ref.watch(authProvider);
    final user = authState.value?.user;

    // 🚫 사용자 위치 상태별 처리
    if (user == null) {
      state = state.copyWith(
        status: ProductLoadStatus.error,
        errorMessage: '로그인이 필요합니다.',
      );
      return;
    }

    if (user.locationStatus == 'pending') {
      final regionName = (user.pendingLocationName?.isNotEmpty == true)
          ? user.pendingLocationName
          : "현재 지역"; // TODO: 가입되지 않은 유저는 어떻게 처리할지 고민해보기
      state = state.copyWith(
        status: ProductLoadStatus.loaded,
        products: [], // 빈 리스트
        errorMessage: '$regionName은 서비스 준비 중입니다.',
      );
      return;
    }

    // @Deprecated('unavailable 상태 사용하지 않음')
    if (user.locationStatus == 'unavailable') {
      final regionName = (user.pendingLocationName?.isNotEmpty == true)
          ? user.pendingLocationName
          : "현재 지역";
      state = state.copyWith(
        status: ProductLoadStatus.loaded,
        products: [], // 빈 리스트
        errorMessage: '$regionName은 서비스 지원 지역이 아닙니다.',
      );
      return;
    }

    // @Deprecated('none 상태 사용하지 않음')
    if (user.locationStatus == 'none' || user.locationTagName == null) {
      state = state.copyWith(
        status: ProductLoadStatus.loaded,
        products: [], // 빈 리스트
        errorMessage: '위치 설정을 먼저 완료해주세요.',
      );
      return;
    }

    // active 상태인 경우만 상품 로드
    await loadProductsByLocationTagAndCategory(
        user.locationTagName!, state.currentCategory);
  }

  // LocationTag + 카테고리 기반 상품 더 로드 (페이지네이션) - 수정
  Future<void> loadMoreProductsByLocationTag() async {
    if (state.isLoadingMore || !state.hasMore) return;

    try {
      state = state.copyWith(isLoadingMore: true);

      final result = await _productRepository
          .getProductsByLocationTagAndCategoryWithPagination(
        state.currentLocationTag,
        state.currentCategory == '전체' ? null : state.currentCategory,
        state.lastDocument,
        20,
      );

      state = state.copyWith(
        status: ProductLoadStatus.loaded,
        products: [...state.products, ...result.products],
        lastDocument: result.lastDocument,
        hasMore: result.products.length == 20,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isLoadingMore: false,
      );
    }
  }

  // 상품 상세 정보 가져오기
  Future<void> getProductDetails(String productId) async {
    try {
      state = state.copyWith(
        isDetailLoading: true,
        errorMessage: null,
        currentAction: ProductActionType.loadDetails,
      );

      final product = await _productRepository.getProductById(productId);

      state = state.copyWith(
        status: ProductLoadStatus.loaded,
        selectedProduct: product,
        isDetailLoading: false,
        currentAction: ProductActionType.none,
      );
    } catch (e) {
      state = state.copyWith(
        status: ProductLoadStatus.error,
        errorMessage: e.toString(),
        isDetailLoading: false,
        currentAction: ProductActionType.none,
      );
    }
  }

  // 선택된 상품 초기화
  void clearSelectedProduct() {
    state = state.copyWith(selectedProduct: null);
  }

  // 오류 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 카테고리 설정
  void setCategory(String category) {
    state = state.copyWith(currentCategory: category);
  }

  /// 현재 사용자 위치 + 카테고리별 상품 로드
  Future<void> loadProductsByCategory(String category) async {
    final authState = ref.watch(authProvider);
    final user = authState.value?.user;

    // 🚫 사용자 위치 상태별 처리
    if (user == null) {
      state = state.copyWith(
        status: ProductLoadStatus.error,
        errorMessage: '로그인이 필요합니다.',
      );
      return;
    }

    if (user.locationStatus == 'pending') {
      final regionName = (user.pendingLocationName?.isNotEmpty == true)
          ? user.pendingLocationName
          : "현재 지역";
      state = state.copyWith(
        status: ProductLoadStatus.loaded,
        products: [], // 빈 리스트
        errorMessage: '$regionName은 서비스 준비 중입니다.',
      );
      return;
    }

    if (user.locationStatus == 'unavailable') {
      final regionName = (user.pendingLocationName?.isNotEmpty == true)
          ? user.pendingLocationName
          : "현재 지역";
      state = state.copyWith(
        status: ProductLoadStatus.loaded,
        products: [], // 빈 리스트
        errorMessage: '$regionName은 서비스 지원 지역이 아닙니다.',
      );
      return;
    }

    if (user.locationStatus == 'none' || user.locationTagName == null) {
      state = state.copyWith(
        status: ProductLoadStatus.loaded,
        products: [], // 빈 리스트
        errorMessage: '위치 설정을 먼저 완료해주세요.',
      );
      return;
    }

    // active 상태인 경우만 상품 로드
    await loadProductsByLocationTagAndCategory(user.locationTagName!, category);
  }

  /// LocationTag + 카테고리별 상품 로드 (핵심 메소드)
  Future<void> loadProductsByLocationTagAndCategory(
    String locationTagName,
    String category,
  ) async {
    try {
      state = state.copyWith(
        status: ProductLoadStatus.loading,
        products: [],
        lastDocument: null,
        hasMore: true,
        currentLocationTag: locationTagName,
        currentCategory: category,
        errorMessage: null,
        currentAction: ProductActionType.loadByLocationTag,
      );

      final result = await _productRepository
          .getProductsByLocationTagAndCategoryWithPagination(
        locationTagName,
        category == '전체' ? null : category,
        null,
        20,
      );

      state = state.copyWith(
        status: ProductLoadStatus.loaded,
        products: result.products,
        lastDocument: result.lastDocument,
        hasMore: result.products.length == 20,
        currentAction: ProductActionType.none,
      );
    } catch (e) {
      state = state.copyWith(
        status: ProductLoadStatus.error,
        errorMessage: e.toString(),
        currentAction: ProductActionType.none,
      );
    }
  }
}
