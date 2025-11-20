import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../services/report_service.dart';
import '../chat/chat_detail_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;

  Widget _buildImageCarousel(List<String> imageUrls) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: imageUrls.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return Image.network(
              imageUrls[index],
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 300,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image, size: 64, color: Colors.grey),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 300,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            );
          },
        ),
        // 이미지 인디케이터
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              imageUrls.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                  border: Border.all(
                    color: Colors.black26,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isFavorited =
        currentUser != null && product.favoriteUserIds.contains(currentUser.uid);
    // 오너 여부는 명확하게 현재 사용자 UID와 판매자 UID를 비교하여 결정
    final bool isOwner =
        currentUser != null && product.sellerId == currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
        title: Text('상품 상세', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
        actions: [
          IconButton(
            onPressed: () {
              ProductService.toggleFavorite(product.id);
            },
            icon: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: isFavorited ? Colors.red : Theme.of(context).colorScheme.primary,
            ),
          ),
          if (!isOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'report') {
                  _showReportDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.report, color: Colors.red),
                      SizedBox(width: 8),
                      Text('신고하기'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지
            if (product.imageUrls.isNotEmpty)
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  maxHeight: 400,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                ),
                child: product.imageUrls.length > 1
                    ? _buildImageCarousel(product.imageUrls)
                    : Image.network(
                        product.imageUrls.first,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 300,
                            alignment: Alignment.center,
                            child: const Icon(Icons.image, size: 64, color: Colors.grey),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 300,
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      ),
              )
            else
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                ),
                child: const Icon(Icons.image, size: 64, color: Colors.grey),
              ),
            
            // 상품 정보
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 카테고리
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '${product.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(product.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(product.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 작성자(판매자) 정보 (가입 이름)
                  FutureBuilder(
                    future: UserService.getUser(product.sellerId),
                    builder: (context, snapshot) {
                      final name = snapshot.data?.name ?? '판매자';
                      return Row(
                        children: [
                          const Icon(Icons.person, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // 지역 정보
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        product.region,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 상품 설명
                  const Text(
                    '상품 설명',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 등록일
                  Text(
                    '등록일: ${_formatDate(product.createdAt)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  // 판매자 전용: 상태 변경
                  if (isOwner) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      '거래 상태 변경',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: product.status,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(
                              value: 'available',
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  SizedBox(width: 8),
                                  Text('판매중'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'reserved',
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, color: Colors.orange, size: 20),
                                  SizedBox(width: 8),
                                  Text('예약중'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'sold',
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.grey, size: 20),
                                  SizedBox(width: 8),
                                  Text('거래완료'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (String? newStatus) {
                            if (newStatus != null && newStatus != product.status) {
                              _changeStatus(newStatus);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isOwner
          ? Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // 수정 기능 (추후 구현)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('수정 기능은 곧 추가됩니다')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('수정'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _showDeleteDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('삭제'),
                    ),
                  ),
                ],
              ),
            )
          : Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('채팅을 시작하려면 로그인이 필요합니다.')),
                      );
                      return;
                    }
                    if (isOwner) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('자신과는 채팅할 수 없습니다.')),
                      );
                      return;
                    }
                    
                    // 채팅방 생성 또는 가져오기
                    final chatRoomId = await ChatService.getOrCreateChatRoom(product.sellerId);
                    final seller = await UserService.getUser(product.sellerId);
                    final sellerName = seller?.name ?? '판매자';

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            chatRoomId: chatRoomId,
                            otherUserName: sellerName,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('판매자와 채팅하기'),
                ),
              ),
            ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'available':
        return '판매중';
      case 'reserved':
        return '예약중';
      case 'sold':
        return '거래완료';
      default:
        return '판매중';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'reserved':
        return Colors.orange;
      case 'sold':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  void _changeStatus(String newStatus) async {
    try {
      await ProductService.updateProductStatus(widget.product.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('거래 상태가 ${_getStatusText(newStatus)}(으)로 변경되었습니다')),
        );
        // 화면 새로고침
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('상태 변경 실패: $e')),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('상품 삭제'),
        content: const Text('정말로 이 상품을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ProductService.deleteProduct(widget.product.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('상품이 삭제되었습니다')),
                );
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    String? selectedReason;
    final TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('상품 신고하기'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('신고 사유를 선택해주세요', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setState) => Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('사기/허위매물'),
                      value: '사기/허위매물',
                      groupValue: selectedReason,
                      onChanged: (value) => setState(() => selectedReason = value),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      title: const Text('욕설/비방'),
                      value: '욕설/비방',
                      groupValue: selectedReason,
                      onChanged: (value) => setState(() => selectedReason = value),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      title: const Text('음란/선정적'),
                      value: '음란/선정적',
                      groupValue: selectedReason,
                      onChanged: (value) => setState(() => selectedReason = value),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    RadioListTile<String>(
                      title: const Text('기타'),
                      value: '기타',
                      groupValue: selectedReason,
                      onChanged: (value) => setState(() => selectedReason = value),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: '상세 설명 (선택)',
                  border: OutlineInputBorder(),
                  hintText: '신고 내용을 자세히 적어주세요',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              if (selectedReason == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('신고 사유를 선택해주세요')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                await ReportService.submitReport(
                  reportedUserId: widget.product.sellerId,
                  targetType: 'product',
                  targetId: widget.product.id,
                  reason: selectedReason!,
                  description: descController.text.trim().isEmpty 
                      ? null 
                      : descController.text.trim(),
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('신고가 접수되었습니다')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('신고 실패: $e')),
                  );
                }
              }
            },
            child: const Text('신고', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
