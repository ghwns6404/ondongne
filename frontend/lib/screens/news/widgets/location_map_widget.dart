import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show IFrameElement;

import 'platform_view_registry_stub.dart'
    if (dart.library.html) 'platform_view_registry_web.dart';

class LocationMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? placeName;
  final String? address;

  const LocationMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.address,
  });

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget> {
  WebViewController? _controller;
  bool _isLoading = true;
  late final String _webViewId;

  @override
  void initState() {
    super.initState();
    _webViewId = 'location-map-${widget.latitude}-${widget.longitude}-${DateTime.now().millisecondsSinceEpoch}';
    
    if (kIsWeb) {
      _initWebIframe();
    } else {
      _initWebView();
    }
  }
  
  void _initWebIframe() {
    final lat = widget.latitude;
    final lng = widget.longitude;
    final placeName = Uri.encodeComponent(widget.placeName ?? '');
    final address = Uri.encodeComponent(widget.address ?? '');
    
    platformViewRegistry.registerViewFactory(
      _webViewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..src = 'location_map.html?lat=$lat&lng=$lng&placeName=$placeName&address=$address';
        return iframe;
      },
    );
    
    setState(() {
      _isLoading = false;
    });
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadHtmlString(_buildHtmlContent());
  }

  String _buildHtmlContent() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>위치 지도</title>
    <script type="text/javascript" src="//dapi.kakao.com/v2/maps/sdk.js?appkey=aab1af1b6dae4b5beb07de4c90e35cee"></script>
    <style>
        * { margin: 0; padding: 0; }
        html, body { width: 100%; height: 100%; overflow: hidden; }
        #map { width: 100%; height: 100%; }
    </style>
</head>
<body>
    <div id="map"></div>

    <script>
        // 카카오맵 스크립트 로딩 대기
        function initMap() {
            if (typeof kakao === 'undefined' || typeof kakao.maps === 'undefined') {
                console.log('카카오맵 로딩 중...');
                setTimeout(initMap, 100);
                return;
            }

            const container = document.getElementById('map');
            const options = {
                center: new kakao.maps.LatLng(${widget.latitude}, ${widget.longitude}),
                level: 3
            };

            const map = new kakao.maps.Map(container, options);

            // 마커 생성
            const markerPosition = new kakao.maps.LatLng(${widget.latitude}, ${widget.longitude});
            const marker = new kakao.maps.Marker({
                position: markerPosition
            });
            marker.setMap(map);

            // 인포윈도우 생성 (이름이나 주소가 있는 경우)
            ${widget.placeName != null || widget.address != null ? '''
            const iwContent = '<div style="padding:10px; font-size:12px; max-width:200px;">''' +
                '''${widget.placeName != null ? '<div style="font-weight:bold; margin-bottom:4px;">${widget.placeName}</div>' : ''}''' +
                '''${widget.address != null ? '<div style="color:#666;">${widget.address}</div>' : ''}''' +
                '''</div>';
            const iwPosition = new kakao.maps.LatLng(${widget.latitude}, ${widget.longitude});
            const infowindow = new kakao.maps.InfoWindow({
                position: iwPosition,
                content: iwContent
            });
            infowindow.open(map, marker);
            ''' : ''}
        }

        // 페이지 로드 후 지도 초기화
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initMap);
        } else {
            initMap();
        }
    </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // 웹에서는 HTML 파일로 카카오맵 표시
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            HtmlElementView(viewType: _webViewId),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          if (_controller != null)
            WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

