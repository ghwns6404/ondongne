// 비-웹(모바일 등) 환경에서 사용되는 stub 구현

import 'package:flutter/material.dart';

void initLocationMapWeb({
  required String webViewId,
  required double latitude,
  required double longitude,
  required String? placeName,
  required String? address,
  required void Function() onLoaded,
}) {
  // 웹이 아닌 환경에서는 아무 것도 하지 않음
  onLoaded();
}

Widget buildLocationMapWebView({
  required BuildContext context,
  required bool isLoading,
  required String webViewId,
}) {
  // 웹이 아닌 환경에서는 사용되지 않도록, 단순 빈 위젯 반환
  return const SizedBox.shrink();
}


