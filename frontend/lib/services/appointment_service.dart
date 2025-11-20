import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment.dart';
import 'notification_service.dart';

class AppointmentService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('appointments');

  /// 약속 생성
  static Future<String> createAppointment({
    required String chatRoomId,
    required String receiverId,
    required DateTime dateTime,
    required String location,
    GeoPoint? coordinates,
    String? memo,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final doc = await _col.add({
      'chatRoomId': chatRoomId,
      'proposerId': user.uid,
      'receiverId': receiverId,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'coordinates': coordinates,
      'memo': memo,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'respondedAt': null,
    });

    // 알림 전송
    await NotificationService.notifyAppointment(
      receiverId: receiverId,
      type: 'proposal',
      appointmentId: doc.id,
    );

    return doc.id;
  }

  /// 약속 수락
  static Future<void> acceptAppointment(String appointmentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    await _col.doc(appointmentId).update({
      'status': 'accepted',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // 제안자에게 알림
    final appointment = await getAppointment(appointmentId);
    if (appointment != null) {
      await NotificationService.notifyAppointment(
        receiverId: appointment.proposerId,
        type: 'accepted',
        appointmentId: appointmentId,
      );
    }
  }

  /// 약속 거절
  static Future<void> rejectAppointment(String appointmentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    await _col.doc(appointmentId).update({
      'status': 'rejected',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // 제안자에게 알림
    final appointment = await getAppointment(appointmentId);
    if (appointment != null) {
      await NotificationService.notifyAppointment(
        receiverId: appointment.proposerId,
        type: 'rejected',
        appointmentId: appointmentId,
      );
    }
  }

  /// 약속 취소
  static Future<void> cancelAppointment(String appointmentId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final appointment = await getAppointment(appointmentId);
    if (appointment == null) {
      throw Exception('약속을 찾을 수 없습니다.');
    }

    // 본인이 제안자 또는 수신자인지 확인
    if (appointment.proposerId != user.uid && appointment.receiverId != user.uid) {
      throw Exception('이 약속을 취소할 권한이 없습니다.');
    }

    await _col.doc(appointmentId).update({
      'status': 'cancelled',
      'respondedAt': FieldValue.serverTimestamp(),
    });

    // 상대방에게 알림
    final otherUserId = appointment.proposerId == user.uid
        ? appointment.receiverId
        : appointment.proposerId;

    await NotificationService.notifyAppointment(
      receiverId: otherUserId,
      type: 'cancelled',
      appointmentId: appointmentId,
    );
  }

  /// 약속 완료 처리
  static Future<void> completeAppointment(String appointmentId) async {
    await _col.doc(appointmentId).update({
      'status': 'completed',
    });
  }

  /// 약속 조회
  static Future<Appointment?> getAppointment(String appointmentId) async {
    final doc = await _col.doc(appointmentId).get();
    if (!doc.exists) return null;
    return Appointment.fromDoc(doc);
  }

  /// 채팅방의 약속 목록 조회 (스트림)
  static Stream<List<Appointment>> watchChatRoomAppointments(String chatRoomId) {
    return _col
        .where('chatRoomId', isEqualTo: chatRoomId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Appointment.fromDoc(doc)).toList();
    });
  }

  /// 내 약속 목록 조회 (스트림)
  static Stream<List<Appointment>> watchMyAppointments() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    // 내가 제안한 약속 또는 받은 약속
    return _col
        .where('status', whereIn: ['pending', 'accepted'])
        .orderBy('dateTime', descending: false) // 가까운 약속부터
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Appointment.fromDoc(doc))
          .where((appointment) =>
              appointment.proposerId == user.uid ||
              appointment.receiverId == user.uid)
          .toList();
    });
  }

}

