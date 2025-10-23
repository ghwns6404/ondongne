import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/login_screen.dart';
import 'marketplace/marketplace_tab.dart';
import 'news/news_screen.dart';
import 'chat/chat_screen.dart';
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
    return Scaffold(
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            '채팅',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '곧 만나볼 수 있습니다!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
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
                // 프로필 헤더
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Text(
                          userData['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            color: Color(0xFFFF6B35),
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userData['name'] ?? '사용자',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userData['email'] ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // 프로필 정보
                _buildProfileInfo('가입일', '방금 전'),
                _buildProfileInfo('상태', '온라인'),
                _buildProfileInfo('이메일', userData['email'] ?? ''),
                
                const SizedBox(height: 32),
                
                // 로그아웃 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildProfileInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

}