import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFF2C5E1A);
  static const secondaryColor = Color(0xFF8d693a);
  static const backgroundColor = Color(0xFFFFFFFF);
  static const errorColor = Color(0xFFB00020);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: backgroundColor, // Statt background
        error: errorColor,
      ),
      textTheme: GoogleFonts.robotoTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTheme = lightTheme;
    return baseTheme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.grey[900],
      cardTheme: baseTheme.cardTheme.copyWith(
        color: Colors.grey[850],
      ),
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        fillColor: Colors.grey[850],
      ),
    );
  }
}
