import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/session/session_controller.dart';
import '../shared/mallika_widgets.dart';

class SessionRetryScreen extends StatelessWidget {
  const SessionRetryScreen({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MallikaColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: MallikaColors.primary, size: 48),
              const SizedBox(height: 16),
              const Text(
                'The hospital service could not be reached.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: MallikaColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your sign-in is still on this phone. Try again when the connection returns.',
                textAlign: TextAlign.center,
                style: TextStyle(color: MallikaColors.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 24),
              MallikaButton(label: 'Retry', onPressed: session.boot),
            ],
          ),
        ),
      ),
    );
  }
}
