import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../services/kakao_map_service.dart';

/// 웹용 약속 장소 화면 (카카오맵 링크로 이동)
class AppointmentMapScreenWeb extends StatelessWidget {
  final Appointment appointment;

  const AppointmentMapScreenWeb({
    super.key,
    required this.appointment,
  });

  Future<void> _openInKakaoMap(BuildContext context) async {
    final lat = appointment.coordinates?.latitude ?? 36.337728;
    final lng = appointment.coordinates?.longitude ?? 127.445966;
    
    final url = KakaoMapService.getKakaoMapUrl(
      lat: lat,
      lng: lng,
      placeName: appointment.location,
    );

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('카카오맵을 열 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openNavigation(BuildContext context) async {
    final lat = appointment.coordinates?.latitude ?? 36.337728;
    final lng = appointment.coordinates?.longitude ?? 127.445966;
    
    final url = KakaoMapService.getKakaoNaviUrl(
      lat: lat,
      lng: lng,
      placeName: appointment.location,
    );

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('길찾기를 열 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateTime = appointment.dateTime.toDate();
    final dateStr = DateFormat('yyyy.MM.dd (E) a h:mm', 'ko').format(dateTime);

    return Scaffold(
      appBar: AppBar(
        title: const Text('약속 장소'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.place, color: Colors.blue, size: 32),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          '약속 장소',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // 날짜/시간
                  Row(
                    children: [
                      const Icon(Icons.event, color: Colors.blue, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 장소
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place, color: Colors.red, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          appointment.location,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),

                  // 메모
                  if (appointment.memo != null && appointment.memo!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            appointment.memo!,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Divider(height: 32),

                  // 버튼
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openInKakaoMap(context),
                          icon: const Icon(Icons.map),
                          label: const Text('카카오맵 열기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[700],
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openNavigation(context),
                          icon: const Icon(Icons.navigation),
                          label: const Text('길찾기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 안내 메시지
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '웹 브라우저에서는 카카오맵이 새 탭에서 열립니다.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

