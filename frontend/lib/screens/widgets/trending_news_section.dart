import '../news/news_detail_screen.dart';
import 'package:flutter/material.dart';
import '../../models/news.dart';
import '../../services/news_service.dart';

class TrendingNewsSection extends StatelessWidget {
  const TrendingNewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '좋아요 많은 소식',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<News>>(
            stream: NewsService.watchNews(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 140,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return const SizedBox(
                  height: 140,
                  child: Center(child: Text('오류가 발생했습니다')),
                );
              }

              final all = snapshot.data ?? [];
              all.sort((a, b) => b.favoriteUserIds.length.compareTo(a.favoriteUserIds.length));
              final top = all.take(3).toList();

              if (top.isEmpty) {
                return const SizedBox(
                  height: 80,
                  child: Center(child: Text('인기 소식이 없습니다')),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: top.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final n = top[i];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NewsDetailScreen(news: n),
                        ),
                      );
                    },
                    child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.region,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite, size: 16, color: scheme.primary),
                            const SizedBox(width: 4),
                            Text('${n.favoriteUserIds.length}', style: const TextStyle(fontSize: 12)),
                          ],
                        )
                      ],
                    ),
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
}


