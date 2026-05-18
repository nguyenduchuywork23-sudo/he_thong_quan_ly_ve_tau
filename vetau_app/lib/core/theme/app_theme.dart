library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF2196F3);       // Blue 500
  static const Color primaryLight = Color(0xFF64B5F6);  // Blue 300
  static const Color primaryDark = Color(0xFF1976D2);   // Blue 700

  static const Color background = Color(0xFFF3F8FF);    // Xanh lam cực nhạt
  static const Color surface = Color(0xFFFFFFFF);       // Trắng tinh
  static const Color cardColor = Color(0xFFFFFFFF);     // Trắng tinh
  static const Color cardBorder = Color(0xFFE2E8F0);    // Slate 200

  static const Color textPrimary = Color(0xFF1A237E);   // Xanh đen đậm (Indigo 900)
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textHint = Color(0xFF94A3B8);      // Slate 400

  static const Color success = Color(0xFF10B981);       // Emerald 500
  static const Color warning = Color(0xFFF59E0B);       // Amber 500
  static const Color error = Color(0xFFEF4444);         // Red 500
  static const Color info = Color(0xFF3B82F6);          // Blue 500

  static const Color seatAvailable = Color(0xFF10B981);
  static const Color seatSelected = Color(0xFF2196F3);
  static const Color seatBooked = Color(0xFFCBD5E1);
  static const Color seatLocked = Color(0xFF94A3B8);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB), Color(0xFFE3F2FD)], // Soft blue hero
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
  );

  static const double radiusCard = 20.0;
  static const double radiusButton = 16.0;
  static const double radiusInput = 16.0;
  static const double radiusSmall = 10.0;

  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF1A237E).withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
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
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent, // Ngăn Material 3 tự đổi màu
        shadowColor: const Color(0xFF1A237E).withOpacity(0.05),
        titleTextStyle: GoogleFonts.nunitoSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primary.withOpacity(0.5),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: GoogleFonts.nunitoSans(
            fontSize: 16, fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          backgroundColor: surface,
          side: const BorderSide(color: primaryLight, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: GoogleFonts.nunitoSans(
            fontSize: 16, fontWeight: FontWeight.w700,
          ),
        ),
      ),
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
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: background,
        labelStyle: GoogleFonts.nunitoSans(fontSize: 12, color: textSecondary),
        side: const BorderSide(color: cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(
        color: cardBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
