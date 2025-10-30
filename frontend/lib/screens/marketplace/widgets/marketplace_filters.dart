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
    final tossPrimary = Theme.of(context).colorScheme.primary;
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
          _buildRegionFilter(tossPrimary),
          const SizedBox(height: 16),
          _buildPriceFilter(tossPrimary),
          const SizedBox(height: 16),
          _buildFavoritesToggle(tossPrimary),
        ],
      ),
    );
  }

  Widget _buildRegionFilter(Color tossPrimary) {
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
        Text(
          '지역',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: tossPrimary,
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

  Widget _buildPriceFilter(Color tossPrimary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '가격',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: tossPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
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
                    borderSide: BorderSide(color: tossPrimary),
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
                    borderSide: BorderSide(color: tossPrimary),
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

  Widget _buildFavoritesToggle(Color tossPrimary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '내 즐겨찾기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: tossPrimary,
          ),
        ),
        Switch(
          value: showFavoritesOnly,
          onChanged: onFavoritesChanged,
          activeThumbColor: tossPrimary,
          activeTrackColor: tossPrimary.withOpacity(0.3),
          inactiveThumbColor: Colors.grey[300],
          inactiveTrackColor: Colors.grey[200],
        ),
      ],
    );
  }
}
