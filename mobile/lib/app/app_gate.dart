import 'package:flutter/material.dart';

import '../core/session/session_controller.dart';
import '../features/authentication/sign_in_flow.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/session_retry_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/profile_setup_screen.dart';

class AppGate extends StatelessWidget {
  const AppGate({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        switch (session.gate) {
          case Gate.booting:
            return const SplashScreen();
          case Gate.unreachable:
            return SessionRetryScreen(session: session);
          case Gate.signedOut:
            return SignInFlow(session: session);
          case Gate.needsProfile:
            return ProfileSetupScreen(session: session);
          case Gate.ready:
            return HomeScreen(
              session: session,
              onOpenProfile: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfileScreen(session: session),
                  ),
                );
              },
            );
        }
      },
    );
  }
}
