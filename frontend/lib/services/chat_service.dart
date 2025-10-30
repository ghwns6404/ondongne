import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_room.dart';
import '../models/message.dart';
import 'user_service.dart';

class ChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _roomsCol =>
      _db.collection('chat_rooms');

  static String getChatRoomId(String userId1, String userId2) {
    if (userId1.hashCode <= userId2.hashCode) {
      return '$userId1-$userId2';
    } else {
      return '$userId2-$userId1';
    }
  }

  static Future<String> getOrCreateChatRoom(String otherUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('로그인이 필요합니다.');
    
    final myId = currentUser.uid;
    final chatRoomId = getChatRoomId(myId, otherUserId);
    final roomRef = _roomsCol.doc(chatRoomId);
    final roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      final myName = (await UserService.getUser(myId))?.name ?? '사용자';
      final otherName = (await UserService.getUser(otherUserId))?.name ?? '상대방';
      
      final newRoom = {
        'userIds': [myId, otherUserId],
        'lastMessage': '채팅방이 개설되었습니다.',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'userNames': {
          myId: myName,
          otherUserId: otherName,
        }
      };
      await roomRef.set(newRoom);
    }
    return chatRoomId;
  }

  static Stream<List<ChatRoom>> watchChatRooms() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _roomsCol
        .where('userIds', arrayContains: currentUser.uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatRoom.fromDoc(doc)).toList());
  }

  static Stream<List<Message>> watchMessages(String chatRoomId) {
    return _roomsCol
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromDoc(doc)).toList());
  }

  static Future<void> sendMessage(String chatRoomId, String text) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || text.trim().isEmpty) return;

    final messageCol = _roomsCol.doc(chatRoomId).collection('messages');
    final roomRef = _roomsCol.doc(chatRoomId);

    await _db.runTransaction((transaction) async {
      final newMessage = {
        'senderId': currentUser.uid,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };
      transaction.set(messageCol.doc(), newMessage);
      
      transaction.update(roomRef, {
        'lastMessage': text.trim(),
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> leaveChatRoom(String chatRoomId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    final roomRef = _roomsCol.doc(chatRoomId);
    await _db.runTransaction((txn) async {
      final roomSnap = await txn.get(roomRef);
      if (!roomSnap.exists) return;
      final data = roomSnap.data() as Map<String, dynamic>;
      final userIds = List<String>.from(data['userIds'] ?? []);
      userIds.remove(currentUser.uid);
      if (userIds.isEmpty) {
        // 방 및 메시지 완전 삭제
        final messagesRef = roomRef.collection('messages');
        final messagesSnap = await messagesRef.get();
        for (final msgDoc in messagesSnap.docs) {
          txn.delete(msgDoc.reference);
        }
        txn.delete(roomRef);
      } else {
        txn.update(roomRef, {'userIds': userIds});
      }
    });
  }
}
