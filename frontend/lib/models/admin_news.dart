import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNews {
  final String id;
  final String title;
  final String content;
  final String region;
  final List<String> imageUrls;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final List<String> favoriteUserIds; // 즐겨찾기한 사용자 uid 목록

  AdminNews({
    required this.id,
    required this.title,
    required this.content,
    required this.region,
    required this.imageUrls,
    required this.createdAt,
    this.updatedAt,
    required this.favoriteUserIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'region': region,
      'imageUrls': imageUrls,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'favoriteUserIds': favoriteUserIds,
    };
  }

  factory AdminNews.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminNews(
      id: doc.id,
      title: data['title'] as String,
      content: data['content'] as String,
      region: data['region'] as String,
      imageUrls: (data['imageUrls'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp?,
      favoriteUserIds: (data['favoriteUserIds'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
