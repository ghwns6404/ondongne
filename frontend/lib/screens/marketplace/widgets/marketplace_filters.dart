import 'package:flutter/material.dart';

class MarketplaceFilters extends StatelessWidget {
  final String selectedRegion;
  final int? minPrice;
  final int? maxPrice;
  final bool showFavoritesOnly;
  final Function(String) onRegionChanged;
  final Function(int?, int?) onPriceChanged;
  final Function(bool) onFavoritesChanged;

  const MarketplaceFilters({
    super.key,
    required this.selectedRegion,
    required this.minPrice,
    required this.maxPrice,
    required this.showFavoritesOnly,
    required this.onRegionChanged,
    required this.onPriceChanged,
    required this.onFavoritesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 지역 필터
          _buildRegionFilter(),
          const SizedBox(height: 16),
          
          // 가격 필터
          _buildPriceFilter(),
          const SizedBox(height: 16),
          
          // 즐겨찾기 토글
          _buildFavoritesToggle(),
        ],
      ),
    );
  }

  Widget _buildRegionFilter() {
    final regions = [
      '대전 전체',
      '대전 동구',
      '대전 중구',
      '대전 서구',
      '대전 대덕구',
      '대전 유성구',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '지역',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedRegion,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              style: const TextStyle(color: Colors.black, fontSize: 16),
              items: regions.map((String region) {
                return DropdownMenuItem<String>(
                  value: region,
                  child: Text(region),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  onRegionChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '가격',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // 최소 가격
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '최소가격',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFFF6B35)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (value) {
                  final min = int.tryParse(value);
                  onPriceChanged(min, maxPrice);
                },
              ),
            ),
            
            const SizedBox(width: 8),
            
            const Text('~', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
            
            const SizedBox(width: 8),
            
            // 최대 가격
            Expanded(
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '최대가격',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFFF6B35)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onChanged: (value) {
                  final max = int.tryParse(value);
                  onPriceChanged(minPrice, max);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFavoritesToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '내 즐겨찾기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B35),
          ),
        ),
        Switch(
          value: showFavoritesOnly,
          onChanged: onFavoritesChanged,
          activeColor: const Color(0xFFFF6B35),
          activeTrackColor: const Color(0xFFFF6B35).withOpacity(0.3),
          inactiveThumbColor: Colors.grey[300],
          inactiveTrackColor: Colors.grey[200],
        ),
      ],
    );
  }
}
