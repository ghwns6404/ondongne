import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String text;
  final Timestamp createdAt;

  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory Message.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] as String,
      text: data['text'] as String,
      createdAt: data['createdAt'] as Timestamp,
    );
  }
}
