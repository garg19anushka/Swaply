import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────
//  SkillSwap Design System  •  v2.0
//  Aesthetic: Instagram-meets-Snapchat
//  • Pure white surfaces, crisp shadows
//  • Vivid coral/violet accent system
//  • Rounded "pill" geometry everywhere
//  • DM Sans display + Inter body
// ─────────────────────────────────────────────

class AppColors {
  // ── Brand ──────────────────────────────────
  static const Color primary = Color(0xFF6C47FF); // Electric Violet
  static const Color primaryDark = Color(0xFF4F2FE0);
  static const Color primaryLight = Color(0xFF9B7DFF);

  static const Color secondary = Color(
    0xFFFF4D6D,
  ); // Coral Pink (Snapchat energy)
  static const Color secondaryLight = Color(0xFFFF8FA3);

  static const Color accent = Color(0xFFFFBE0B); // Sunny Yellow
  static const Color accentTeal = Color(0xFF00C9A7); // Mint

  // ── Status ─────────────────────────────────
  static const Color success = Color(0xFF00C9A7);
  static const Color successLight = Color(0xFFB2F0E4);
  static const Color warning = Color(0xFFFFBE0B);
  static const Color warningLight = Color(0xFFFFF3CD); // Soft amber tint
  static const Color error = Color(0xFFFF4D6D);
  static const Color errorLight = Color(0xFFFFD6DF);
  static const Color info = Color(0xFF4CC9F0);

  // ── Surfaces (Light / Instagram feel) ──────
  static const Color background = Color(0xFFFAFAFA); // IG background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color cardBg = Color(0xFFFFFFFF);

  // ── Typography ─────────────────────────────
  static const Color textPrimary = Color(0xFF0A0A0A);
  static const Color textSecondary = Color(0xFF6E6E6E);
  static const Color textLight = Color(0xFFAAAAAA);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Borders ────────────────────────────────
  static const Color divider = Color(0xFFEFEFEF);
  static const Color border = Color(0xFFE0E0E0);
  static const Color shimmerBase = Color(0xFFEEEEEE);
  static const Color shimmerHigh = Color(0xFFF8F8F8);

  // ── Gradients ──────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C47FF), Color(0xFFFF4D6D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF6C47FF), Color(0xFF9B4DFF), Color(0xFFFF4D6D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient storyGradient = LinearGradient(
    colors: [Color(0xFFFFBE0B), Color(0xFFFF4D6D), Color(0xFF6C47FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mintGradient = LinearGradient(
    colors: [Color(0xFF00C9A7), Color(0xFF4CC9F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFF4D6D), Color(0xFFFFBE0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Glassmorphism ──────────────────────────
  static Color glassWhite = Colors.white.withOpacity(0.85);
  static Color glassBorder = Colors.white.withOpacity(0.6);
  static Color shadowPrimary = const Color(0xFF6C47FF).withOpacity(0.22);
  static Color shadowCard = Colors.black.withOpacity(0.07);
  static Color shadowStrong = Colors.black.withOpacity(0.13);

  // ── Dark Theme Colors ──────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFAAAAAA);
  static const Color darkTextLight = Color(0xFF6E6E6E);
  static const Color darkDivider = Color(0xFF333333);
  static const Color darkBorder = Color(0xFF444444);
}

// ─────────────────────────────────────────────
//  Shadows
// ─────────────────────────────────────────────
class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get button => [
    BoxShadow(
      color: AppColors.shadowPrimary,
      blurRadius: 18,
      offset: const Offset(0, 8),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get fab => [
    BoxShadow(
      color: AppColors.shadowPrimary,
      blurRadius: 24,
      offset: const Offset(0, 10),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> get bottomNav => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, -4),
    ),
  ];

  static List<BoxShadow> get story => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.35),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];
}

// ─────────────────────────────────────────────
//  Geometry
// ─────────────────────────────────────────────
class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 36;
  static const double full = 999;
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// ─────────────────────────────────────────────
//  Theme
// ─────────────────────────────────────────────
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.light,
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _buildTextTheme(),

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.dmSans(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.dmSans(color: AppColors.textLight, fontSize: 14),
        floatingLabelStyle: GoogleFonts.dmSans(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: AppColors.textLight,
        suffixIconColor: AppColors.textLight,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary.withOpacity(0.12),
        labelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        checkmarkColor: AppColors.primary,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 11),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        labelStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.divider,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _buildTextTheme().apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.dmSans(
          color: AppColors.darkTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary, size: 24),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.darkDivider, width: 1),
        ),
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        labelStyle: GoogleFonts.dmSans(
          color: AppColors.darkTextSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.dmSans(color: AppColors.darkTextLight, fontSize: 14),
        floatingLabelStyle: GoogleFonts.dmSans(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: AppColors.darkTextLight,
        suffixIconColor: AppColors.darkTextLight,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.darkTextLight,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 11),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.dmSans(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -1.0,
      ),
      displayMedium: GoogleFonts.dmSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -0.8,
      ),
      displaySmall: GoogleFonts.dmSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
      headlineMedium: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.dmSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.55,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textLight,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textLight,
        letterSpacing: 0.3,
      ),
    );
  }
}
