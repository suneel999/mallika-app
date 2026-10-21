import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../shared/mallika_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.language,
    required this.onLanguage,
    required this.onContinue,
  });

  final String language;
  final ValueChanged<String> onLanguage;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MallikaColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: const Color(0xFFE5E8EC),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onLanguage(language == 'en' ? 'te' : 'en'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.translate, size: 16, color: MallikaColors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          'English',
                          style: TextStyle(
                            color: MallikaColors.secondary,
                            fontWeight: language == 'en' ? FontWeight.w700 : FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                        const Text(' | ', style: TextStyle(color: MallikaColors.secondary, fontSize: 12)),
                        Text(
                          'తెలుగు',
                          style: TextStyle(
                            color: MallikaColors.secondary,
                            fontWeight: language == 'te' ? FontWeight.w700 : FontWeight.w400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Icon(Icons.local_hospital, color: MallikaColors.primary, size: 48),
            const SizedBox(height: 8),
            const Text(
              'Welcome to Mallika Hospitals',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MallikaColors.primary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'మల్లికా హాస్పిటల్స్‌కి స్వాగతం',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MallikaColors.secondary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your healthcare, made simpler.',
              textAlign: TextAlign.center,
              style: TextStyle(color: MallikaColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [MallikaColors.primaryFixed, Color(0xFFF1F4F8)],
                ),
              ),
              child: const Icon(Icons.health_and_safety_outlined, size: 72, color: MallikaColors.primary),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: MallikaColors.primaryFixed,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 14, color: MallikaColors.primary),
                  SizedBox(width: 4),
                  Text('Trusted Healthcare Partner', style: TextStyle(fontSize: 11, color: MallikaColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Care You Can Trust',
              style: TextStyle(
                color: MallikaColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Connect with hospital services, explore consultations and diagnostic tests, and submit appointment requests conveniently from your phone.',
              style: TextStyle(color: MallikaColors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 12),
            const _Benefit(
              icon: Icons.assignment_outlined,
              title: 'Expert Consultations',
              detail: 'Explore doctors and request consultations.',
            ),
            const _Benefit(
              icon: Icons.biotech_outlined,
              title: 'Diagnostic Services',
              detail: 'Discover available tests (Echo, CT scans, Lab).',
            ),
            const _Benefit(
              icon: Icons.event_available_outlined,
              title: 'Easy Appointment Requests',
              detail: 'Submit requests and track their status.',
            ),
            const SizedBox(height: 20),
            MallikaButton(label: 'Get Started', onPressed: onContinue),
            TextButton(
              onPressed: onContinue,
              child: const Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(color: MallikaColors.secondary),
                  children: [
                    TextSpan(
                      text: 'Log in',
                      style: TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(onPressed: () => showPendingPage(context), child: const Text('Privacy Policy')),
                const Text('•', style: TextStyle(color: MallikaColors.onSurfaceVariant)),
                TextButton(onPressed: () => showPendingPage(context), child: const Text('Terms of Use')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: MallikaColors.secondaryFixed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: MallikaColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: MallikaColors.primary)),
                Text(detail, style: const TextStyle(fontSize: 12, color: MallikaColors.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
