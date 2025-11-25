import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final int price;
  final List<String> imageUrls;
  final String region; // 예: 대전 동구, 대전 유성구 등
  final String category; // 카테고리
  final String status; // 'available', 'reserved', 'sold'
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final List<String> favoriteUserIds; // 즐겨찾기한 사용자 uid 목록
  final int viewCount; // 조회수
  final List<String> viewedUserIds; // 조회한 사용자 uid 목록 (중복 방지용)

  Product({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrls,
    required this.region,
    this.category = '기타 중고물품', // 기본값
    this.status = 'available', // 기본값: 판매중
    required this.createdAt,
    this.updatedAt,
    required this.favoriteUserIds,
    this.viewCount = 0,
    this.viewedUserIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'title': title,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'region': region,
      'category': category,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'favoriteUserIds': favoriteUserIds,
      'viewCount': viewCount,
      'viewedUserIds': viewedUserIds,
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
      category: data['category'] as String? ?? '기타 중고물품', // 기존 데이터 호환성
      status: data['status'] as String? ?? 'available', // 기존 데이터 호환성
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp?,
      favoriteUserIds: (data['favoriteUserIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      viewCount: (data['viewCount'] as num?)?.toInt() ?? 0,
      viewedUserIds: (data['viewedUserIds'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
