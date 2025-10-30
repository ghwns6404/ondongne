import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> userIds;
  final String lastMessage;
  final Timestamp lastMessageAt;
  final Map<String, String> userNames; 
  
  ChatRoom({
    required this.id,
    required this.userIds,
    this.lastMessage = '',
    required this.lastMessageAt,
    required this.userNames,
  });

  factory ChatRoom.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      userIds: List<String>.from(data['userIds'] ?? []),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: data['lastMessageAt'] as Timestamp? ?? Timestamp.now(),
      userNames: Map<String, String>.from(data['userNames'] ?? {}),
    );
  }
}
