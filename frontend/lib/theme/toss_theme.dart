import 'package:flutter/material.dart';

final Color tossPrimary = Color(0xff0064FF);      // 토스 블루
final Color tossBackground = Color(0xffffffff);   // 화이트
final Color tossText = Color(0xff222222);         // 진한 블랙
final Color tossGray = Color(0xffF5F6FA);         // 라이트 그레이

final ThemeData tossTheme = ThemeData(
  primaryColor: tossPrimary,
  scaffoldBackgroundColor: tossBackground,
  appBarTheme: AppBarTheme(
    backgroundColor: tossBackground,
    foregroundColor: tossText,
    elevation: 0,
    iconTheme: IconThemeData(color: tossText),
  ),
  colorScheme: ColorScheme.light(
    primary: tossPrimary,
    surface: tossBackground,
    onSurface: tossText,
    secondary: tossPrimary,
    onPrimary: Colors.white,
  ),
  textTheme: TextTheme(
    displayLarge: TextStyle(fontWeight: FontWeight.bold, color: tossText),
    bodyLarge: TextStyle(color: tossText),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: tossGray,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.all(tossPrimary),
      foregroundColor: WidgetStateProperty.all(Colors.white),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
      ),
    ),
  ),
);
