import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 이미지 파일을 Firebase Storage에 업로드하고 다운로드 URL을 반환합니다.
  /// 
  /// [file] - 업로드할 XFile 객체
  /// [folder] - 저장할 폴더 경로 (예: 'products', 'news', 'profile')
  /// 
  /// 반환: 다운로드 URL 문자열
  /// 
  /// 예외: 업로드 실패 시 Exception을 throw합니다.
  static Future<String> uploadImage({
    required XFile file,
    required String folder,
  }) async {
    try {
      // 사용자 인증 확인
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('로그인이 필요합니다. 먼저 로그인해주세요.');
      }

      // 고유한 파일명 생성 (타임스탬프 + 랜덤 문자열)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = file.name.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final uniqueFileName = '${timestamp}_${fileName}';
      final path = '$folder/$uniqueFileName';

      // Storage 참조 생성
      final ref = _storage.ref(path);

      // 파일 확장자로 MIME 타입 결정
      String contentType = 'image/jpeg'; // 기본값
      final extension = fileName.toLowerCase().split('.').last;
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg';
      }

      // 플랫폼별 업로드 처리
      if (kIsWeb) {
        // 웹: putData 사용
        final bytes = await file.readAsBytes();
        await ref.putData(
          bytes,
          SettableMetadata(contentType: contentType),
        );
      } else {
        // 모바일/데스크톱: putFile 사용
        final fileObj = File(file.path);
        await ref.putFile(
          fileObj,
          SettableMetadata(contentType: contentType),
        );
      }

      // 다운로드 URL 가져오기
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      // 에러 메시지 개선
      final errorStr = e.toString().toLowerCase();
      String errorMessage = '이미지 업로드 실패';
      String helpMessage = '';
      
      if (errorStr.contains('unauthorized') || errorStr.contains('403') || errorStr.contains('forbidden')) {
        errorMessage = 'Firebase Storage 권한이 없습니다.';
        helpMessage = '\n\n해결 방법:\n'
            '1. Firebase 콘솔 접속: https://console.firebase.google.com/\n'
            '2. 프로젝트 선택: ondongne-e494a\n'
            '3. Storage → Rules 탭 클릭\n'
            '4. 다음 규칙으로 변경:\n\n'
            'rules_version = \'2\';\n'
            'service firebase.storage {\n'
            '  match /b/{bucket}/o {\n'
            '    match /products/{allPaths=**} {\n'
            '      allow read: if true;\n'
            '      allow write: if request.auth != null;\n'
            '    }\n'
            '  }\n'
            '}\n\n'
            '5. Publish 클릭';
      } else if (errorStr.contains('permission') || errorStr.contains('권한')) {
        errorMessage = 'Firebase Storage 권한이 없습니다.';
        helpMessage = '\n\nFirebase 콘솔에서 Storage 규칙을 확인해주세요.';
      } else if (errorStr.contains('network') || errorStr.contains('네트워크') || errorStr.contains('failed')) {
        errorMessage = '네트워크 연결을 확인하고 다시 시도해주세요.';
      } else if (errorStr.contains('size') || errorStr.contains('크기') || errorStr.contains('too large')) {
        errorMessage = '이미지 파일 크기가 너무 큽니다. 더 작은 이미지를 선택해주세요.';
      } else if (errorStr.contains('cors') || errorStr.contains('preflight')) {
        errorMessage = 'CORS 설정이 필요할 수 있습니다. Firebase Storage가 활성화되어 있는지 확인해주세요.';
      } else if (errorStr.contains('quota') || errorStr.contains('quota exceeded')) {
        errorMessage = 'Firebase Storage 용량이 초과되었습니다. Firebase 콘솔에서 확인해주세요.';
      } else if (errorStr.contains('로그인')) {
        errorMessage = '로그인이 필요합니다. 먼저 로그인해주세요.';
      }
      
      throw Exception('$errorMessage$helpMessage\n\n상세: ${e.toString()}');
    }
  }

  /// 여러 이미지를 순차적으로 업로드하고 URL 리스트를 반환합니다.
  /// 
  /// [files] - 업로드할 XFile 리스트
  /// [folder] - 저장할 폴더 경로
  /// [onProgress] - 업로드 진행 상황 콜백 (선택적)
  /// 
  /// 반환: 다운로드 URL 문자열 리스트
  static Future<List<String>> uploadMultipleImages({
    required List<XFile> files,
    required String folder,
    Function(int current, int total)? onProgress,
  }) async {
    if (files.isEmpty) return [];

    final urls = <String>[];
    final total = files.length;

    for (int i = 0; i < files.length; i++) {
      try {
        // 진행 상황 콜백 호출
        onProgress?.call(i + 1, total);

        final url = await uploadImage(file: files[i], folder: folder);
        urls.add(url);
      } catch (e) {
        // 개별 파일 업로드 실패 시 로그만 남기고 계속 진행
        print('이미지 업로드 실패 (${files[i].name}): $e');
        // 실패한 파일은 건너뛰고 계속 진행
      }
    }

    return urls;
  }

  /// Storage에서 파일을 삭제합니다.
  /// 
  /// [url] - 삭제할 파일의 다운로드 URL
  static Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('이미지 삭제 실패: $e');
      // 삭제 실패해도 예외를 throw하지 않음 (이미 삭제된 경우 등)
    }
  }

  /// 여러 이미지를 삭제합니다.
  /// 
  /// [urls] - 삭제할 파일의 다운로드 URL 리스트
  static Future<void> deleteMultipleImages(List<String> urls) async {
    for (final url in urls) {
      await deleteImage(url);
    }
  }
}

