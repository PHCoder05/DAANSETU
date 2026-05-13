import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// DAANSETU Premium Theme - Zomato-inspired clean design
class AppTheme {
  // Primary Colors - Clean, modern palette
  static const Color primaryRed = Color(0xFFE23744);     // Zomato Red
  static const Color primaryGreen = Color(0xFF1BAC4B);   // Success Green
  static const Color accentOrange = Color(0xFFF39C12);   // Warm Orange
  static const Color accentBlue = Color(0xFF3498DB);     // Clean Blue
  static const Color primaryBlue = Color(0xFF3498DB);    // Alias for accentBlue
  
  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8F9FA);
  static const Color lightGray = Color(0xFFE9ECEF);
  static const Color gray = Color(0xFFADB5BD);
  static const Color darkGray = Color(0xFF6C757D);
  static const Color charcoal = Color(0xFF343A40);
  static const Color black = Color(0xFF1A1A1A);
  
  // Background Colors
  static const Color scaffoldLight = Color(0xFFFAFAFA);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color scaffoldDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);
  
  // Status Colors
  static const Color success = Color(0xFF1BAC4B);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);
  
  // Category Colors
  static const Map<String, Color> categoryColors = {
    'food': Color(0xFFE23744),
    'clothes': Color(0xFF9B59B6),
    'books': Color(0xFF3498DB),
    'medical': Color(0xFF1ABC9C),
    'electronics': Color(0xFFE67E22),
    'furniture': Color(0xFF795548),
    'other': Color(0xFF607D8B),
  };
  
  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static InputDecoration inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: offWhite,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryRed, width: 2),
    ),
  );

  // Border Radius
  static BorderRadius get borderRadiusSmall => BorderRadius.circular(8);
  static BorderRadius get borderRadiusMedium => BorderRadius.circular(12);
  static BorderRadius get borderRadiusLarge => BorderRadius.circular(16);
  static BorderRadius get borderRadiusXL => BorderRadius.circular(24);

  // ===== LIGHT THEME =====
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: scaffoldLight,
    primaryColor: primaryRed,
    colorScheme: const ColorScheme.light(
      primary: primaryRed,
      secondary: primaryGreen,
      surface: cardLight,
      error: error,
      onPrimary: white,
      onSecondary: white,
      onSurface: charcoal,
    ),
    
    // Typography
    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: black,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: black,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: black,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: black,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: charcoal,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: charcoal,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: darkGray,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: darkGray,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: gray,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: charcoal,
      ),
    ),
    
    // App Bar
    appBarTheme: AppBarTheme(
      backgroundColor: white,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: black,
      ),
      iconTheme: const IconThemeData(color: charcoal),
    ),
    
    // Cards
    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadiusMedium,
      ),
      margin: EdgeInsets.zero,
    ),
    
    // Elevated Button
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMedium,
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Outlined Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryRed,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMedium,
        ),
        side: const BorderSide(color: primaryRed, width: 1.5),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Text Button
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryRed,
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: offWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: primaryRed, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: error),
      ),
      hintStyle: GoogleFonts.poppins(color: gray, fontSize: 14),
      labelStyle: GoogleFonts.poppins(color: darkGray, fontSize: 14),
    ),
    
    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: white,
      selectedItemColor: primaryRed,
      unselectedItemColor: gray,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: offWhite,
      selectedColor: primaryRed.withValues(alpha: 0.1),
      labelStyle: GoogleFonts.poppins(fontSize: 13, color: darkGray),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadiusSmall,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    
    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryRed,
      foregroundColor: white,
      elevation: 4,
    ),
    
    // Divider
    dividerTheme: const DividerThemeData(
      color: lightGray,
      thickness: 1,
      space: 1,
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: darkGray,
      size: 24,
    ),
  );

  // ===== DARK THEME =====
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: scaffoldDark,
    primaryColor: primaryRed,
    colorScheme: const ColorScheme.dark(
      primary: primaryRed,
      secondary: primaryGreen,
      surface: cardDark,
      error: error,
      onPrimary: white,
      onSecondary: white,
      onSurface: white,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: scaffoldDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: white,
      ),
      iconTheme: const IconThemeData(color: white),
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadiusMedium,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: Color(0xFF2D2D2D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: primaryRed, width: 2),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A1A1A),
      selectedItemColor: primaryRed,
      unselectedItemColor: gray,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
