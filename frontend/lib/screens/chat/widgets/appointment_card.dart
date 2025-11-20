import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import '../../../models/appointment.dart';
import '../../../services/appointment_service.dart';
import '../appointment_map_screen.dart';
import '../appointment_map_screen_web.dart';

/// 채팅에 표시되는 약속 카드
class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool isMe; // 내가 제안한 약속인지

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.isMe,
  });

  String _getStatusEmoji() {
    if (appointment.isAccepted) return '✅';
    if (appointment.isRejected) return '❌';
    if (appointment.isCancelled) return '🚫';
    return '📅';
  }

  String _getStatusText() {
    if (appointment.isAccepted) return '확정된 약속';
    if (appointment.isRejected) return '거절된 약속';
    if (appointment.isCancelled) return '취소된 약속';
    return '약속 제안';
  }

  Color _getCardColor() {
    if (appointment.isAccepted) return Colors.green[50]!;
    if (appointment.isRejected) return Colors.red[50]!;
    if (appointment.isCancelled) return Colors.grey[200]!;
    return Colors.blue[50]!;
  }

  Color _getBorderColor() {
    if (appointment.isAccepted) return Colors.green;
    if (appointment.isRejected) return Colors.red;
    if (appointment.isCancelled) return Colors.grey;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final dateTime = appointment.dateTime.toDate();
    final dateStr = DateFormat('yyyy.MM.dd (E)', 'ko').format(dateTime);
    final timeStr = DateFormat('a h:mm', 'ko').format(dateTime);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCardColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태 헤더
          Row(
            children: [
              Text(
                _getStatusEmoji(),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getBorderColor(),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // 날짜/시간
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                timeStr,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 장소
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  appointment.location,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),

          // 메모 (있으면)
          if (appointment.memo != null && appointment.memo!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    appointment.memo!,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ],

          const Divider(height: 20),

          // 버튼
          if (appointment.isPending && !isMe) ...[
            // 상대방이 보낸 약속 제안 → 수락/거절 버튼
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await AppointmentService.acceptAppointment(appointment.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('약속을 수락했습니다!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('오류: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('수락'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await AppointmentService.rejectAppointment(appointment.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('약속을 거절했습니다.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('오류: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('거절'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (appointment.isAccepted) ...[
            // 확정된 약속 → 지도보기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => kIsWeb
                          ? AppointmentMapScreenWeb(appointment: appointment)
                          : AppointmentMapScreen(appointment: appointment),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: const Text('지도보기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

