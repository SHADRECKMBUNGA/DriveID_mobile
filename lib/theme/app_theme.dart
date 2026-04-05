import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0B1220);
  static const Color cardDark = Color(0xFF111827);
  static const Color gold = Color(0xFFD4A24C);
  static const Color goldLight = Color(0xFFE6B566);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white54;

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    fontFamily: 'Roboto',
  );
}
