import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF818CF8);
  static const Color secondaryLight = Color(0xFF10B981);
  static const Color secondaryDark = Color(0xFF34D399);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF1E293B);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF334155);
  static const Color textLight = Color(0xFF1E293B);
  static const Color textDark = Color(0xFFF8FAFC);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryLight,
        background: backgroundLight,
        surface: surfaceLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: textLight,
        onSurface: textLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primaryLight,
        unselectedItemColor: Colors.grey,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryLight, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        background: backgroundDark,
        surface: surfaceDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: textDark,
        onSurface: textDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryDark,
        unselectedItemColor: Colors.grey,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryDark, width: 2),
        ),
        filled: true,
        fillColor: Color(0xFF475569),
      ),
    );
  }

  // Additional themes
  static final Map<String, ThemeData> additionalThemes = {
    'desert': _desertTheme,
    'emerald': _emeraldTheme,
    'azure': _azureTheme,
    'ramadan': _ramadanTheme,
    'calligraphy': _calligraphyTheme,
  };

  static ThemeData get _desertTheme {
    return lightTheme.copyWith(
      colorScheme: lightTheme.colorScheme.copyWith(
        primary: Color(0xFFD97706),
        secondary: Color(0xFFF59E0B),
        background: Color(0xFFFEF3C7),
        surface: Color(0xFFFFFBEB),
      ),
    );
  }

  static ThemeData get _emeraldTheme {
    return lightTheme.copyWith(
      colorScheme: lightTheme.colorScheme.copyWith(
        primary: Color(0xFF059669),
        secondary: Color(0xFF10B981),
        background: Color(0xFFECFDF5),
        surface: Color(0xFFFFFFFF),
      ),
    );
  }

  static ThemeData get _azureTheme {
    return lightTheme.copyWith(
      colorScheme: lightTheme.colorScheme.copyWith(
        primary: Color(0xFF0284C7),
        secondary: Color(0xFF0EA5E9),
        background: Color(0xFFECFEFF),
        surface: Color(0xFFFFFFFF),
      ),
    );
  }

  static ThemeData get _ramadanTheme {
    return lightTheme.copyWith(
      colorScheme: lightTheme.colorScheme.copyWith(
        primary: Color(0xFF8254C8),
        secondary: Color(0xFFD4AF37),
        background: Color(0xFFF8F4FF),
        surface: Color(0xFFFFFFFF),
      ),
    );
  }

  static ThemeData get _calligraphyTheme {
    return darkTheme.copyWith(
      colorScheme: darkTheme.colorScheme.copyWith(
        primary: Color(0xFFDBB98F),
        secondary: Color(0xFFBC8A5F),
        background: Color(0xFF1A1A1A),
        surface: Color(0xFF2A2A2A),
      ),
    );
  }
} 