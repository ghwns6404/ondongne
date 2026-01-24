// 비-웹(모바일 등) 환경에서 사용되는 stub 구현

import 'package:flutter/material.dart';

void initLocationPickerWeb({
  required String webViewId,
  required double? initialLatitude,
  required double? initialLongitude,
  required void Function(String message) onLocationSelected,
  required void Function() onLoaded,
}) {
  // 웹이 아닌 환경에서는 아무 것도 하지 않음
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
  // 웹이 아닌 환경에서는 사용되지 않도록, 단순 빈 위젯 반환
  return const SizedBox.shrink();
}


