import 'package:flutter/material.dart';

class TopAppBar extends StatelessWidget {
  final VoidCallback onChatbotPressed;
  final VoidCallback onNotificationPressed;

  const TopAppBar({
    super.key,
    required this.onChatbotPressed,
    required this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          // 로고
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
