import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final String postId; // 게시물 ID (news 또는 adminNews)
  final String postType; // 'news' 또는 'adminNews'
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  Comment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.postId,
    required this.postType,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'postId': postId,
      'postType': postType,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Comment.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Comment(
      id: doc.id,
      authorId: data['authorId'] as String,
      authorName: data['authorName'] as String,
      content: data['content'] as String,
      postId: data['postId'] as String,
      postType: data['postType'] as String,
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }
}
