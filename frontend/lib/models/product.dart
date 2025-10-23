import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final int price;
  final List<String> imageUrls;
  final String region; // 예: 대전 동구, 대전 유성구 등
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final List<String> favoriteUserIds; // 즐겨찾기한 사용자 uid 목록

  Product({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrls,
    required this.region,
    required this.createdAt,
    this.updatedAt,
    required this.favoriteUserIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'region': region,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'favoriteUserIds': favoriteUserIds,
    };
  }

  factory Product.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      sellerId: data['sellerId'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      price: (data['price'] as num).toInt(),
      imageUrls: (data['imageUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      region: data['region'] as String,
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp?,
      favoriteUserIds: (data['favoriteUserIds'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
