import 'package:flutter/material.dart';

class RegionFilter extends StatefulWidget {
  final String selectedRegion;
  final Function(String) onRegionChanged;

  const RegionFilter({
    super.key,
    required this.selectedRegion,
    required this.onRegionChanged,
  });

  @override
  State<RegionFilter> createState() => _RegionFilterState();
}

class _RegionFilterState extends State<RegionFilter> {
  final List<String> _regions = [
    '대전 전체',
    '대전 유성구',
    '대전 서구',
    '대전 중구',
    '대전 동구',
    '대전 대덕구',
  ];

  @override
  Widget build(BuildContext context) {
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
              value: widget.selectedRegion,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
              items: _regions.map((String region) {
                return DropdownMenuItem<String>(
                  value: region,
                  child: Text(region),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  widget.onRegionChanged(newValue);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

