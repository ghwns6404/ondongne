import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import 'widgets/marketplace_filters.dart';
import 'widgets/product_card.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

class MarketplaceTab extends StatefulWidget {
  const MarketplaceTab({super.key});

  @override
  State<MarketplaceTab> createState() => _MarketplaceTabState();
}

class _MarketplaceTabState extends State<MarketplaceTab> {
  String _selectedRegion = '대전 전체';
  int? _minPrice;
  int? _maxPrice;
  bool _showFavoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 필터 섹션
          MarketplaceFilters(
            selectedRegion: _selectedRegion,
            minPrice: _minPrice,
            maxPrice: _maxPrice,
            showFavoritesOnly: _showFavoritesOnly,
            onRegionChanged: (region) => setState(() => _selectedRegion = region),
            onPriceChanged: (min, max) => setState(() {
              _minPrice = min;
              _maxPrice = max;
            }),
            onFavoritesChanged: (value) => setState(() => _showFavoritesOnly = value),
          ),
          
          // 상품 목록
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: ProductService.watchProducts(
                region: _selectedRegion,
                minPrice: _minPrice,
                maxPrice: _maxPrice,
                onlyFavorites: _showFavoritesOnly,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('오류: ${snapshot.error}'));
                }
                
                final products = snapshot.data ?? [];
                
                if (products.isEmpty) {
                  return const Center(
                    child: Text(
                      '등록된 상품이 없습니다',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(product: product),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductFormScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFFFF6B35),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
