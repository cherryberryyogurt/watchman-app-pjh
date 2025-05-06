import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String location;
  final List<String> imageUrls;
  final String sellerId;
  final String sellerName;
  final GeoPoint? coordinates;
  final DateTime createdAt;
  final List<Map<String, dynamic>>? options;
  final int? stock;
  final bool isAvailable;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.location,
    required this.imageUrls,
    required this.sellerId,
    required this.sellerName,
    this.coordinates,
    required this.createdAt,
    this.options,
    this.stock,
    this.isAvailable = true,
  });

  // From Firebase doc
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      location: data['location'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      coordinates: data['coordinates'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      options: data['options'] != null 
          ? List<Map<String, dynamic>>.from(data['options']) 
          : null,
      stock: data['stock'],
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  // To Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'location': location,
      'imageUrls': imageUrls,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'coordinates': coordinates,
      'createdAt': Timestamp.fromDate(createdAt),
      'options': options,
      'stock': stock,
      'isAvailable': isAvailable,
    };
  }
} 