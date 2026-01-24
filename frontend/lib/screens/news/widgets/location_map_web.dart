// 웹 전용 구현 (dart:html 사용 가능)
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html show IFrameElement;

import 'package:flutter/material.dart';

import 'platform_view_registry_stub.dart'
    if (dart.library.html) 'platform_view_registry_web.dart';

typedef VoidCallback = void Function();

void initLocationMapWeb({
  required String webViewId,
  required double latitude,
  required double longitude,
  required String? placeName,
  required String? address,
  required VoidCallback onLoaded,
}) {
  final lat = latitude;
  final lng = longitude;
  final encodedPlaceName = Uri.encodeComponent(placeName ?? '');
  final encodedAddress = Uri.encodeComponent(address ?? '');

  platformViewRegistry.registerViewFactory(
    webViewId,
    (int viewId) {
      final iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..src =
            'location_map.html?lat=$lat&lng=$lng&placeName=$encodedPlaceName&address=$encodedAddress';
      return iframe;
    },
  );

  onLoaded();
}

Widget buildLocationMapWebView({
  required BuildContext context,
  required bool isLoading,
  required String webViewId,
}) {
  return Container(
    height: 200,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[300]!),
    ),
    clipBehavior: Clip.hardEdge,
    child: Stack(
      children: [
        HtmlElementView(viewType: webViewId),
        if (isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    ),
  );
}


