import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfanityFilterService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// 텍스트에 욕설/비속어가 포함되어 있는지 검사합니다.
  /// 
  /// [text] - 검사할 텍스트
  /// 
  /// 반환: {isClean: true} 또는 {isClean: false, reason: "이유"}
  /// 
  /// 예외: 
  /// - 로그인하지 않은 경우
  /// - API 호출 실패
  static Future<Map<String, dynamic>> checkProfanity(String text) async {
    try {
      // 로그인 확인
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 빈 텍스트 검사
      if (text.trim().isEmpty) {
        return {'isClean': true};
      }

      // Cloud Function 호출
      final callable = _functions.httpsCallable('checkProfanity');
      final result = await callable.call<Map<String, dynamic>>({
        'text': text,
      });

      return result.data;
    } on FirebaseFunctionsException catch (e) {
      print('Cloud Functions 오류: ${e.code} - ${e.message}');
      
      // 오류 처리
      if (e.code == 'unauthenticated') {
        throw Exception('로그인이 필요합니다.');
      } else if (e.code == 'invalid-argument') {
        throw Exception(e.message ?? '잘못된 입력입니다.');
      } else {
        // 기타 오류 시 통과 처리 (서비스 중단 방지)
        print('욕설 필터링 API 오류로 인해 통과 처리합니다.');
        return {'isClean': true};
      }
    } catch (e) {
      print('욕설 필터링 오류: $e');
      // 오류 시 통과 처리 (서비스 중단 방지)
      return {'isClean': true};
    }
  }

  /// 여러 텍스트를 한 번에 검사합니다.
  /// 
  /// [texts] - 검사할 텍스트 리스트
  /// 
  /// 반환: 모든 텍스트가 깨끗하면 true, 하나라도 욕설이 있으면 false
  static Future<Map<String, dynamic>> checkMultipleTexts(
      List<String> texts) async {
    // 모든 텍스트를 하나로 합쳐서 검사
    final combinedText = texts.join(' ');
    return await checkProfanity(combinedText);
  }

  /// 텍스트 검사 후 예외를 throw합니다.
  /// 
  /// 댓글/게시물 작성 시 사용하기 편리합니다.
  /// 
  /// [text] - 검사할 텍스트
  /// 
  /// 예외: 욕설이 감지되면 Exception을 throw
  static Future<void> validateText(String text) async {
    final result = await checkProfanity(text);
    
    if (result['isClean'] != true) {
      final reason = result['reason'] ?? '부적절한 표현이 감지되었습니다.';
      throw Exception('게시할 수 없습니다.\n$reason');
    }
  }

  /// 여러 텍스트를 검사 후 예외를 throw합니다.
  /// 
  /// [texts] - 검사할 텍스트 리스트
  /// 
  /// 예외: 욕설이 감지되면 Exception을 throw
  static Future<void> validateMultipleTexts(List<String> texts) async {
    final result = await checkMultipleTexts(texts);
    
    if (result['isClean'] != true) {
      final reason = result['reason'] ?? '부적절한 표현이 감지되었습니다.';
      throw Exception('게시할 수 없습니다.\n$reason');
    }
  }
}

