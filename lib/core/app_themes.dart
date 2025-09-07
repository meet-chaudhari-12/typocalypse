// lib/app_themes.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  // --- A NEW, VIBRANT "GAMER" COLOR PALETTE ---
  static const Color _primaryColor = Color(0xFF9C27B0); // A more vibrant Purple
  static const Color _secondaryColor = Color(0xFF00BCD4); // A bright Cyan for accents
  static const Color _darkBackground = Color(0xFF1A1A2E); // A deep, dark blue
  static const Color _darkSurface = Color(0xFF16213E);   // A slightly lighter surface color

  // --- COLOR SCHEMES ---
  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: _primaryColor,
    brightness: Brightness.light,
    secondary: _secondaryColor,
  );

  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: _primaryColor,
    brightness: Brightness.dark,
    background: _darkBackground,
    surface: _darkSurface,
    secondary: _secondaryColor,
  );

  // --- FONT THEME ---
  // Using Orbitron for headers and Inter for body for that "cool but readable" gamer look.
  static final TextTheme _textTheme = GoogleFonts.interTextTheme().copyWith(
    displayLarge: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
    displayMedium: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
    displaySmall: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
    headlineLarge: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
    headlineMedium: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
    headlineSmall: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
  );

  // --- THEME DEFINITIONS ---
  static ThemeData get lightTheme {
    return _buildTheme(_lightColorScheme);
  }

  static ThemeData get darkTheme {
    return _buildTheme(_darkColorScheme);
  }

  // --- CENTRAL THEME BUILDER ---
  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      textTheme: _textTheme.apply(
        bodyColor: colorScheme.onBackground,
        displayColor: colorScheme.onBackground,
      ),
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // Transparent app bar for a modern look
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _textTheme.titleLarge!.copyWith(color: colorScheme.onBackground),
        iconTheme: IconThemeData(color: colorScheme.onBackground),
      ),

      // --- COOLER BUTTON THEMES ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary, // Fixes the invisible text issue
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Pill shape
          textStyle: _textTheme.labelLarge!.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.secondary, // Use accent color
          side: BorderSide(color: colorScheme.secondary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: _textTheme.labelLarge!.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.secondary,
        ),
      ),

      // --- COOLER TEXT FIELD THEME ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.onBackground.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colorScheme.secondary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onBackground.withOpacity(0.6)),
      ),

      // --- COOLER CHIP THEME (for home screen) ---
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        secondaryLabelStyle: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // --- COOLER CARD THEME (for profile screen) ---
      cardTheme: CardThemeData( // Corrected from CardTheme
        elevation: 0,
        color: colorScheme.surface.withOpacity(0.8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.onSurface.withOpacity(0.1))
        ),
      ),
    );
  }
}