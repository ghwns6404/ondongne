import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/message.dart';
import '../../models/appointment.dart';
import '../../services/chat_service.dart';
import '../../services/appointment_service.dart';
import '../../services/storage_service.dart';
import 'widgets/appointment_bottom_sheet.dart';
import 'widgets/appointment_card.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserName;
  final String otherUserId; // 추가

  const ChatDetailScreen({
    super.key,
    required this.chatRoomId,
    required this.otherUserName,
    required this.otherUserId, // 추가
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  late final Stream<List<Message>> _messageStream;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _messageStream = ChatService.watchMessages(widget.chatRoomId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text;
    _messageController.clear();
    await ChatService.sendMessage(widget.chatRoomId, messageText);
  }

  /// 이미지 선택 및 전송
  Future<void> _pickAndSendImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      // Firebase Storage에 업로드
      final imageUrl = await StorageService.uploadImage(
        file: image,
        folder: 'chat',
      );

      // 이미지 메시지 전송
      await ChatService.sendImageMessage(widget.chatRoomId, imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사진을 전송했습니다'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사진 전송 실패: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _leaveChatRoom() async {
    await ChatService.leaveChatRoom(widget.chatRoomId);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  /// 약속 잡기 바텀시트 열기
  Future<void> _openAppointmentSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppointmentBottomSheet(
        chatRoomId: widget.chatRoomId,
        receiverId: widget.otherUserId,
      ),
    );

    if (result != null && mounted) {
      try {
        // 약속 생성
        final appointmentId = await AppointmentService.createAppointment(
          chatRoomId: widget.chatRoomId,
          receiverId: widget.otherUserId,
          dateTime: result['dateTime'] as DateTime,
          location: result['location'] as String,
          coordinates: result['coordinates'] as GeoPoint?,
          memo: result['memo'] as String?,
        );

        // 채팅에 약속 메시지 전송
        await ChatService.sendAppointmentMessage(
          widget.chatRoomId,
          appointmentId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('약속 제안을 보냈습니다!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('약속 생성 실패: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 상단에는 otherUserName (닉네임) 이 표시됨
        title: Text(widget.otherUserName),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.calendar_month, size: 26),
              tooltip: '약속 잡기',
              onPressed: _openAppointmentSheet,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 4, right: 8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.exit_to_app, size: 26),
              tooltip: '채팅방 나가기',
              color: Colors.red,
              onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('채팅방 나가기'),
                  content: Text('채팅방을 나가시겠습니까?'),
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
                await _leaveChatRoom();
              }
            },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messageStream,
              builder: (context, snapshot) {
                // 디버깅용 로그 추가
                print('Connection State: ${snapshot.connectionState}');
                if (snapshot.hasData) {
                  print('Messages Count: ${snapshot.data!.length}');
                }
                if (snapshot.hasError) {
                  print('Stream Error: ${snapshot.error}');
                  return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUser?.uid;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    // 약속 메시지인 경우
    if (message.isAppointment && message.appointmentId != null) {
      return FutureBuilder<Appointment?>(
        future: AppointmentService.getAppointment(message.appointmentId!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final appointment = snapshot.data!;
          return AppointmentCard(
            appointment: appointment,
            isMe: isMe,
          );
        },
      );
    }

    // 이미지 메시지인 경우
    if (message.isImage) {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          constraints: const BoxConstraints(
            maxWidth: 250,
            maxHeight: 300,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              message.text, // 이미지 URL
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 200,
                  height: 200,
                  alignment: Alignment.center,
                  color: Colors.grey[200],
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  alignment: Alignment.center,
                  color: Colors.grey[300],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('이미지 로드 실패', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    // 일반 텍스트 메시지
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 약속 잡기 버튼
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.calendar_month, size: 22),
                onPressed: _openAppointmentSheet,
                color: Colors.white,
                tooltip: '약속 잡기',
              ),
            ),
            // 이미지 전송 버튼
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[600]!],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _isUploadingImage
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.image, size: 22),
                      onPressed: _pickAndSendImage,
                      color: Colors.white,
                      tooltip: '사진 보내기',
                    ),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: '메시지를 입력하세요...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendMessage,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
