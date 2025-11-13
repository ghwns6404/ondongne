import 'package:firebase_auth/firebase_auth.dart';
import 'location_service.dart';
import 'user_service.dart';

class VerificationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 위치로 동(洞) 인증하고 저장
  static Future<String> verifyCurrentDong() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }
    final dong = await LocationService.getCurrentDong();
    await UserService.setVerifiedDong(uid: user.uid, verifiedDong: dong);
    return dong;
  }

  // 테스트나 수동 입력용: 특정 동으로 인증(운영에서는 비활성 권장)
  static Future<void> setDongManually(String dong) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }
    await UserService.setVerifiedDong(uid: user.uid, verifiedDong: dong);
  }
}


