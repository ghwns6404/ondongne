// 웹 전용 구현 (dart:html 사용 가능)
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:html' as html show window, IFrameElement;

import 'package:flutter/material.dart';

import 'platform_view_registry_stub.dart'
    if (dart.library.html) 'platform_view_registry_web.dart';

typedef LocationSelectedCallback = void Function(String message);
typedef VoidCallback = void Function();

void initLocationPickerWeb({
  required String webViewId,
  required double? initialLatitude,
  required double? initialLongitude,
  required LocationSelectedCallback onLocationSelected,
  required VoidCallback onLoaded,
}) {
  final lat = initialLatitude ?? 36.3504;
  final lng = initialLongitude ?? 127.3845;

  platformViewRegistry.registerViewFactory(
    webViewId,
    (int viewId) {
      final iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..src = 'location_picker.html?lat=$lat&lng=$lng';

      return iframe;
    },
  );

  // 메시지 리스너 추가
  html.window.onMessage.listen((event) {
    if (event.data is String) {
      try {
        onLocationSelected(event.data as String);
      } catch (_) {
        // 무시
      }
    }
  });

  onLoaded();
}

Widget buildLocationPickerWebView({
  required BuildContext context,
  required bool isLoading,
  required String webViewId,
  required String? selectedAddress,
  required double? selectedLat,
  required double? selectedLng,
  required String? selectedPlaceName,
}) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('위치 선택'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      actions: [
        if (selectedAddress != null)
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () {
              Navigator.of(context).pop({
                'latitude': selectedLat,
                'longitude': selectedLng,
                'address': selectedAddress,
                'placeName': selectedPlaceName,
              });
            },
            tooltip: '선택 완료',
          ),
      ],
    ),
    body: Stack(
      children: [
        HtmlElementView(viewType: webViewId),
        if (isLoading)
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


