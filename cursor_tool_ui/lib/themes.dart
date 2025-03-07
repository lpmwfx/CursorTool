import 'package:flutter/material.dart';

// Farver
final primaryColor = Colors.blue.shade800;
final secondaryColor = Colors.teal.shade600;
final errorColor = Colors.red.shade700;
final successColor = Colors.green.shade600;

// Lys tema
final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: primaryColor,
    secondary: secondaryColor,
    error: errorColor,
    surface: Colors.grey.shade100,
    background: Colors.grey.shade50,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: primaryColor,
    ),
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
    fillColor: Colors.grey.shade100,
  ),
);

// Mørk tema
final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.dark(
    primary: Colors.blue.shade400,
    secondary: Colors.teal.shade300,
    error: Colors.red.shade400,
    surface: Color(0xFF252525),
    background: Color(0xFF1A1A1A),
    onSurface: Colors.grey.shade300,
    onBackground: Colors.grey.shade300,
  ),
  scaffoldBackgroundColor: Color(0xFF121212),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF1E1E1E),
    foregroundColor: Colors.white,
  ),
  cardTheme: CardTheme(
    color: Color(0xFF252525),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.blue.shade400,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    filled: true,
    fillColor: Color(0xFF303030),
  ),
  dialogTheme: DialogTheme(
    backgroundColor: Color(0xFF252525),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
); 