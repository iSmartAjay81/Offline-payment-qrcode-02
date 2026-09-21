import 'dart:ui';
import 'package:flutter/material.dart';

enum LampStyle {
  deskLamp,     // Classic Articulated Architect Desk Lamp (Brushed Brass / Emerald)
  vintageBulb,  // Exposed Vintage Edison Filament Bulb (Amber glass / warm filament)
  lantern,      // Industrial Brass Lantern (Beveled glass panels / bronze frame)
}

class PbrTheme {
  // Photorealistic Metallic and Tungsten Colors
  static const Color darkRoomBase = Color(0xFF0D0F12);
  static const Color darkRoomSurface = Color(0xFF161A20);
  static const Color deskWoodDark = Color(0xFF1E1A16);
  static const Color deskWoodLight = Color(0xFFE8DCCB);

  // Metal highlights
  static const Color brassGold = Color(0xFFD4AF37);
  static const Color brassBurnished = Color(0xFFA67C1E);
  static const Color bronzeDark = Color(0xFF5C4033);
  static const Color brushedAluminum = Color(0xFFC0C5CD);
  static const Color steelHighlight = Color(0xFFE2E8F0);

  // Tungsten Light Glows
  static const Color tungstenWarm = Color(0xFFFFB347);
  static const Color tungstenHot = Color(0xFFFFF4D4);
  static const Color tungstenCore = Color(0xFFFFFFFF);
  static const Color lightConeAmbient = Color(0x33FFA938);
  static const Color lightConeIntense = Color(0x66FFC107);

  // Security & Alert Accents
  static const Color alertGold = Color(0xFFFFB703);
  static const Color scamRed = Color(0xFFE63946);
  static const Color successEmerald = Color(0xFF2A9D8F);

  // Glassmorphic Container Decoration
  static BoxDecoration glassDecoration({
    required bool isDark,
    double opacity = 0.65,
    BorderRadius? borderRadius,
    Color? customColor,
    bool isLit = false,
  }) {
    final baseColor = customColor ??
        (isDark ? const Color(0xFF181C24) : const Color(0xFFFFFFFF));

    final radius = borderRadius ?? BorderRadius.circular(20);

    return BoxDecoration(
      borderRadius: radius,
      color: baseColor.withOpacity(opacity),
      border: Border.all(
        color: isLit
            ? tungstenWarm.withOpacity(0.45)
            : (isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08)),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: isLit
              ? tungstenWarm.withOpacity(0.18)
              : (isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.08)),
          blurRadius: isLit ? 30 : 18,
          spreadRadius: isLit ? 2 : 0,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // PBR Metallic Button Decoration
  static BoxDecoration metallicButton({
    bool isPrimary = true,
    bool isPressed = false,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isPrimary
            ? [
                brassGold,
                brassBurnished,
                const Color(0xFF805A12),
              ]
            : [
                const Color(0xFF2A2E39),
                const Color(0xFF1A1D24),
              ],
        stops: const [0.0, 0.5, 1.0],
      ),
      border: Border.all(
        color: isPrimary ? tungstenHot.withOpacity(0.8) : Colors.white.withOpacity(0.15),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: isPrimary
              ? brassGold.withOpacity(isPressed ? 0.2 : 0.4)
              : Colors.black.withOpacity(0.3),
          blurRadius: isPressed ? 4 : 12,
          offset: isPressed ? const Offset(0, 2) : const Offset(0, 6),
        ),
      ],
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkRoomBase,
      colorScheme: const ColorScheme.dark(
        primary: brassGold,
        onPrimary: Colors.black,
        secondary: tungstenWarm,
        surface: darkRoomSurface,
        onSurface: Colors.white,
        error: scamRed,
      ),
      cardColor: darkRoomSurface,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      colorScheme: const ColorScheme.light(
        primary: brassBurnished,
        onPrimary: Colors.white,
        secondary: brassGold,
        surface: Colors.white,
        onSurface: Color(0xFF1F242E),
        error: scamRed,
      ),
      cardColor: Colors.white,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
