// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF4F8CFF);
  static const dark = Color(0xFF0B1020);
  static const purple = Color(0xFF7B61FF);
  static const cyan = Color(0xFF5FE1FF);

  static ThemeData lightTheme = ThemeData(
    fontFamily: 'Inter',
    scaffoldBackgroundColor: Colors.white,
    primaryColor: const Color.fromARGB(255, 215, 219, 226),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      bodyMedium: TextStyle(fontSize: 14),
      bodySmall: TextStyle(fontSize: 12),
    ),
  );
}
