import 'package:flutter/material.dart';

/// Brand colours. The navy is the colour of the hospital logo. The blue and
/// amber come from the Stitch screen "Home (Enhanced Blue Header)".
abstract final class MallikaColors {
  static const Color primary = Color(0xFF0C1B5B);
  static const Color primaryContainer = Color(0xFF1D3A8F);
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

  /// Heading and body text on white cards.
  static const Color ink = Color(0xFF0F2744);
  static const Color muted = Color(0xFF64748B);

  /// Card outline and the pale tile behind an icon.
  static const Color outline = Color(0xFFE3EAF5);
  static const Color tint = Color(0xFFE8F0FE);
}

ThemeData buildMallikaTheme() {
  const jakarta = 'Plus Jakarta Sans';
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: MallikaColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: MallikaColors.primary,
        onPrimary: Colors.white,
        primaryContainer: MallikaColors.primaryContainer,
        onPrimaryContainer: Colors.white,
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

  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: MallikaColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: jakarta,
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MallikaColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 48),
        shape: rounded,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MallikaColors.primary,
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: MallikaColors.secondaryFixed),
        shape: rounded,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MallikaColors.secondary,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        fontFamily: jakarta,
        color: MallikaColors.primary,
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Inter',
        color: MallikaColors.onSurfaceVariant,
        fontSize: 15,
        height: 1.4,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: MallikaColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: const TextStyle(
        fontFamily: 'Inter',
        color: Colors.white,
        fontSize: 14,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: MallikaColors.primary,
    ),
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
