import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../services/kakao_map_service.dart';

/// 약속 장소를 카카오맵으로 표시하는 화면
class AppointmentMapScreen extends StatefulWidget {
  final Appointment appointment;

  const AppointmentMapScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<AppointmentMapScreen> createState() => _AppointmentMapScreenState();
}

class _AppointmentMapScreenState extends State<AppointmentMapScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    final appointment = widget.appointment;
    final lat = appointment.coordinates?.latitude ?? 36.337728;
    final lng = appointment.coordinates?.longitude ?? 127.445966;
    final placeName = appointment.location;

    // 카카오맵 HTML 생성
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>약속 장소</title>
  <script type="text/javascript"
    src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=bf70f20aeca20060f22c896cfb4e36cd"></script>
  <style>
    body { margin: 0; padding: 0; }
    #map { width: 100%; height: 100vh; }
    .custom-overlay {
      position: relative;
      background: white;
      border: 2px solid #088A08;
      border-radius: 8px;
      padding: 10px;
      box-shadow: 0 2px 6px rgba(0,0,0,0.3);
      font-size: 14px;
      font-weight: bold;
    }
    .custom-overlay:after {
      content: '';
      position: absolute;
      bottom: -10px;
      left: 50%;
      margin-left: -10px;
      border: 10px solid transparent;
      border-top-color: #088A08;
    }
  </style>
</head>
<body>
  <div id="map"></div>
  <script>
    var mapContainer = document.getElementById('map');
    var mapOption = { 
      center: new kakao.maps.LatLng($lat, $lng),
      level: 3
    };
    var map = new kakao.maps.Map(mapContainer, mapOption);
    
    var marker = new kakao.maps.Marker({
      map: map, 
      position: new kakao.maps.LatLng($lat, $lng)
    });
    
    var content = '<div class="custom-overlay">📍 약속 장소<br/>$placeName</div>';
    
    var customOverlay = new kakao.maps.CustomOverlay({
      map: map,
      position: marker.getPosition(),
      content: content,
      yAnchor: 1.5
    });
  </script>
</body>
</html>
''';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(htmlContent);
  }

  Future<void> _openInKakaoMap() async {
    final appointment = widget.appointment;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('카카오맵을 열 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openNavigation() async {
    final appointment = widget.appointment;
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
      if (mounted) {
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
    final appointment = widget.appointment;
    final dateTime = appointment.dateTime.toDate();
    final dateStr = DateFormat('yyyy.MM.dd (E) a h:mm', 'ko').format(dateTime);

    return Scaffold(
      appBar: AppBar(
        title: const Text('약속 장소'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Stack(
        children: [
          // 지도
          WebViewWidget(controller: _controller),

          // 로딩 인디케이터
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // 하단 정보 카드
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 날짜/시간
                    Row(
                      children: [
                        const Icon(Icons.event, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 장소
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            appointment.location,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),

                    // 메모
                    if (appointment.memo != null && appointment.memo!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.chat_bubble_outline,
                              color: Colors.grey, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              appointment.memo!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const Divider(height: 20),

                    // 버튼
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openInKakaoMap,
                            icon: const Icon(Icons.map),
                            label: const Text('카카오맵'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow[700],
                              foregroundColor: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openNavigation,
                            icon: const Icon(Icons.navigation),
                            label: const Text('길찾기'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

