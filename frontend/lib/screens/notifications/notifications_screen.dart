import 'package:flutter/material.dart';
import '../../models/notification.dart';
import '../../services/notification_service.dart';
import '../news/news_detail_screen.dart';
import '../marketplace/product_detail_screen.dart';
import '../../services/news_service.dart';
import '../../services/admin_news_service.dart';
import '../../services/product_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        actions: [
          // 모두 읽음 처리
          IconButton(
            onPressed: () async {
              await NotificationService.markAllAsRead();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('모든 알림을 읽음 처리했습니다')),
                );
              }
            },
            icon: const Icon(Icons.done_all),
            tooltip: '모두 읽음',
          ),
          // 모두 삭제
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('알림 전체 삭제'),
                  content: const Text('모든 알림을 삭제하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await NotificationService.deleteAllNotifications();
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('모든 알림을 삭제했습니다')),
                          );
                        }
                      },
                      child: const Text('삭제', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.delete_outline),
            tooltip: '전체 삭제',
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationService.watchMyNotifications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('오류가 발생했습니다: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '알림이 없습니다',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        NotificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림이 삭제되었습니다')),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: notification.isRead ? Colors.white : Colors.blue[50],
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getTypeColor(notification.type),
            child: Icon(
              _getTypeIcon(notification.type),
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(notification.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: () => _handleNotificationTap(context, notification),
        ),
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.comment:
        return Icons.comment;
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.chat:
        return Icons.chat;
      case NotificationType.system:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.comment:
        return Colors.blue;
      case NotificationType.like:
        return Colors.red;
      case NotificationType.chat:
        return Colors.green;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('MM월 dd일').format(date);
    }
  }

  Future<void> _handleNotificationTap(
      BuildContext context, AppNotification notification) async {
    // 읽음 처리
    if (!notification.isRead) {
      await NotificationService.markAsRead(notification.id);
    }

    // 타입에 따라 화면 이동
    try {
      switch (notification.type) {
        case NotificationType.comment:
        case NotificationType.like:
          final postId = notification.data['postId'] as String?;
          final postType = notification.data['postType'] as String?;

          if (postId == null || postType == null) return;

          if (postType == 'product') {
            final product = await ProductService.getProduct(postId);
            if (product != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(product: product),
                ),
              );
            }
          } else {
            var news = await NewsService.getNews(postId);
            news ??= await AdminNewsService.getAdminNews(postId);
            if (news != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewsDetailScreen(news: news!),
                ),
              );
            }
          }
          break;

        case NotificationType.chat:
          final chatRoomId = notification.data['chatRoomId'] as String?;
          if (chatRoomId != null && context.mounted) {
            // TODO: ChatDetailScreen으로 이동 (chatRoomId로 채팅방 정보 가져와야 함)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('채팅 화면으로 이동합니다')),
            );
          }
          break;

        case NotificationType.system:
          // 시스템 알림은 별도 처리 없음
          break;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('페이지를 열 수 없습니다: $e')),
        );
      }
    }
  }
}

