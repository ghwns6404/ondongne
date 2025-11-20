import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart';

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  /// 알림 생성
  static Future<String> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? imageUrl,
    required Map<String, dynamic> data,
  }) async {
    final doc = await _col.add({
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// 댓글 알림 생성
  static Future<void> notifyComment({
    required String postOwnerId,  // 게시물 작성자 ID
    required String commenterName, // 댓글 작성자 이름
    required String postTitle,     // 게시물 제목
    required String postId,
    required String postType,      // 'news', 'product', etc.
  }) async {
    // 자기 게시물에 자기가 댓글 단 경우 알림 X
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid == postOwnerId) return;

    await createNotification(
      userId: postOwnerId,
      type: NotificationType.comment,
      title: '💬 새 댓글',
      body: '$commenterName님이 "$postTitle"에 댓글을 남겼습니다.',
      data: {
        'postId': postId,
        'postType': postType,
      },
    );
  }

  /// 좋아요 알림 생성
  static Future<void> notifyLike({
    required String postOwnerId,
    required String likerName,
    required String postTitle,
    required String postId,
    required String postType,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid == postOwnerId) return;

    await createNotification(
      userId: postOwnerId,
      type: NotificationType.like,
      title: '❤️ 새 좋아요',
      body: '$likerName님이 "$postTitle"을(를) 좋아합니다.',
      data: {
        'postId': postId,
        'postType': postType,
      },
    );
  }

  /// 채팅 알림 생성
  static Future<void> notifyChat({
    required String recipientId,
    required String senderName,
    required String messagePreview,
    required String chatRoomId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid == recipientId) return;

    await createNotification(
      userId: recipientId,
      type: NotificationType.chat,
      title: '💌 새 메시지',
      body: '$senderName: $messagePreview',
      data: {
        'chatRoomId': chatRoomId,
      },
    );
  }

  /// 약속 알림 생성
  static Future<void> notifyAppointment({
    required String receiverId,
    required String type, // 'proposal', 'accepted', 'rejected', 'cancelled'
    required String appointmentId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid == receiverId) return;

    String title = '';
    String body = '';

    switch (type) {
      case 'proposal':
        title = '📅 약속 제안';
        body = '새로운 약속 제안이 도착했습니다.';
        break;
      case 'accepted':
        title = '✅ 약속 수락';
        body = '약속이 확정되었습니다!';
        break;
      case 'rejected':
        title = '❌ 약속 거절';
        body = '약속이 거절되었습니다.';
        break;
      case 'cancelled':
        title = '🚫 약속 취소';
        body = '약속이 취소되었습니다.';
        break;
    }

    await createNotification(
      userId: receiverId,
      type: NotificationType.chat, // 임시로 chat 타입 사용 (나중에 appointment 타입 추가 가능)
      title: title,
      body: body,
      data: {
        'appointmentId': appointmentId,
        'appointmentType': type,
      },
    );
  }

  /// 내 알림 목록 가져오기 (Stream)
  static Stream<List<AppNotification>> watchMyNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _col
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(50) // 최근 50개만
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromDoc(doc))
            .toList());
  }

  /// 읽지 않은 알림 개수 가져오기
  static Stream<int> watchUnreadCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return _col
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 알림 읽음 처리
  static Future<void> markAsRead(String notificationId) async {
    await _col.doc(notificationId).update({'isRead': true});
  }

  /// 모든 알림 읽음 처리
  static Future<void> markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = _db.batch();
    final snapshot = await _col
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  /// 알림 삭제
  static Future<void> deleteNotification(String notificationId) async {
    await _col.doc(notificationId).delete();
  }

  /// 모든 알림 삭제
  static Future<void> deleteAllNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = _db.batch();
    final snapshot = await _col
        .where('userId', isEqualTo: user.uid)
        .get();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}

