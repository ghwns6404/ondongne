import 'package:flutter/material.dart';
import '../../models/admin_news.dart';
import '../../services/admin_news_service.dart';
import '../news/admin_news_detail_screen.dart';

class AdminNewsSection extends StatelessWidget {
  final String? searchQuery; // 옵션: 검색어
  final VoidCallback? onMorePressed; // 더보기 액션
  const AdminNewsSection({super.key, this.searchQuery, this.onMorePressed});

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
              Row(
                children: [
                  Icon(Icons.campaign, color: tossPrimary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '우리동네 공지사항',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: tossPrimary,
                    ),
                  ),
                ],
              ),
              if (onMorePressed != null)
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

          // 공지사항 데이터
          StreamBuilder<List<AdminNews>>(
            stream: AdminNewsService.watchAdminNews(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: Text('오류가 발생했습니다')),
                );
              }

              final adminNewsList = snapshot.data ?? [];

              // 검색어 필터
              final q = (searchQuery ?? '').trim().toLowerCase();
              final filteredAdmin = q.isEmpty
                  ? adminNewsList
                  : adminNewsList.where((n) {
                      final title = n.title.toLowerCase();
                      final content = n.content.toLowerCase();
                      return title.contains(q) || content.contains(q);
                    }).toList();

              if (filteredAdmin.isEmpty) {
                return const SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      '등록된 공지사항이 없습니다',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredAdmin.take(5).length,
                  itemBuilder: (context, index) {
                    final adminNews = filteredAdmin[index];
                    return _buildAdminNewsCard(context, adminNews, tossPrimary);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Admin 공지사항 카드
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
          border: Border.all(color: tossPrimary.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: tossPrimary.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3),
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
                            return Icon(Icons.campaign, size: 50, color: tossPrimary);
                          },
                        ),
                      )
                    : Icon(Icons.campaign, size: 50, color: tossPrimary),
              ),
            ),
            Container(
              height: 50,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                border: Border(
                  top: BorderSide(color: tossPrimary.withOpacity(0.3)),
                ),
              ),
              child: Center(
                child: Text(
                  adminNews.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
}

