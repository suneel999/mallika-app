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
              const IconTile(icon: Icons.wifi_off_rounded, size: 88),
              const SizedBox(height: 22),
              const Text(
                'The hospital service could not be reached.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: MallikaColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Plus Jakarta Sans',
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your sign-in is still on this phone. Try again when the connection returns.',
                textAlign: TextAlign.center,
                style: TextStyle(color: MallikaColors.muted, height: 1.4),
              ),
              const SizedBox(height: 26),
              MallikaButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: session.boot,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
