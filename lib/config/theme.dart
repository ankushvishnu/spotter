import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Energetic Dark / Spotter Aesthetic
  static const Color primaryColor   = Color(0xFFFF5C1A); // Vibrant Orange
  static const Color accentColor    = Color(0xFFFF8C42); // Soft Orange 
  static const Color secondaryColor = Color(0xFF8B3DFF); // Violet
  static const Color backgroundColor = Color(0xFF070709); // Deepest Black
  static const Color surfaceColor   = Color(0xFF14141E); // Elevated Surface
  static const Color cardColor      = Color(0xFF1A1A28); // Lighter Surface
  static const Color textPrimary    = Color(0xFFEEEAF8); // Soft White
  static const Color textSecondary  = Color(0xFF8888AA); // Muted Violet/Gray
  static const Color successColor   = Color(0xFF00C853);
  static const Color errorColor     = Color(0xFFFF3E3E);
  static const Color warningColor   = Color(0xFFF5C842); // Gold


  // Spacing Constants
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration slowAnimation = Duration(milliseconds: 800);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, accentColor],       // energetic orange
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient energeticGradient = LinearGradient(
    colors: [secondaryColor, Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [cardColor, surfaceColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Box Shadows
  static BoxShadow primaryGlow = BoxShadow(
    color: primaryColor.withValues(alpha: 0.35),
    blurRadius: 20,
    spreadRadius: 2,
  );

  static BoxShadow accentGlow = BoxShadow(
    color: accentColor.withValues(alpha: 0.35),
    blurRadius: 20,
    spreadRadius: 2,
  );

  // Button Decorations
  static BoxDecoration gradientButtonDecoration({double radius = 12}) {
    return BoxDecoration(
      gradient: primaryGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [primaryGlow],
    );
  }

  static BoxDecoration energeticButtonDecoration({double radius = 12}) {
    return BoxDecoration(
      gradient: energeticGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: secondaryColor.withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 2,
        ),
      ],
    );
  }

  static ButtonStyle gradientButtonStyle({double radius = 12}) {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  // Fitness Category Helpers
  static IconData getFitnessIcon(String category) {
    switch (category.toLowerCase()) {
      case 'strength':
        return Icons.fitness_center_rounded;
      case 'cardio':
        return Icons.directions_run_rounded;
      case 'yoga':
        return Icons.self_improvement_rounded;
      case 'crossfit':
        return Icons.sports_gymnastics_rounded;
      case 'nutrition':
        return Icons.restaurant_rounded;
      default:
        return Icons.sports_rounded;
    }
  }

  static Color getFitnessColor(String category) {
    switch (category.toLowerCase()) {
      case 'strength':
        return primaryColor;
      case 'cardio':
        return secondaryColor;
      case 'yoga':
        return accentColor;
      case 'crossfit':
        return warningColor;
      case 'nutrition':
        return successColor;
      default:
        return primaryColor;
    }
  }

  static LinearGradient getFitnessGradient(String category) {
    switch (category.toLowerCase()) {
      case 'strength':
        return primaryGradient;
      case 'cardio':
        return energeticGradient;
      case 'yoga':
        return const LinearGradient(
          colors: [accentColor, Color(0xFF00A3CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'crossfit':
        return const LinearGradient(
          colors: [warningColor, Color(0xFFFFD700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'nutrition':
        return const LinearGradient(
          colors: [successColor, Color(0xFF00CC6F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return primaryGradient;
    }
  }

  // Dark Athletic Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      surface: surfaceColor,
    ),
    
    // Text Theme - Bold Athletic Editorial Style
    textTheme: GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.montserrat(
        fontSize: 44,
        fontWeight: FontWeight.w900,
        color: textPrimary,
        letterSpacing: -1.5, // tighter kerning for premium feel
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 34,
        fontWeight: FontWeight.w900,
        color: textPrimary,
        letterSpacing: -1.0,
      ),
      displaySmall: GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: textPrimary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: textSecondary,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: textSecondary,
        height: 1.4,
      ),
    ),
    
    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: textPrimary),
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
    ),
    
    // Card Theme
    cardTheme: const CardThemeData(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
    
    // Elevated Button Theme - Bold & Energetic
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: backgroundColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        textStyle: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        textStyle: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: surfaceColor,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 12,
      ),
    ),
  );
}

// Extension for Gradient opacity (workaround)
extension GradientExtension on LinearGradient {
  LinearGradient withOpacity(double opacity) {
    return LinearGradient(
      colors: colors.map((color) => color.withValues(alpha: opacity)).toList(),
      begin: begin,
      end: end,
      stops: stops,
    );
  }
}