import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Shown while the app checks for a saved session. The hospital name and the
/// Telugu line are part of the logo artwork.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MallikaColors.headerStart,
              MallikaColors.primary,
              MallikaColors.headerEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const Spacer(flex: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: MallikaColors.accent, width: 2),
                  ),
                  child: Image.asset(
                    'assets/home/mallika_logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Care Today • Healthier Tomorrow',
                  style: TextStyle(
                    color: MallikaColors.primaryFixed,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(flex: 3),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: MallikaColors.accent,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Opening your account',
                  style: TextStyle(
                    color: MallikaColors.primaryFixed,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
