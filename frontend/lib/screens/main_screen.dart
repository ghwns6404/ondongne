import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'marketplace/marketplace_tab.dart';
import 'news/news_screen.dart';
import 'chat/chat_screen.dart'; // 수정: chat_screen.dart 임포트
import 'chatbot/chatbot_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';
import 'widgets/top_app_bar.dart';
import 'widgets/admin_news_section.dart';
import 'widgets/news_section.dart';
import 'widgets/popular_products_section.dart';
import 'widgets/recommended_products_section.dart';
import 'widgets/trending_news_section.dart';
import 'widgets/ad_banner.dart';
import 'widgets/bottom_navigation.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _dong;          // 현재 동 이름
  String? _locError;      // 위치/주소 에러 메시지
  bool _locLoading = true; // 로딩 상태

  @override
  void initState() {
    super.initState();
    _loadDong(); //  현재 동 로드
  }

  //  추가: 동(행정동) 가져오기
  Future<void> _loadDong() async {
    setState(() {
      _locLoading = true;
      _locError = null;
    });
    try {
      final dong = await LocationService.getCurrentDong();
      if (!mounted) return;
      setState(() {
        _dong = dong;
        _locLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locError = e.toString();
        _locLoading = false;
      });
    }
  }

  void _openChatbot() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Chatbot',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: const ChatbotScreen(),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
    );
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
                _openChatbot();
              },
              onNotificationPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              dong: _dong,
              locLoading: _locLoading,
              locError: _locError,
              onRefreshLocation: _loadDong,
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
        return const ProfileScreen();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 검색바
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '검색어를 입력하세요 (예: 사탕)',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // 우리동네 공지사항 (어드민 글)
          AdminNewsSection(
            searchQuery: _searchQuery,
            onMorePressed: () {
              setState(() {
                _currentIndex = 1; // 소식 탭
              });
            },
          ),
          
          const SizedBox(height: 24),

          // 우리동네 소식 (일반 사용자 글)
          NewsSection(
            searchQuery: _searchQuery,
            onMorePressed: () {
              setState(() {
                _currentIndex = 1; // 소식 탭
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // 좋아요 많은 소식
          const TrendingNewsSection(),

          const SizedBox(height: 24),

          // 당신을 위한 추천
          RecommendedProductsSection(
            onMorePressed: () {
              setState(() {
                _currentIndex = 2; // 중고거래 탭
              });
            },
          ),

          const SizedBox(height: 24),

          // 인기있는 물품
          PopularProductsSection(
            searchQuery: _searchQuery,
            onMorePressed: () {
              setState(() {
                _currentIndex = 2; // 중고거래 탭
              });
            },
          ),
          
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

}