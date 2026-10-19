import 'package:flutter/material.dart';

/// Colours taken from the Stitch screen "Home (Enhanced Blue Header)".
abstract final class MallikaColors {
  static const Color primary = Color(0xFF002743);
  static const Color primaryContainer = Color(0xFF0A3D62);
  static const Color headerStart = Color(0xFF071D49);
  static const Color headerMid = Color(0xFF0A2E66);
  static const Color headerEnd = Color(0xFF0D3B75);
  static const Color secondary = Color(0xFF005DB7);
  static const Color accent = Color(0xFFFBBF24);
  static const Color background = Color(0xFFF7FAFE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF181C1F);
  static const Color onSurfaceVariant = Color(0xFF42474E);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color secondaryFixed = Color(0xFFD6E3FF);
  static const Color primaryFixed = Color(0xFFCFE5FF);
}

ThemeData buildMallikaTheme() {
  const jakarta = 'Plus Jakarta Sans';
  final colorScheme = ColorScheme.fromSeed(
    seedColor: MallikaColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: MallikaColors.primary,
    onPrimary: Colors.white,
    primaryContainer: MallikaColors.primaryContainer,
    secondary: MallikaColors.secondary,
    onSecondary: Colors.white,
    surface: MallikaColors.background,
    error: MallikaColors.error,
    errorContainer: MallikaColors.errorContainer,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: MallikaColors.background,
    fontFamily: 'Inter',
  );

  return base.copyWith(
    textTheme: base.textTheme
        .apply(
          bodyColor: MallikaColors.onSurface,
          displayColor: MallikaColors.primary,
        )
        .copyWith(
          headlineSmall: const TextStyle(
            fontFamily: jakarta,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: MallikaColors.primary,
            height: 1.3,
          ),
          headlineMedium: const TextStyle(
            fontFamily: jakarta,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.25,
          ),
        ),
  );
}
