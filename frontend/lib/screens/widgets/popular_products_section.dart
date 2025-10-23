import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';

class PopularProductsSection extends StatelessWidget {
  const PopularProductsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 제목
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '인기있는 물품',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B35),
                ),
              ),
              TextButton(
                onPressed: () {
                  // 더보기 기능 (미구현)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('더 많은 상품을 곧 만나보세요!')),
                  );
                },
                child: const Text(
                  '더보기',
                  style: TextStyle(
                    color: Color(0xFFFF6B35),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 실제 상품 데이터 (하트 개수 기준 정렬)
          StreamBuilder<List<Product>>(
            stream: ProductService.watchProducts(),
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
              
              final products = snapshot.data ?? [];
              
              // 하트 개수 기준으로 정렬하고 상위 6개만 선택
              final popularProducts = products
                ..sort((a, b) => b.favoriteUserIds.length.compareTo(a.favoriteUserIds.length))
                ..take(6);
              
              if (popularProducts.isEmpty) {
                return const SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      '등록된 상품이 없습니다',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              
              return SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: popularProducts.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(popularProducts[index]);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
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
          // 상품 이미지
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: product.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        product.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.shopping_bag, size: 40, color: Colors.grey);
                        },
                      ),
                    )
                  : const Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
            ),
          ),
          
          // 상품 정보
          Container(
            height: 50,
            width: double.infinity,
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${product.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 12, color: Colors.red),
                        const SizedBox(width: 2),
                        Text(
                          '${product.favoriteUserIds.length}',
                          style: const TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
