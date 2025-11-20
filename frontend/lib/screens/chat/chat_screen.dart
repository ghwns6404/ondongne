import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/chat_room.dart';
import '../../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅'),
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: ChatService.watchChatRooms(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '오류가 발생했습니다. Firestore 색인(Index)이 설정되었는지 확인해주세요.\n\n오류: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('진행 중인 대화가 없습니다.'),
            );
          }
          final chatRooms = snapshot.data!;

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final room = chatRooms[index];
              final otherUserId = room.userIds.firstWhere((id) => id != currentUser?.uid, orElse: () => '');
              final otherUserName = (room.userNames[otherUserId]?.isNotEmpty ?? false)
                ? room.userNames[otherUserId]!
                : (otherUserId.isNotEmpty ? '${otherUserId.substring(0,6)}...' : '?');
              
              return ListTile(
                leading: CircleAvatar(
                  child: Text(otherUserName.substring(0, 1)),
                ),
                title: Text(otherUserName),
                subtitle: Text(
                  room.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: Icon(Icons.close),
                  tooltip: '채팅방 나가기',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('채팅방 나가기'),
                        content: Text('정말 이 채팅방을 나가시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('취소'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('나가기'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed ?? false) {
                      await ChatService.leaveChatRoom(room.id);
                    }
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        chatRoomId: room.id,
                        otherUserName: otherUserName,
                        otherUserId: otherUserId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
