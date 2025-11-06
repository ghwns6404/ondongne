import 'package:flutter/material.dart';

class TopAppBar extends StatelessWidget {
  final VoidCallback onChatbotPressed;
  final VoidCallback onNotificationPressed;
  final String? dong;
  final bool locLoading;
  final String? locError;
  final VoidCallback? onRefreshLocation;

  const TopAppBar({
    super.key,
    required this.onChatbotPressed,
    required this.onNotificationPressed,
    this.dong,
    this.locLoading = false,
    this.locError,
    this.onRefreshLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 로고 + 내 동네
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'On!동네',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              if (locLoading)
                Text(
                  '내 동네 확인 중…',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                )
              else if (locError != null)
                Text(
                  '내 동네: 알 수 없음',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                )
              else if (dong != null)
                Row(
                  children: [
                    Icon(Icons.place, size: 14, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '내 동네: $dong',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    if (onRefreshLocation != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.refresh, size: 16, color: Theme.of(context).colorScheme.primary),
                        onPressed: locLoading ? null : onRefreshLocation,
                        tooltip: '위치 새로고침',
                      ),
                    ],
                  ],
                ),
            ],
          ),
          
          // 우측 버튼들
          Row(
            children: [
              // 챗봇 버튼
              IconButton(
                onPressed: onChatbotPressed,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                ),
                tooltip: '챗봇',
              ),
              
              const SizedBox(width: 8),
              
              // 알림 버튼
              IconButton(
                onPressed: onNotificationPressed,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Colors.red[600],
                    size: 20,
                  ),
                ),
                tooltip: '알림',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
