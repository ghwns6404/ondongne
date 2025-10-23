import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/admin_news.dart';
import '../../services/admin_news_service.dart';
import '../../services/user_service.dart';
import 'admin_news_form_screen.dart';
import 'widgets/comment_section.dart';

class AdminNewsDetailScreen extends StatelessWidget {
  final AdminNews adminNews;

  const AdminNewsDetailScreen({
    super.key,
    required this.adminNews,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('뉴스&이벤트 상세'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 상단 내용
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    adminNews.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 지역
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      adminNews.region,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 이미지 (있는 경우)
                  if (adminNews.imageUrls.isNotEmpty)
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFFF6B35).withOpacity(0.1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          adminNews.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.campaign, size: 50, color: Color(0xFFFF6B35)),
                            );
                          },
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // 내용
                  Text(
                    adminNews.content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 하단 정보
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFF6B35).withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        // 좋아요 버튼
                        GestureDetector(
                          onTap: () => _toggleFavorite(context),
                          child: Row(
                            children: [
                              Icon(
                                adminNews.favoriteUserIds.contains(FirebaseAuth.instance.currentUser?.uid)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                                color: adminNews.favoriteUserIds.contains(FirebaseAuth.instance.currentUser?.uid)
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${adminNews.favoriteUserIds.length}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(adminNews.createdAt),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 관리자 전용 액션 버튼
                  _buildActionButtons(context),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // 댓글 섹션
          Container(
            height: 400,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: CommentSection(
              postId: adminNews.id,
              postType: 'adminNews',
            ),
          ),
        ],
      ),
    );
  }

  // 관리자 전용 액션 버튼
  Widget _buildActionButtons(BuildContext context) {
    return StreamBuilder<bool>(
      stream: UserService.watchIsAdmin(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? false;
        
        if (!isAdmin) {
          return const SizedBox.shrink();
        }
        
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _editAdminNews(context),
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text('수정', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _deleteAdminNews(context),
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text('삭제', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 좋아요 토글
  Future<void> _toggleFavorite(BuildContext context) async {
    try {
      await AdminNewsService.toggleFavorite(adminNews.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('좋아요 처리 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  // 수정
  void _editAdminNews(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminNewsFormScreen(
          adminNewsToEdit: adminNews,
        ),
      ),
    );
  }

  // 삭제
  Future<void> _deleteAdminNews(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('정말로 이 뉴스&이벤트를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminNewsService.deleteAdminNews(adminNews.id);
        if (context.mounted) {
          Navigator.of(context).pop(); // 상세보기 화면 닫기
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('뉴스&이벤트가 삭제되었습니다')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
          );
        }
      }
    }
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
