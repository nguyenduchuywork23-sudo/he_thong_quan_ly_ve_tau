/// App Theme – Design System chuẩn Mobile
///
/// Màu sắc:
///   Primary  : #E8470A (đỏ cam đặc trưng vé tàu Việt Nam)
///   Background: #0F1124 (navy tối)
///   Surface  : #1A1D2E
///   Card     : #252840
///
/// Font: Nunito Sans (Google Fonts)
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Màu sắc ─────────────────────────────────
  static const Color primary = Color(0xFFE8470A);
  static const Color primaryLight = Color(0xFFFF6B35);
  static const Color primaryDark = Color(0xFFBF3608);

  static const Color background = Color(0xFF0F1124);
  static const Color surface = Color(0xFF1A1D2E);
  static const Color cardColor = Color(0xFF252840);
  static const Color cardBorder = Color(0xFF343759);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textHint = Color(0xFF6B7280);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color seatAvailable = Color(0xFF22C55E);
  static const Color seatSelected = Color(0xFFE8470A);
  static const Color seatBooked = Color(0xFF4B5563);
  static const Color seatLocked = Color(0xFF6B7280);

  // ─── Gradient ─────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F1124), Color(0xFF1E2140), Color(0xFF0F1124)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A2E4A), Color(0xFF1E2140)],
  );

  // ─── Border Radius ────────────────────────────
  static const double radiusCard = 16.0;
  static const double radiusButton = 14.0;
  static const double radiusInput = 12.0;
  static const double radiusSmall = 8.0;

  // ─── Spacing ──────────────────────────────────
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // ─── ThemeData ────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        secondary: primaryLight,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.nunitoSansTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.nunitoSans(
          fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary,
        ),
        displayMedium: GoogleFonts.nunitoSans(
          fontSize: 26, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        titleLarge: GoogleFonts.nunitoSans(
          fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        titleMedium: GoogleFonts.nunitoSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        titleSmall: GoogleFonts.nunitoSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        bodyLarge: GoogleFonts.nunitoSans(
          fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary,
        ),
        bodyMedium: GoogleFonts.nunitoSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary,
        ),
        bodySmall: GoogleFonts.nunitoSans(
          fontSize: 12, fontWeight: FontWeight.w400, color: textHint,
        ),
        labelLarge: GoogleFonts.nunitoSans(
          fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
        ),
      ),
      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunitoSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      // ── Card ──
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
      ),
      // ── ElevatedButton ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: GoogleFonts.nunitoSans(
            fontSize: 16, fontWeight: FontWeight.w700,
          ),
        ),
      ),
      // ── OutlinedButton ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: GoogleFonts.nunitoSans(
            fontSize: 16, fontWeight: FontWeight.w700,
          ),
        ),
      ),
      // ── Input ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM, vertical: spacingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: GoogleFonts.nunitoSans(color: textHint, fontSize: 14),
        labelStyle: GoogleFonts.nunitoSans(color: textSecondary, fontSize: 14),
      ),
      // ── BottomSheet ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: cardColor,
        labelStyle: GoogleFonts.nunitoSans(fontSize: 12, color: textSecondary),
        side: const BorderSide(color: cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      // ── Divider ──
      dividerTheme: const DividerThemeData(
        color: cardBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
