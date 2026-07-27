import 'package:flutter/material.dart';
import 'package:drip_ui/drip_ui.dart';

class AppTheme {
  // --- CONFIGURACIÓN LIGHT MODE (Family Budget Tracker) ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF000666), // Deep Navy Blue
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF006d37), // Mint Green
      onSecondary: Color(0xFFFFFFFF),
      tertiary: Color(0xFF001d31),
      error: Color(0xFFba1a1a),
      surface: Color(0xFFf7f9fc), // Light Gray background[cite: 19]
      onSurface: Color(0xFF191c1e),
    ),
    // Tipografía basada en Inter[cite: 19]
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontFamily: 'Inter', fontSize: 40, fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400),
      labelSmall: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w500),
    ),
    // Formas: Standard 16px (lg), Containers 24px (xl)[cite: 19]
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    ),
    // Extensión de tema para drip_ui
    extensions: [
      DripThemeExtension(
        primaryColor: const Color(0xFF000666), // Deep Navy Blue - Coincide con primary
        backgroundColor: const Color(0xFFF7F9FC), // Light Gray background
        inputBackground: const Color(0xFFFFFFFF), // White input fields
        labelColor: const Color(0xFF191c1e), // Dark text for labels
        hintColor: const Color(0xFF999999), // Gray hint text
      ),
    ],
  );

  // --- CONFIGURACIÓN DARK MODE (Nocturnal Professional) ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3f51b5), // Luminous Indigo
      onPrimary: Color(0xFF08218a),
      secondary: Color(0xFF71d7cd), // Desaturated Mint
      onSecondary: Color(0xFF003733),
      surface: Color(0xFF131313), // Near-black ink[cite: 20]
      onSurface: Color(0xFFe5e2e1),
      error: Color(0xFFffb4ab),
    ),
    // Tipografía híbrida: Hanken Grotesk, Inter, JetBrains Mono[cite: 20]
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontFamily: 'Hanken Grotesk', fontSize: 32, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400),
      labelMedium: TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.w500),
    ),
    // Formas: Base 8px, Medium 16px, Large 24px[cite: 20]
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    // Extensión de tema para drip_ui
    extensions: [
      DripThemeExtension(
        primaryColor: const Color(0xFF3f51b5), // Luminous Indigo - Coincide con primary
        backgroundColor: const Color(0xFF131313), // Near-black ink
        inputBackground: const Color(0xFF1a1a2e), // Dark input fields
        labelColor: const Color(0xFFe5e2e1), // Light text for labels
        hintColor: const Color(0xFF888888), // Gray hint text
      ),
    ],
  );
}