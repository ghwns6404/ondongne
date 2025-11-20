import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image_picker/image_picker.dart';

/// AI 상품 분석 결과
class AIProductAnalysis {
  final String title;
  final String description;
  final String category;
  final int priceMin;
  final int priceMax;
  final String priceReason;

  AIProductAnalysis({
    required this.title,
    required this.description,
    required this.category,
    required this.priceMin,
    required this.priceMax,
    required this.priceReason,
  });

  factory AIProductAnalysis.fromJson(Map<String, dynamic> json) {
    return AIProductAnalysis(
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      priceMin: (json['priceMin'] as num).toInt(),
      priceMax: (json['priceMax'] as num).toInt(),
      priceReason: json['priceReason'] as String,
    );
  }

  /// 추천 가격 (평균값)
  int get suggestedPrice => ((priceMin + priceMax) / 2).round();

  /// 가격 범위 텍스트
  String get priceRangeText {
    if (priceMin == 0 && priceMax == 0) {
      return '가격 추천 불가';
    }
    return '${_formatPrice(priceMin)} ~ ${_formatPrice(priceMax)}원';
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

class AIProductService {
  static final _functions = FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  /// 이미지를 분석하여 상품 정보 자동 생성
  static Future<AIProductAnalysis> analyzeProductImage(XFile imageFile) async {
    try {
      // 이미지를 base64로 인코딩
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Firebase Function 호출
      final callable = _functions.httpsCallable('analyzeProductImage');
      final result = await callable.call({
        'imageBase64': base64Image,
      });

      // 응답 파싱
      final data = result.data;
      
      if (data['success'] != true) {
        throw Exception('AI 분석 실패');
      }

      return AIProductAnalysis.fromJson(data['data']);
    } catch (e) {
      print('AI 상품 분석 오류: $e');
      rethrow;
    }
  }
}

