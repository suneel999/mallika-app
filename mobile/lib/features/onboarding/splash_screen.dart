import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Stitch splash. The accreditation, encryption, and care lines are design copy
/// and still need hospital confirmation before release.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [MallikaColors.primary, MallikaColors.primaryContainer, MallikaColors.primary],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: MallikaColors.secondaryFixed, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'NABH ACCREDITED • 24/7 CARE',
                        style: TextStyle(
                          color: MallikaColors.primaryFixed,
                          fontSize: 11,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 128,
                  height: 128,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_hospital, color: MallikaColors.primary, size: 64),
                ),
                const SizedBox(height: 24),
                const Text(
                  'MALLIKA HOSPITALS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64A1FF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'ఆపదలో మీ నేస్తం',
                    style: TextStyle(
                      color: MallikaColors.secondaryFixed,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Care Today • Healthier Tomorrow',
                  style: TextStyle(color: MallikaColors.primaryFixed, fontSize: 14),
                ),
                const SizedBox(height: 20),
                const Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    _TrustChip(icon: Icons.local_hospital, label: 'Emergency'),
                    _TrustChip(icon: Icons.monitor_heart_outlined, label: 'Super Speciality'),
                    _TrustChip(icon: Icons.health_and_safety_outlined, label: 'ICU 24/7'),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: MallikaColors.secondaryFixed),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Initializing secure patient portal...',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, color: MallikaColors.primaryFixed, size: 14),
                    SizedBox(width: 6),
                    Text(
                      '256-Bit Encrypted Clinical Gateway',
                      style: TextStyle(color: MallikaColors.primaryFixed, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: MallikaColors.secondaryFixed, size: 16),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: MallikaColors.primaryFixed, fontSize: 11)),
      ],
    );
  }
}

