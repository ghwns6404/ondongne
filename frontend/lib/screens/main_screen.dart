import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/login_screen.dart';
import 'marketplace/marketplace_tab.dart';
import 'news/news_screen.dart';
import 'chat/chat_screen.dart'; // 수정: chat_screen.dart 임포트
import 'widgets/top_app_bar.dart';
import 'widgets/news_section.dart';
import 'widgets/popular_products_section.dart';
import 'widgets/ad_banner.dart';
import 'widgets/bottom_navigation.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  Future<void> _logout() async {
    try {
      if (_user != null) {
        await FirebaseFirestore.instance.collection('users').doc(_user!.uid).update({
          'isOnline': false,
          'lastLogoutAt': FieldValue.serverTimestamp(),
        });
      }
      
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 상단바 (항상 고정)
            TopAppBar(
              onChatbotPressed: () {
                // 챗봇 기능 (미구현)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('챗봇 기능은 곧 만나볼 수 있습니다!')),
                );
              },
              onNotificationPressed: () {
                // 알림 기능 (미구현)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알림 기능은 곧 만나볼 수 있습니다!')),
                );
              },
            ),
            
            // 메인 콘텐츠 (탭에 따라 변경)
            Expanded(
              child: _buildCurrentPage(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildNewsPage();
      case 2:
        return _buildMarketplacePage();
      case 3:
        return _buildChatPage();
      case 4:
        return _buildProfilePage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 우리동네 소식
          const NewsSection(),
          
          const SizedBox(height: 24),
          
          // 인기있는 물품
          const PopularProductsSection(),
          
          const SizedBox(height: 24),
          
          // 광고 배너
          const AdBanner(),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNewsPage() {
    return const NewsScreen();
  }

  Widget _buildMarketplacePage() {
    return const MarketplaceTab();
  }

  Widget _buildChatPage() {
    return const ChatListScreen(); // 수정: 플레이스홀더를 ChatListScreen으로 교체
  }

  Widget _buildProfilePage() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return StreamBuilder<DocumentSnapshot>(
      stream: _user != null 
          ? FirebaseFirestore.instance.collection('users').doc(_user!.uid).snapshots()
          : null,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Toss 스타일 프로필 헤더
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Text(
                          userData['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userData['name'] ?? '사용자',
                        style: textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userData['email'] ?? '',
                        style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Toss 스타일 프로필 정보
                _buildProfileInfo('가입일', '방금 전', scheme, textTheme),
                _buildProfileInfo('상태', '온라인', scheme, textTheme),
                _buildProfileInfo('이메일', userData['email'] ?? '', scheme, textTheme),
                const SizedBox(height: 32),
                // Toss 스타일 로그아웃 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: scheme.error,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '로그아웃',
                      style: textTheme.titleMedium?.copyWith(color: scheme.error, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget _buildProfileInfo(String label, String value, ColorScheme scheme, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(color: scheme.primary),
          ),
        ],
      ),
    );
  }

}