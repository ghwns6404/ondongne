import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment.dart';
import 'notification_service.dart';

class CommentService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('comments');

  // 댓글 생성
  static Future<String> createComment({
    required String postId,
    required String postType, // 'news' 또는 'adminNews'
    required String content,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 사용자 이름 가져오기
    final userDoc = await _db.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final userName = userData?['name'] ?? '익명';

    final doc = await _col.add({
      'authorId': user.uid,
      'authorName': userName,
      'content': content,
      'postId': postId,
      'postType': postType,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
    });
    
    // 알림 발송: 게시물 작성자 찾기
    try {
      String? postOwnerId;
      String? postTitle;
      
      if (postType == 'news') {
        final postDoc = await _db.collection('news').doc(postId).get();
        if (postDoc.exists) {
          postOwnerId = postDoc.data()?['authorId'] as String?;
          postTitle = postDoc.data()?['title'] as String?;
        }
      } else if (postType == 'adminNews') {
        final postDoc = await _db.collection('adminNews').doc(postId).get();
        if (postDoc.exists) {
          postOwnerId = postDoc.data()?['authorId'] as String?;
          postTitle = postDoc.data()?['title'] as String?;
        }
      } else if (postType == 'product') {
        final postDoc = await _db.collection('products').doc(postId).get();
        if (postDoc.exists) {
          postOwnerId = postDoc.data()?['sellerId'] as String?;
          postTitle = postDoc.data()?['title'] as String?;
        }
      }
      
      if (postOwnerId != null && postTitle != null) {
        await NotificationService.notifyComment(
          postOwnerId: postOwnerId,
          commenterName: userName,
          postTitle: postTitle,
          postId: postId,
          postType: postType,
        );
      }
    } catch (e) {
      print('댓글 알림 발송 실패: $e');
      // 알림 실패해도 댓글 작성은 성공
    }
    
    return doc.id;
  }

  // 댓글 수정
  static Future<void> updateComment(
    String commentId, {
    required String content,
  }) async {
    await _col.doc(commentId).update({
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 댓글 삭제
  static Future<void> deleteComment(String commentId) async {
    await _col.doc(commentId).delete();
  }

  // 특정 게시물의 댓글 조회
  static Stream<List<Comment>> watchComments({
    required String postId,
    required String postType,
  }) {
    return _col
        .where('postId', isEqualTo: postId)
        .where('postType', isEqualTo: postType)
        .snapshots()
        .map((snapshot) {
          final comments = snapshot.docs.map((d) => Comment.fromDoc(d)).toList();
          // 클라이언트에서 정렬
          comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return comments;
        });
  }

  // 댓글 개수 조회
  static Stream<int> watchCommentCount({
    required String postId,
    required String postType,
  }) {
    return _col
        .where('postId', isEqualTo: postId)
        .where('postType', isEqualTo: postType)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
