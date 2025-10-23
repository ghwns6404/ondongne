import 'package:flutter/material.dart';

class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return _buildAdBanner(index);
        },
      ),
    );
  }

  Widget _buildAdBanner(int index) {
    final banners = [
      {
        'title': '온동네와 함께하는',
        'subtitle': '스마트한 중고거래!',
        'button': '지금 시작하기',
        'icon': Icons.shopping_cart,
        'colors': [const Color(0xFFFF6B35), const Color(0xFFFF8A65)],
      },
      {
        'title': '동네 사람들과',
        'subtitle': '소통하세요!',
        'button': '커뮤니티 참여',
        'icon': Icons.people,
        'colors': [const Color(0xFF2196F3), const Color(0xFF64B5F6)],
      },
      {
        'title': '실시간 채팅으로',
        'subtitle': '빠른 거래!',
        'button': '채팅 시작',
        'icon': Icons.chat,
        'colors': [const Color(0xFF4CAF50), const Color(0xFF81C784)],
      },
    ];

    final banner = banners[index];

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: banner['colors'] as List<Color>,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (banner['colors'] as List<Color>)[0].withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 배경 패턴
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // 메인 콘텐츠
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 텍스트 부분
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        banner['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        banner['subtitle'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          banner['button'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 아이콘 부분
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    banner['icon'] as IconData,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
