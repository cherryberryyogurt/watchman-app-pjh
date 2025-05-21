import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:math' show sqrt, cos;
import '../models/product_model.dart';
import '../repositories/product_repository.dart';

part 'product_state.g.dart';

enum ProductLoadStatus {
  initial,
  loading,
  loaded,
  error,
}

enum ProductActionType {
  none,
  loadAll,
  loadByLocation,
  loadByLocationTag,
  loadDetails,
  addDummy,
  addToCart,
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
  final ProductActionType currentAction;
  final bool isDetailLoading;
  final bool isDummyAddLoading;
  
  bool get isLoading => status == ProductLoadStatus.loading || isLoadingMore || isDetailLoading || isDummyAddLoading;

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
    this.currentAction = ProductActionType.none,
    this.isDetailLoading = false,
    this.isDummyAddLoading = false,
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
    ProductActionType? currentAction,
    bool? isDetailLoading,
    bool? isDummyAddLoading,
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
      currentAction: currentAction ?? this.currentAction,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isDummyAddLoading: isDummyAddLoading ?? this.isDummyAddLoading,
    );
  }
}

// ProductRepository 프로바이더
@riverpod
ProductRepository productRepository(ProductRepositoryRef ref) {
  return ProductRepository();
}

// 상품 상태 노티파이어
@riverpod
class Product extends _$Product {
  late final ProductRepository _productRepository;

  @override
  ProductState build() {
    _productRepository = ref.watch(productRepositoryProvider);
    return const ProductState(
          status: ProductLoadStatus.initial,
          products: [],
    );
  }

  // 모든 상품 로드
  Future<void> loadProducts() async {
    try {
      state = state.copyWith(
        status: ProductLoadStatus.loading,
        errorMessage: null,
        currentAction: ProductActionType.loadAll,
      );

      final products = await _productRepository.getAllProducts();

      state = state.copyWith(
        status: ProductLoadStatus.loaded,
        products: products,
        hasMore: false,
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

  // 위치 기반 상품 로드 (GeoPoint 사용, 좌표->locationTag 변환 필요)
  Future<void> loadProductsByLocation(GeoPoint location, double radius) async {
    try {
      state = state.copyWith(
        status: ProductLoadStatus.loading,
        products: [],
        lastDocument: null,
        hasMore: true,
        currentCoordinates: location,
        errorMessage: null,
        currentAction: ProductActionType.loadByLocation,
      );

      final result = await _productRepository.getProductsByLocation(location, radius, null, 20);

      // 좌표에 기반한 locationTag 결정
      String locationTag = '전체'; // 기본값
      
      // 좌표가 유효한 경우 좌표에 기반한 위치 태그 결정
      if (location.latitude != 0 && location.longitude != 0) {
        // 주요 지역의 좌표 중심과 해당 지역 태그 정의
        final regionMap = [
          {'name': '강남동', 'center': const GeoPoint(37.4988, 127.0281), 'radius': 2.0},
          {'name': '서초동', 'center': const GeoPoint(37.4923, 127.0292), 'radius': 2.0},
          {'name': '송파동', 'center': const GeoPoint(37.5145, 127.1057), 'radius': 2.0},
          {'name': '영등포동', 'center': const GeoPoint(37.5257, 126.8957), 'radius': 2.0}, 
          {'name': '강서동', 'center': const GeoPoint(37.5509, 126.8495), 'radius': 2.0},
        ];
        
        // 현재 위치와 가장 가까운 지역 찾기
        double minDistance = double.infinity;
        String nearestRegion = '특정 위치';
        
        for (final region in regionMap) {
          final center = region['center'] as GeoPoint;
          final radius = region['radius'] as double;
          
          // 두 좌표 간의 거리 계산 (Haversine 공식 대신 단순화된 근사값 사용)
          final latDiff = (location.latitude - center.latitude) * 111.0; // 1도당 약 111km
          final lngDiff = (location.longitude - center.longitude) * 111.0 * 
              cos(center.latitude * (3.141592 / 180.0)); // 위도에 따른 경도 거리 보정
          final distance = sqrt(latDiff * latDiff + lngDiff * lngDiff);
          
          if (distance < minDistance) {
            minDistance = distance;
            nearestRegion = region['name'] as String;
          }
        }
        
        // 가장 가까운 지역이 일정 거리 이내인 경우만 해당 지역으로 설정
        if (minDistance <= 5.0) { // 5km 이내
          locationTag = nearestRegion;
        } else {
          locationTag = '특정 위치'; // 어떤 지역에도 가깝지 않은 경우
        }
      }

      state = state.copyWith(
        status: ProductLoadStatus.loaded,
        products: result.products,
        lastDocument: result.lastDocument,
        hasMore: result.products.length == 20,
        currentLocationTag: locationTag,
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
  
  // 위치 기반 상품 더 로드 (페이지네이션)
  Future<void> loadMoreProductsByLocation() async {
    if (state.isLoadingMore || !state.hasMore || state.currentCoordinates == null) return;

    try {
      state = state.copyWith(isLoadingMore: true);

      final result = await _productRepository.getProductsByLocation(
        state.currentCoordinates!,
        5.0,
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

  // LocationTag 기반 상품 로드 (새로 추가)
  Future<void> loadProductsByLocationTag(String locationTag) async {
    try {
      state = state.copyWith(
        status: ProductLoadStatus.loading,
        products: [],
        lastDocument: null,
        hasMore: true,
        currentLocationTag: locationTag,
        errorMessage: null,
        currentAction: ProductActionType.loadByLocationTag,
      );

      final result = await _productRepository.getProductsByLocationTag(locationTag, null, 20);

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
  
  // LocationTag 기반 상품 더 로드 (페이지네이션)
  Future<void> loadMoreProductsByLocationTag() async {
    if (state.isLoadingMore || !state.hasMore || state.currentLocationTag == '전체') return;

    try {
      state = state.copyWith(isLoadingMore: true);
      
      final result = await _productRepository.getProductsByLocationTag(
        state.currentLocationTag,
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

  // 위치 설정 (GeoPoint와 locationTag 모두 저장)
  void setLocation(String location, GeoPoint? coordinates) {
    String locationTag = location;
    if (location != '전체') {
      if (location == '강남구') locationTag = '강남동';
      else if (location == '서초구') locationTag = '서초동';
      else if (location == '송파구') locationTag = '송파동';
    }

    state = state.copyWith(
      currentLocation: location,
      currentCoordinates: coordinates,
      currentLocationTag: locationTag,
    );
  }

  // 테스트용 더미 상품 추가
  Future<void> addDummyProducts() async {
    try {
      state = state.copyWith(
        isDummyAddLoading: true,
        currentAction: ProductActionType.addDummy,
      );
      
      await _productRepository.addDummyProducts();
      await loadProducts();
      
      state = state.copyWith(
        isDummyAddLoading: false,
        currentAction: ProductActionType.none,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
        isDummyAddLoading: false,
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
}