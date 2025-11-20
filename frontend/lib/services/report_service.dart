import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report.dart';
import 'user_service.dart';

class ReportService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('reports');

  // 신고 제출
  static Future<String> submitReport({
    required String reportedUserId, // 신고 대상 사용자
    String? targetType, // 'product', 'news', 'comment', null
    String? targetId, // 게시물/댓글 ID
    required String reason, // 신고 사유
    String? description, // 상세 설명
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    // 자기 자신은 신고할 수 없음
    if (user.uid == reportedUserId) {
      throw Exception('자기 자신을 신고할 수 없습니다.');
    }

    // 중복 신고 방지 (같은 사용자가 같은 대상을 이미 신고했는지 확인)
    final existingReports = await _col
        .where('reporterId', isEqualTo: user.uid)
        .where('reportedUserId', isEqualTo: reportedUserId)
        .where('targetType', isEqualTo: targetType)
        .where('targetId', isEqualTo: targetId)
        .limit(1)
        .get();

    if (existingReports.docs.isNotEmpty) {
      throw Exception('이미 신고한 대상입니다.');
    }

    // 신고 생성
    final doc = await _col.add({
      'reporterId': user.uid,
      'reportedUserId': reportedUserId,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    // 신고 대상자의 매너점수 감소
    try {
      await UserService.decreaseMannerScoreForReport(reportedUserId);
    } catch (e) {
      print('매너점수 감소 실패: $e');
    }

    return doc.id;
  }

  // 특정 대상에 대한 신고 목록 조회 (관리자용)
  static Future<List<Report>> getReportsByTarget({
    String? targetType,
    String? targetId,
  }) async {
    Query<Map<String, dynamic>> query = _col.orderBy('createdAt', descending: true);

    if (targetType != null) {
      query = query.where('targetType', isEqualTo: targetType);
    }
    if (targetId != null) {
      query = query.where('targetId', isEqualTo: targetId);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Report.fromDoc(doc)).toList();
  }

  // 특정 사용자에 대한 신고 목록 조회 (관리자용)
  static Future<List<Report>> getReportsByReportedUser(String userId) async {
    final snapshot = await _col
        .where('reportedUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Report.fromDoc(doc)).toList();
  }

  // 모든 신고 목록 조회 (관리자용)
  static Stream<List<Report>> watchAllReports() {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Report.fromDoc(doc)).toList());
  }

  // 신고 상태 업데이트 (관리자용)
  static Future<void> updateReportStatus(String reportId, String status) async {
    if (!['pending', 'reviewed', 'rejected'].contains(status)) {
      throw Exception('유효하지 않은 상태값입니다.');
    }

    await _col.doc(reportId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}



