import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chatbot_message.dart';

class ChatbotService {
  static final FirebaseFunctions _functions = 
      FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  /// 챗봇에게 질문하고 검색 결과 받기
  /// 
  /// [query] - 사용자 질문
  /// 
  /// 반환: {
  ///   message: "GPT가 생성한 응답 메시지",
  ///   results: [검색 결과 리스트],
  ///   keywords: [추출된 키워드]
  /// }
  static Future<Map<String, dynamic>> search(String query) async {
    try {
      // 로그인 확인
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 빈 질문 검사
      if (query.trim().isEmpty) {
        throw Exception('검색어를 입력해주세요.');
      }

      // Cloud Function 호출
      final callable = _functions.httpsCallable('chatbotSearch');
      final result = await callable.call<Map<String, dynamic>>({
        'query': query,
      });

      final data = result.data;
      
      // 검색 결과를 SearchResultItem으로 변환
      final List<dynamic> resultsJson = data['results'] ?? [];
      final List<SearchResultItem> searchResults = resultsJson
          .map((json) => SearchResultItem.fromJson(json as Map<String, dynamic>))
          .toList();

      return {
        'message': data['message'] as String? ?? '검색 완료!',
        'results': searchResults,
        'keywords': data['keywords'] as List<dynamic>? ?? [],
      };
    } on FirebaseFunctionsException catch (e) {
      print('Cloud Functions 오류: ${e.code} - ${e.message}');
      
      if (e.code == 'unauthenticated') {
        throw Exception('로그인이 필요합니다.');
      } else if (e.code == 'invalid-argument') {
        throw Exception(e.message ?? '잘못된 입력입니다.');
      } else {
        throw Exception('검색 중 오류가 발생했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      print('챗봇 검색 오류: $e');
      throw Exception('검색 중 오류가 발생했습니다. 다시 시도해주세요.');
    }
  }
}

