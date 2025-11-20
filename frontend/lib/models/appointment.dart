import 'package:cloud_firestore/cloud_firestore.dart';

/// 약속 모델
class Appointment {
  final String id;
  final String chatRoomId;     // 어느 채팅방의 약속인지
  final String proposerId;     // 제안한 사람
  final String receiverId;     // 받는 사람
  final Timestamp dateTime;    // 약속 날짜+시간
  final String location;       // 장소 텍스트 (예: "대전 동구 중앙로역 2번 출구")
  final GeoPoint? coordinates; // 위도/경도 (선택)
  final String? memo;          // 메모 (예: "2번 출구 앞 스타벅스에서 만나요")
  final String status;         // 'pending', 'accepted', 'rejected', 'cancelled', 'completed'
  final Timestamp createdAt;
  final Timestamp? respondedAt; // 수락/거절한 시간

  Appointment({
    required this.id,
    required this.chatRoomId,
    required this.proposerId,
    required this.receiverId,
    required this.dateTime,
    required this.location,
    this.coordinates,
    this.memo,
    this.status = 'pending',
    required this.createdAt,
    this.respondedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatRoomId': chatRoomId,
      'proposerId': proposerId,
      'receiverId': receiverId,
      'dateTime': dateTime,
      'location': location,
      'coordinates': coordinates,
      'memo': memo,
      'status': status,
      'createdAt': createdAt,
      'respondedAt': respondedAt,
    };
  }

  factory Appointment.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      chatRoomId: data['chatRoomId'] as String,
      proposerId: data['proposerId'] as String,
      receiverId: data['receiverId'] as String,
      dateTime: data['dateTime'] as Timestamp,
      location: data['location'] as String,
      coordinates: data['coordinates'] as GeoPoint?,
      memo: data['memo'] as String?,
      status: data['status'] as String? ?? 'pending',
      createdAt: data['createdAt'] as Timestamp,
      respondedAt: data['respondedAt'] as Timestamp?,
    );
  }

  /// 약속이 확정되었는지
  bool get isAccepted => status == 'accepted';

  /// 약속이 거절되었는지
  bool get isRejected => status == 'rejected';

  /// 약속이 대기 중인지
  bool get isPending => status == 'pending';

  /// 약속이 취소되었는지
  bool get isCancelled => status == 'cancelled';

  /// 약속이 완료되었는지
  bool get isCompleted => status == 'completed';
}

