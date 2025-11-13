import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  comment,      // 댓글
  like,         // 좋아요
  chat,         // 채팅 메시지
  system,       // 시스템 알림
}

class AppNotification {
  final String id;
  final String userId;           // 알림 받을 사용자 ID
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl;        // 관련 이미지 (선택)
  final Map<String, dynamic> data; // 관련 데이터 (게시물 ID, 댓글 ID 등)
  final bool isRead;             // 읽음 여부
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      userId: data['userId'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${data['type']}',
        orElse: () => NotificationType.system,
      ),
      title: data['title'] as String,
      body: data['body'] as String,
      imageUrl: data['imageUrl'] as String?,
      data: Map<String, dynamic>.from(data['data'] as Map),
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

