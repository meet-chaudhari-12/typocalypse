import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  static final ThemeData volcanoTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF100803),
    primaryColor: Colors.orangeAccent,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF9A825),
      secondary: Color(0xFFEF6C00),
      onPrimary: Colors.black,
      onSurface: Colors.white,
      error: Color(0xFFE53935),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEF6C00),
        foregroundColor: Colors.white,
      ),
    ),
    textTheme: GoogleFonts.ebGaramondTextTheme(
      ThemeData.dark().textTheme,
    ),

  );
}