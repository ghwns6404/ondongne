import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// 카카오 장소 검색 결과
class KakaoPlace {
  final String placeName;
  final String addressName;
  final double x; // 경도
  final double y; // 위도
  final String? phone;
  final String? categoryName;

  KakaoPlace({
    required this.placeName,
    required this.addressName,
    required this.x,
    required this.y,
    this.phone,
    this.categoryName,
  });

  factory KakaoPlace.fromJson(Map<String, dynamic> json) {
    return KakaoPlace(
      placeName: json['place_name'] as String,
      addressName: json['address_name'] as String,
      x: double.parse(json['x'] as String),
      y: double.parse(json['y'] as String),
      phone: json['phone'] as String?,
      categoryName: json['category_name'] as String?,
    );
  }

  String get fullAddress => '$addressName ($placeName)';
}

class KakaoMapService {
  static String? get _apiKey => dotenv.env['KAKAO_REST_KEY'];

  /// 장소 검색 (키워드)
  static Future<List<KakaoPlace>> searchPlaces(String query) async {
    final key = _apiKey;
    if (key == null || key.isEmpty) {
      throw Exception('KAKAO_REST_KEY가 설정되어 있지 않습니다.');
    }

    final uri = Uri.parse(
      'https://dapi.kakao.com/v2/local/search/keyword.json?query=$query',
    );

    final res = await http.get(uri, headers: {'Authorization': 'KakaoAK $key'});

    if (res.statusCode != 200) {
      throw Exception('카카오 장소 검색 실패: HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final documents = (data['documents'] as List?) ?? [];

    return documents
        .map((doc) => KakaoPlace.fromJson(doc as Map<String, dynamic>))
        .toList();
  }

  /// 좌표로 주소 검색 (역지오코딩)
  static Future<String> coordToAddress(double lat, double lng) async {
    final key = _apiKey;
    if (key == null || key.isEmpty) {
      throw Exception('KAKAO_REST_KEY가 설정되어 있지 않습니다.');
    }

    final uri = Uri.parse(
      'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=$lng&y=$lat',
    );

    final res = await http.get(uri, headers: {'Authorization': 'KakaoAK $key'});

    if (res.statusCode != 200) {
      throw Exception('카카오 주소 조회 실패: HTTP ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final documents = (data['documents'] as List?) ?? [];

    if (documents.isEmpty) {
      throw Exception('주소를 찾을 수 없습니다.');
    }

    final address = documents.first['address'] ?? {};
    return address['address_name'] as String? ?? '주소 없음';
  }

  /// 카카오맵 URL 생성 (앱에서 카카오맵 열기)
  static String getKakaoMapUrl({
    required double lat,
    required double lng,
    required String placeName,
  }) {
    // 카카오맵 모바일 웹 URL
    return 'https://map.kakao.com/link/map/$placeName,$lat,$lng';
  }

  /// 길찾기 URL 생성
  static String getKakaoNaviUrl({
    required double lat,
    required double lng,
    required String placeName,
  }) {
    // 카카오내비 URL
    return 'https://map.kakao.com/link/to/$placeName,$lat,$lng';
  }
}

