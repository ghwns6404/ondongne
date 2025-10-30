import 'package:flutter/material.dart';
import '../../models/news.dart';
import '../../models/admin_news.dart';
import '../../services/news_service.dart';
import '../../services/admin_news_service.dart';
import '../news/news_detail_screen.dart';
import '../news/admin_news_detail_screen.dart';

class NewsSection extends StatelessWidget {
  final String? searchQuery; // 옵션: 검색어
  final VoidCallback? onMorePressed; // 더보기 액션
  const NewsSection({super.key, this.searchQuery, this.onMorePressed});

  @override
  Widget build(BuildContext context) {
    final tossPrimary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '우리동네 소식',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: tossPrimary,
                ),
              ),
              TextButton(
                onPressed: onMorePressed,
                child: Text(
                  '더보기',
                  style: TextStyle(
                    color: tossPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 실제 뉴스 데이터 (일반 소식 + 뉴스&이벤트)
          StreamBuilder<List<News>>(
            stream: NewsService.watchNews(),
            builder: (context, newsSnapshot) {
              return StreamBuilder<List<AdminNews>>(
                stream: AdminNewsService.watchAdminNews(),
                builder: (context, adminNewsSnapshot) {
                  if (newsSnapshot.connectionState == ConnectionState.waiting ||
                      adminNewsSnapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (newsSnapshot.hasError || adminNewsSnapshot.hasError) {
                    return const SizedBox(
                      height: 180,
                      child: Center(child: Text('오류가 발생했습니다')),
                    );
                  }

                  final newsList = newsSnapshot.data ?? [];
                  final adminNewsList = adminNewsSnapshot.data ?? [];

                  // 검색어 필터 (제목/내용에 포함 여부, 대소문자 무시)
                  final q = (searchQuery ?? '').trim().toLowerCase();
                  final filteredAdmin = q.isEmpty
                      ? adminNewsList
                      : adminNewsList.where((n) {
                          final title = n.title.toLowerCase();
                          return title.contains(q);
                        }).toList();
                  final filteredNews = q.isEmpty
                      ? newsList
                      : newsList.where((n) {
                          final title = n.title.toLowerCase();
                          final content = n.content.toLowerCase();
                          return title.contains(q) || content.contains(q);
                        }).toList();

                  if (newsList.isEmpty && adminNewsList.isEmpty) {
                    return const SizedBox(
                      height: 180,
                      child: Center(
                        child: Text(
                          '등록된 소식이 없습니다',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  // 뉴스&이벤트를 먼저, 그 다음 일반 소식
                  final allNews = <Widget>[];

                  // 뉴스&이벤트 카드들
                  for (final adminNews in filteredAdmin.take(3)) {
                    allNews.add(_buildAdminNewsCard(context, adminNews, tossPrimary));
                  }

                  // 일반 소식 카드들
                  for (final news in filteredNews.take(5)) {
                    allNews.add(_buildNewsCard(context, news));
                  }

                  return SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: allNews.length,
                      itemBuilder: (context, index) {
                        return allNews[index];
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Admin 뉴스&이벤트 카드
  Widget _buildAdminNewsCard(BuildContext context, AdminNews adminNews, Color tossPrimary) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AdminNewsDetailScreen(adminNews: adminNews),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: tossPrimary.withOpacity(0.1),
          border: Border.all(color: tossPrimary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: tossPrimary.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: adminNews.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          adminNews.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.campaign, size: 40, color: tossPrimary);
                          },
                        ),
                      )
                    : Icon(Icons.campaign, size: 40, color: tossPrimary),
              ),
            ),
            Container(
              height: 50,
              width: double.infinity,
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Center(
                child: Text(
                  adminNews.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: tossPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, News news) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NewsDetailScreen(news: news),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: news.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          news.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.article, size: 40, color: Colors.grey);
                          },
                        ),
                      )
                    : const Icon(Icons.article, size: 40, color: Colors.grey),
              ),
            ),
            Container(
              height: 50,
              width: double.infinity,
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Center(
                child: Text(
                  news.title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
