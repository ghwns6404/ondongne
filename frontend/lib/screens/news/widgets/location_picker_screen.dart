import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

// 웹 전용 import: 웹이 아닐 때는 컴파일되지 않도록 conditional import 사용
import 'location_picker_web.dart' if (dart.library.io) 'location_picker_stub.dart';

class LocationPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  
  // 선택된 위치 정보
  double? _selectedLat;
  double? _selectedLng;
  String? _selectedAddress;
  String? _selectedPlaceName;
  
  final String _webViewId = 'location-picker-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // 웹 전용 초기화는 별도 구현으로 분리
      initLocationPickerWeb(
        webViewId: _webViewId,
        initialLatitude: widget.initialLatitude,
        initialLongitude: widget.initialLongitude,
        onLocationSelected: _handleLocationSelected,
        onLoaded: () {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );
    } else {
      _initWebView();
    }
  }

  void _initWebView() {
    final lat = widget.initialLatitude ?? 36.3504;
    final lng = widget.initialLongitude ?? 127.3845;

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
      ..addJavaScriptChannel(
        'LocationPicker',
        onMessageReceived: (JavaScriptMessage message) {
          _handleLocationSelected(message.message);
        },
      )
      ..loadHtmlString(_buildHtmlContent(lat, lng));
  }

  void _handleLocationSelected(String message) {
    try {
      final data = jsonDecode(message);
      setState(() {
        _selectedLat = data['lat'] as double?;
        _selectedLng = data['lng'] as double?;
        _selectedAddress = data['address'] as String?;
        _selectedPlaceName = data['placeName'] as String?;
      });
    } catch (e) {
      print('위치 파싱 에러: $e');
    }
  }

  String _buildHtmlContent(double lat, double lng) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>위치 선택</title>
    <script type="text/javascript" src="//dapi.kakao.com/v2/maps/sdk.js?appkey=aab1af1b6dae4b5beb07de4c90e35cee&libraries=services"></script>
    <style>
        * { margin: 0; padding: 0; }
        html, body { width: 100%; height: 100%; overflow: hidden; }
        #map { width: 100%; height: 100%; }
        .info-box {
            position: absolute;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            background: white;
            padding: 15px 20px;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            max-width: 90%;
            z-index: 100;
        }
        .info-box h3 {
            margin: 0 0 8px 0;
            font-size: 14px;
            color: #333;
        }
        .info-box p {
            margin: 0;
            font-size: 12px;
            color: #666;
        }
        .confirm-btn {
            position: absolute;
            top: 20px;
            right: 20px;
            background: #4CAF50;
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 8px;
            font-size: 14px;
            font-weight: bold;
            cursor: pointer;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            z-index: 100;
        }
        .confirm-btn:disabled {
            background: #ccc;
            cursor: not-allowed;
        }
    </style>
</head>
<body>
    <div id="map"></div>
    <button id="confirmBtn" class="confirm-btn" onclick="confirmLocation()">이 위치로 선택</button>
    <div id="infoBox" class="info-box" style="display: none;">
        <h3 id="placeName">-</h3>
        <p id="address">-</p>
    </div>

    <script>
        // 선택된 위치 정보 (먼저 초기화)
        let selectedLocation = {
            lat: $lat,
            lng: $lng,
            address: '',
            placeName: ''
        };

        // 카카오맵 스크립트 로딩 대기
        function initMap() {
            if (typeof kakao === 'undefined' || typeof kakao.maps === 'undefined') {
                console.log('카카오맵 로딩 중...');
                setTimeout(initMap, 100);
                return;
            }

            const container = document.getElementById('map');
            const options = {
                center: new kakao.maps.LatLng($lat, $lng),
                level: 3
            };

            const map = new kakao.maps.Map(container, options);
            const geocoder = new kakao.maps.services.Geocoder();

            // 마커 생성
            const markerPosition = new kakao.maps.LatLng($lat, $lng);
            const marker = new kakao.maps.Marker({
                position: markerPosition,
                draggable: true
            });
            marker.setMap(map);

            // 초기 위치 정보 가져오기
            updateLocationInfo($lat, $lng);

            // 마커 드래그 이벤트
            kakao.maps.event.addListener(marker, 'dragend', function() {
                const position = marker.getPosition();
                selectedLocation.lat = position.getLat();
                selectedLocation.lng = position.getLng();
                updateLocationInfo(selectedLocation.lat, selectedLocation.lng);
            });

            // 지도 클릭 이벤트
            kakao.maps.event.addListener(map, 'click', function(mouseEvent) {
                const latlng = mouseEvent.latLng;
                marker.setPosition(latlng);
                selectedLocation.lat = latlng.getLat();
                selectedLocation.lng = latlng.getLng();
                updateLocationInfo(selectedLocation.lat, selectedLocation.lng);
            });

            function updateLocationInfo(lat, lng) {
                geocoder.coord2Address(lng, lat, function(result, status) {
                    if (status === kakao.maps.services.Status.OK) {
                        const address = result[0].address.address_name;
                        selectedLocation.address = address;
                        
                        // 도로명 주소가 있으면 사용
                        if (result[0].road_address) {
                            selectedLocation.placeName = result[0].road_address.building_name || address;
                        } else {
                            selectedLocation.placeName = address;
                        }

                        document.getElementById('placeName').textContent = selectedLocation.placeName;
                        document.getElementById('address').textContent = address;
                        document.getElementById('infoBox').style.display = 'block';
                    }
                });
            }
        }

        // 페이지 로드 후 지도 초기화
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initMap);
        } else {
            initMap();
        }

        function confirmLocation() {
            if (selectedLocation.address) {
                const isWeb = typeof LocationPicker === 'undefined';
                if (isWeb) {
                    // 웹: window.parent로 메시지 전송
                    window.parent.postMessage(JSON.stringify(selectedLocation), '*');
                } else {
                    // 모바일: JavaScriptChannel 사용
                    LocationPicker.postMessage(JSON.stringify(selectedLocation));
                }
            }
        }
    </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // 웹 전용 구현은 별도 파일에 위임
      return buildLocationPickerWebView(
        context: context,
        isLoading: _isLoading,
        webViewId: _webViewId,
        selectedAddress: _selectedAddress,
        selectedLat: _selectedLat,
        selectedLng: _selectedLng,
        selectedPlaceName: _selectedPlaceName,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('위치 선택'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          if (_selectedAddress != null)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () {
                Navigator.of(context).pop({
                  'latitude': _selectedLat,
                  'longitude': _selectedLng,
                  'address': _selectedAddress,
                  'placeName': _selectedPlaceName,
                });
              },
              tooltip: '선택 완료',
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null)
            WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          // 안내 메시지
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '지도를 클릭하거나 마커를 드래그하세요',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

