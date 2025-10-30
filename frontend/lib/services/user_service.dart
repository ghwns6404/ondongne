import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';

class UserService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users');

  // 사용자 정보 저장/업데이트
  static Future<void> saveUser({
    required String uid,
    required String email,
    required String name,
    bool isAdmin = false,
  }) async {
    await _col.doc(uid).set({
      'email': email,
      'name': name,
      'isAdmin': isAdmin,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 특정 사용자 정보 가져오기
  static Future<UserModel?> getUser(String uid) async {
    final doc = await _col.doc(uid).get();
    if (doc.exists) {
      return UserModel.fromDoc(doc);
    }
    return null;
  }

  // 현재 사용자 정보 가져오기
  static Future<UserModel?> getCurrentUserModel() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _col.doc(user.uid).get();
    if (doc.exists) {
      return UserModel.fromDoc(doc);
    }
    return null;
  }

  // Admin 권한 확인 (이메일 안전장치 포함)
  static Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final docRef = _col.doc(user.uid);
    final doc = await docRef.get();
    final data = doc.data();

    // 이메일이 admin@gmail.com이면 무조건 관리자 취급 + 문서에 반영
    if (user.email?.toLowerCase() == 'admin@gmail.com') {
      if (data == null || data['isAdmin'] != true) {
        await docRef.set({'isAdmin': true, 'email': user.email}, SetOptions(merge: true));
      }
      return true;
    }

    return data?['isAdmin'] == true;
  }

  // Admin 권한 확인 (Stream)
  static Stream<bool> watchIsAdmin() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _col.doc(user.uid).snapshots().map((doc) {
      final data = doc.data();
      // 실시간에서도 이메일 안전장치 적용
      if (user.email?.toLowerCase() == 'admin@gmail.com') return true;
      return data?['isAdmin'] == true;
    });
  }

  // 특정 사용자 Admin 권한 설정
  static Future<void> setAdmin(String uid, bool isAdmin) async {
    await _col.doc(uid).update({'isAdmin': isAdmin});
  }
}
