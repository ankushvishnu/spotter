import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Enhanced Energetic Color Palette
  static const Color primaryColor = Color(0xFF00FF87); // Vibrant Neon Green
  static const Color secondaryColor = Color(0xFFFF3E3E); // Energetic Red
  static const Color accentColor = Color(0xFF00D9FF); // Electric Blue
  static const Color tertiaryColor = Color(0xFFFFB800); // Golden Yellow
  static const Color backgroundColor = Color(0xFF0A0A1A); // Deep Space Blue (darker for contrast)
  static const Color surfaceColor = Color(0xFF121222); // Slightly lighter surface
  static const Color cardColor = Color(0xFF1A1A2E); // Card background
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B3C1);
  static const Color successColor = Color(0xFF00FF87);
  static const Color errorColor = Color(0xFFFF3E3E);
  static const Color warningColor = Color(0xFFFFB800);
  static const Color infoColor = Color(0xFF00D9FF);

  // Gradient Colors for Energetic Effects
  static LinearGradient primaryGradient = const LinearGradient(
    colors: [Color(0xFF00FF87), Color(0xFF00D9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient energeticGradient = const LinearGradient(
    colors: [Color(0xFFFF3E3E), Color(0xFFFFB800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient cardGradient = LinearGradient(
    colors: [cardColor.withOpacity(0.8), cardColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glow Effects
  static BoxShadow primaryGlow = BoxShadow(
    color: primaryColor.withOpacity(0.3),
    blurRadius: 20,
    spreadRadius: 2,
  );

  static BoxShadow energeticGlow = BoxShadow(
    color: secondaryColor.withOpacity(0.3),
    blurRadius: 20,
    spreadRadius: 2,
  );
  
  // Dark Athletic Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
      background: backgroundColor,
      surface: surfaceColor,
    ),
    
    // Enhanced Text Theme - More Impactful and Energetic
    textTheme: GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.montserrat(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        color: textPrimary,
        letterSpacing: -1.5,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        color: textPrimary,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      displaySmall: GoogleFonts.montserrat(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.montserrat(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        letterSpacing: -0.3,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.2,
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
        height: 1.4,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        color: textSecondary.withOpacity(0.8),
        height: 1.3,
      ),
      labelLarge: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.3,
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
    
    // Enhanced Card Theme with Depth
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      surfaceTintColor: Colors.white.withOpacity(0.05),
    ),

    // Enhanced Input Decoration with Focus Effects
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: GoogleFonts.inter(
        color: textSecondary,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.inter(
        color: textSecondary.withOpacity(0.6),
      ),
      prefixIconColor: MaterialStateColor.resolveWith((states)
        => states.contains(MaterialState.focused) ? primaryColor : textSecondary),
    ),
    
    // Enhanced Elevated Button Theme with Gradient and Glow
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
        shadowColor: primaryColor.withOpacity(0.3),
      ),
    ).copyWith(
      elevation: MaterialStateProperty.resolveWith<double>((states) {
        if (states.contains(MaterialState.pressed)) return 0;
        if (states.contains(MaterialState.hovered)) return 8;
        return 4;
      }),
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
    
    // Enhanced Outlined Button Theme
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
    ).copyWith(
      side: MaterialStateProperty.resolveWith<BorderSide>((states) {
        if (states.contains(MaterialState.hovered)) {
          return const BorderSide(color: secondaryColor, width: 2);
        }
        return const BorderSide(color: primaryColor, width: 2);
      }),
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
    
    // Enhanced Bottom Navigation Bar Theme
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
      selectedIconTheme: IconThemeData(
        color: primaryColor,
        size: 26,
      ),
      unselectedIconTheme: IconThemeData(
        color: textSecondary,
        size: 24,
      ),
    ),
  );

  // Helper Methods for UI Components

  static BoxDecoration gradientButtonDecoration({double radius = 16}) {
    return BoxDecoration(
      gradient: primaryGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [primaryGlow],
    );
  }

  static BoxDecoration energeticButtonDecoration({double radius = 16}) {
    return BoxDecoration(
      gradient: energeticGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [energeticGlow],
    );
  }

  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      gradient: cardGradient,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  static ButtonStyle gradientButtonStyle({double radius = 16}) {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
      foregroundColor: MaterialStateProperty.all<Color>(backgroundColor),
      padding: MaterialStateProperty.all<EdgeInsets>(
        const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      ),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      textStyle: MaterialStateProperty.all<TextStyle>(
        GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.hovered)) {
          return Colors.white.withOpacity(0.1);
        }
        if (states.contains(MaterialState.pressed)) {
          return Colors.white.withOpacity(0.2);
        }
        return null;
      }),
    );
  }

  // Animation durations for consistent feel
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Spacing system for consistency
  static const double spacingXS = 4;
  static const double spacingSM = 8;
  static const double spacingMD = 16;
  static const double spacingLG = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  // Fitness Icon Mapping
  static Map<String, IconData> fitnessIcons = {
    'strength': Icons.fitness_center_rounded,
    'cardio': Icons.directions_run_rounded,
    'yoga': Icons.self_improvement_rounded,
    'crossfit': Icons.sports_gymnastics_rounded,
    'nutrition': Icons.restaurant_menu_rounded,
    'weightlifting': Icons.sports_rounded,
    'endurance': Icons.directions_bike_rounded,
    'flexibility': Icons.accessibility_rounded,
    'rehab': Icons.healing_rounded,
    'boxing': Icons.sports_mma_rounded,
    'pilates': Icons.spa_rounded,
    'functional': Icons.airline_seat_flat_angled_rounded,
  };

  static IconData getFitnessIcon(String category, {IconData defaultIcon = Icons.fitness_center_rounded}) {
    return fitnessIcons[category.toLowerCase()] ?? defaultIcon;
  }

  // Fitness Color Mapping
  static Map<String, Color> fitnessColors = {
    'strength': Color(0xFFFF6B6B),
    'cardio': Color(0xFF4ECDC4),
    'yoga': Color(0xFFA0D8B3),
    'crossfit': Color(0xFFFFB347),
    'nutrition': Color(0xFF68B0AB),
    'weightlifting': Color(0xFFFF6348),
    'endurance': Color(0xFF48DBFB),
    'flexibility': Color(0xFFDDA0DD),
    'rehab': Color(0xFF85C1E9),
    'boxing': Color(0xFFF7DC6F),
    'pilates': Color(0xFFBB8FCE),
    'functional': Color(0xFF7FB3D3),
  };

  static Color getFitnessColor(String category, {Color defaultColor = primaryColor}) {
    return fitnessColors[category.toLowerCase()] ?? defaultColor;
  }

  // Fitness Gradient Mapping
  static Map<String, Gradient> fitnessGradients = {
    'strength': LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
    'cardio': LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)]),
    'yoga': LinearGradient(colors: [Color(0xFFA0D8B3), Color(0xFF7BCCB5)]),
    'crossfit': LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFFFCC33)]),
  };

  static Gradient getFitnessGradient(String category, {Gradient? defaultGradient}) {
    return fitnessGradients[category.toLowerCase()] ?? defaultGradient ?? primaryGradient;
  }
}