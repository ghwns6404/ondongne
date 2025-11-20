import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String text;
  final Timestamp createdAt;
  final String type;         // 'text', 'image', 'appointment'
  final String? appointmentId; // 약속 ID (type이 'appointment'일 때)

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.type = 'text',      // 기본값: 텍스트 메시지
    this.appointmentId,
  });

  factory Message.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] as String,
      text: data['text'] as String,
      createdAt: data['createdAt'] as Timestamp,
      type: data['type'] as String? ?? 'text',
      appointmentId: data['appointmentId'] as String?,
    );
  }

  /// 텍스트 메시지인지
  bool get isText => type == 'text';

  /// 이미지 메시지인지
  bool get isImage => type == 'image';

  /// 약속 메시지인지
  bool get isAppointment => type == 'appointment';
}
