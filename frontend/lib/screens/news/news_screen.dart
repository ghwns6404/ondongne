import 'package:flutter/material.dart';
import '../../models/news.dart';
import '../../models/admin_news.dart';
import '../../services/news_service.dart';
import '../../services/admin_news_service.dart';
import '../../services/user_service.dart';
import 'news_form_screen.dart';
import 'admin_news_form_screen.dart';
import 'news_detail_screen.dart';
import 'admin_news_detail_screen.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('소식'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 상단: 뉴스&이벤트 섹션
          _buildAdminNewsSection(context),
          
          // 하단: 일반 소식 섹션
          Expanded(
            child: _buildGeneralNewsSection(context),
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: UserService.watchIsAdmin(),
        builder: (context, snapshot) {
          final isAdmin = snapshot.data ?? false;
          final blue = Theme.of(context).colorScheme.primary;
          final gray = Colors.grey[200];
          if (isAdmin) {
            return Stack(
              children: [
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AdminNewsFormScreen()),
                      );
                    },
                    backgroundColor: blue,
                    heroTag: "admin_news",
                    child: const Icon(Icons.campaign, color: Colors.white),
                  ),
                ),
                Positioned(
                  bottom: 80,
                  right: 0,
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const NewsFormScreen()),
                      );
                    },
                    backgroundColor: gray,
                    heroTag: "general_news",
                    child: const Icon(Icons.edit, color: Colors.black),
                  ),
                ),
              ],
            );
          } else {
            return FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const NewsFormScreen()),
                );
              },
              backgroundColor: blue,
              child: const Icon(Icons.edit, color: Colors.white),
            );
          }
        },
      ),
    );
  }

  // 상단: 뉴스&이벤트 섹션
  Widget _buildAdminNewsSection(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '지역 뉴스&이벤트',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<AdminNews>>(
              stream: AdminNewsService.watchAdminNews(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('오류가 발생했습니다'));
                }
                final adminNewsList = snapshot.data ?? [];
                if (adminNewsList.isEmpty) {
                  return Center(
                    child: Text(
                      '등록된 뉴스&이벤트가 없습니다',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: adminNewsList.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AdminNewsDetailScreen(
                              adminNews: adminNewsList[index],
                            ),
                          ),
                        );
                      },
                      child: _buildAdminNewsCard(adminNewsList[index], primary),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 하단: 일반 소식 섹션
  Widget _buildGeneralNewsSection(BuildContext context) {
    return StreamBuilder<List<News>>(
      stream: NewsService.watchNews(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
        }
        
        final newsList = snapshot.data ?? [];
        
        if (newsList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.newspaper, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '등록된 소식이 없습니다',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: newsList.length,
          itemBuilder: (context, index) {
            final news = newsList[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NewsDetailScreen(news: news),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      Text(
                        news.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // 지역
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          news.region,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // 내용
                      Text(
                        news.content,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // 하단 정보
                      Row(
                        children: [
                          const Icon(Icons.favorite, size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            '${news.favoriteUserIds.length}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const Spacer(),
                          Text(
                            _formatDate(news.createdAt),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 뉴스&이벤트 카드
  Widget _buildAdminNewsCard(AdminNews adminNews, Color primary) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: primary.withOpacity(0.1),
        border: Border.all(color: primary.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              adminNews.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // 지역
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                adminNews.region,
                style: TextStyle(
                  fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.favorite, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                Text(
                  '${adminNews.favoriteUserIds.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  _formatDate(adminNews.createdAt),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}