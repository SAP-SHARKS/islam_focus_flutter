// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Theme model that can be controlled from admin panel
class AppThemeData {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color successColor;
  final Color errorColor;
  final Color breathingStartColor;
  final Color breathingEndColor;
  final Brightness brightness;

  const AppThemeData({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.successColor,
    required this.errorColor,
    required this.breathingStartColor,
    required this.breathingEndColor,
    required this.brightness,
  });

  /// Default Light Calming Theme (Matching Onboarding)
  factory AppThemeData.lightCalm() {
    return const AppThemeData(
      primaryColor: Color(0xFF1DB954),       // Spotify green
      secondaryColor: Color(0xFF2E7D6F),     // Calm teal/green
      accentColor: Color(0xFFF0C27B),        // Warm gold
      backgroundColor: Color(0xFFFDF8F4),    // Beige background
      surfaceColor: Color(0xFFFFFFFF),        // Pure white
      cardColor: Color(0xFFFFFFFF),           // White cards
      textPrimary: Color(0xFF1A1A1A),         // Near black
      textSecondary: Color(0xFF666666),       // Muted gray
      successColor: Color(0xFF27AE60),        // Green
      errorColor: Color(0xFFE74C3C),          // Red
      breathingStartColor: Color(0xFFE8F4FD), // Light sky blue
      breathingEndColor: Color(0xFF1DB954),   // Matching primary
      brightness: Brightness.light,
    );
  }

  /// Convert from Supabase JSON
  factory AppThemeData.fromJson(Map<String, dynamic> json) {
    return AppThemeData(
      primaryColor: _colorFromHex(json['primary_color'] ?? '#5B9BD5'),
      secondaryColor: _colorFromHex(json['secondary_color'] ?? '#2E7D6F'),
      accentColor: _colorFromHex(json['accent_color'] ?? '#F0C27B'),
      backgroundColor: _colorFromHex(json['background_color'] ?? '#F7F9FC'),
      surfaceColor: _colorFromHex(json['surface_color'] ?? '#FFFFFF'),
      cardColor: _colorFromHex(json['card_color'] ?? '#FFFFFF'),
      textPrimary: _colorFromHex(json['text_primary'] ?? '#2C3E50'),
      textSecondary: _colorFromHex(json['text_secondary'] ?? '#7F8C8D'),
      successColor: _colorFromHex(json['success_color'] ?? '#27AE60'),
      errorColor: _colorFromHex(json['error_color'] ?? '#E74C3C'),
      breathingStartColor: _colorFromHex(json['breathing_start_color'] ?? '#E8F4FD'),
      breathingEndColor: _colorFromHex(json['breathing_end_color'] ?? '#5B9BD5'),
      brightness: json['brightness'] == 'dark' ? Brightness.dark : Brightness.light,
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'primary_color': _colorToHex(primaryColor),
      'secondary_color': _colorToHex(secondaryColor),
      'accent_color': _colorToHex(accentColor),
      'background_color': _colorToHex(backgroundColor),
      'surface_color': _colorToHex(surfaceColor),
      'card_color': _colorToHex(cardColor),
      'text_primary': _colorToHex(textPrimary),
      'text_secondary': _colorToHex(textSecondary),
      'success_color': _colorToHex(successColor),
      'error_color': _colorToHex(errorColor),
      'breathing_start_color': _colorToHex(breathingStartColor),
      'breathing_end_color': _colorToHex(breathingEndColor),
      'brightness': brightness == Brightness.dark ? 'dark' : 'light',
    };
  }

  /// Build Flutter ThemeData from our custom theme
  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        error: errorColor,
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: textPrimary,
      ),
      cardColor: cardColor,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static Color _colorFromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  static String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }
}
