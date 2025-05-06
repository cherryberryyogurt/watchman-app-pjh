import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';

enum ProductLoadStatus {
  initial,
  loading,
  loaded,
  error,
}

class ProductProvider with ChangeNotifier {
  final ProductRepository _productRepository;

  // State
  ProductLoadStatus _status = ProductLoadStatus.initial;
  List<ProductModel> _products = [];
  ProductModel? _selectedProduct;
  String? _errorMessage;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  String _currentLocation = '전체';
  GeoPoint? _currentCoordinates;

  // Constructor
  ProductProvider({
    required ProductRepository productRepository,
  }) : _productRepository = productRepository;

  // Getters
  ProductLoadStatus get status => _status;
  List<ProductModel> get products => _products;
  ProductModel? get selectedProduct => _selectedProduct;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  String get currentLocation => _currentLocation;
  GeoPoint? get currentCoordinates => _currentCoordinates;

  // Load products
  Future<void> loadProducts() async {
    try {
      _status = ProductLoadStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final products = await _productRepository.getAllProducts();
      
      _products = products;
      _status = ProductLoadStatus.loaded;
      
      notifyListeners();
    } catch (e) {
      _status = ProductLoadStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Load products by location
  Future<void> loadProductsByLocation(GeoPoint location, double radius) async {
    try {
      _status = ProductLoadStatus.loading;
      _currentCoordinates = location;
      _errorMessage = null;
      notifyListeners();

      final products = await _productRepository.getProductsByLocation(location, radius);
      
      _products = products;
      _status = ProductLoadStatus.loaded;
      
      notifyListeners();
    } catch (e) {
      _status = ProductLoadStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Get product details
  Future<void> getProductDetails(String productId) async {
    try {
      _status = ProductLoadStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final product = await _productRepository.getProductById(productId);
      
      _selectedProduct = product;
      _status = ProductLoadStatus.loaded;
      
      notifyListeners();
    } catch (e) {
      _status = ProductLoadStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Set location
  void setLocation(String location, GeoPoint? coordinates) {
    _currentLocation = location;
    _currentCoordinates = coordinates;
    notifyListeners();
  }

  // Add dummy products (for testing)
  Future<void> addDummyProducts() async {
    try {
      await _productRepository.addDummyProducts();
      await loadProducts();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Clear selected product
  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
} 