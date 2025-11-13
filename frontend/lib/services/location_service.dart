import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;


class LocationService {
  static Future<bool> _ensurePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  static Future<Position> getCurrentPosition() async {
    final ok = await _ensurePermission();
    if (!ok) {
      throw Exception('위치 권한이 필요합니다. 설정에서 권한을 허용해주세요.');
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('기기 위치 서비스가 꺼져 있습니다.');
    }
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  static Future<String> getDongFromCoordinates({required double latitude, required double longitude}) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        throw Exception('주소 정보를 찾을 수 없습니다.');
      }
      final p = placemarks.first;
      final dong = <String?>[
        p.subLocality,             // 동
        p.locality,                // 시/구
        p.subAdministrativeArea,   // 구/군
        p.administrativeArea,      // 도/시
        p.street,                  // 도로명
        p.name,                    // 기타
      ]
          .whereType<String>()
          .map((s) => s.trim())
          .firstWhere((s) => s.isNotEmpty, orElse: () => '');

      if (dong.isEmpty) {
        throw Exception('동 정보 추출에 실패했습니다.');
      }
      return dong.replaceAll(RegExp(r'\s+'), ' ').trim();
    } catch (e) {
      if (kIsWeb) {
        // ✅ 웹 환경에서는 카카오 API로 폴백
        return await _reverseGeocodeWithKakao(latitude, longitude);
      }
      rethrow;
    }
  }

  static Future<String> getCurrentDong() async {
    final pos = await getCurrentPosition();
    return getDongFromCoordinates(latitude: pos.latitude, longitude: pos.longitude);
  }
  static Future<String> _reverseGeocodeWithKakao(double lat, double lng) async {
    final key = dotenv.env['KAKAO_REST_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('KAKAO_REST_KEY가 설정되어 있지 않습니다. .env 파일을 확인해주세요.');
    }

    final uri = Uri.parse(
      'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=$lng&y=$lat',
    );

    final res = await http.get(uri, headers: {'Authorization': 'KakaoAK $key'});

    if (res.statusCode != 200) {
      throw Exception('카카오 주소 조회 실패: HTTP ${res.statusCode}');
    }

    print('응답 코드: ${res.statusCode}');
    print('응답 본문: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final docs = (data['documents'] as List?) ?? const [];
    if (docs.isEmpty) {
      throw Exception('카카오 주소 결과가 비어있습니다.');
    }

    final addr = docs.first['address'] ?? {};
    final dong = addr['region_3depth_name'] ?? '';
    if (dong is String && dong.isNotEmpty) {
      return dong;
    } else {
      throw Exception('카카오 API에서 동 정보를 찾을 수 없습니다.');
    }
  }

}


