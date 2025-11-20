import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String reporterId; // 신고자 UID
  final String reportedUserId; // 신고 대상 사용자 UID
  final String? targetType; // 'product', 'news', 'comment', null (사용자 직접 신고)
  final String? targetId; // 신고 대상 게시물/댓글 ID
  final String reason; // 신고 사유
  final String? description; // 상세 설명
  final Timestamp createdAt;
  final String status; // 'pending', 'reviewed', 'rejected'

  Report({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    this.targetType,
    this.targetId,
    required this.reason,
    this.description,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'description': description,
      'createdAt': createdAt,
      'status': status,
    };
  }

  factory Report.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Report(
      id: doc.id,
      reporterId: data['reporterId'] as String,
      reportedUserId: data['reportedUserId'] as String,
      targetType: data['targetType'] as String?,
      targetId: data['targetId'] as String?,
      reason: data['reason'] as String,
      description: data['description'] as String?,
      createdAt: data['createdAt'] as Timestamp,
      status: data['status'] as String? ?? 'pending',
    );
  }
}



