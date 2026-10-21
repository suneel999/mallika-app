import 'package:flutter/material.dart';

import '../../core/api/auth_api.dart';
import '../../core/session/session_controller.dart';
import '../onboarding/welcome_screen.dart';
import 'mobile_number_screen.dart';
import 'otp_screen.dart';

enum _Step { welcome, mobile, otp }

class SignInFlow extends StatefulWidget {
  const SignInFlow({super.key, required this.session});

  final SessionController session;

  @override
  State<SignInFlow> createState() => _SignInFlowState();
}

class _SignInFlowState extends State<SignInFlow> {
  _Step _step = _Step.welcome;
  OtpRequest? _otp;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    switch (_step) {
      case _Step.welcome:
        return WelcomeScreen(
          language: session.language,
          onLanguage: session.setLanguage,
          onContinue: () => setState(() => _step = _Step.mobile),
        );
      case _Step.mobile:
        return MobileNumberScreen(
          session: session,
          onBack: () => setState(() => _step = _Step.welcome),
          onSent: (otp) => setState(() {
            _otp = otp;
            _step = _Step.otp;
          }),
        );
      case _Step.otp:
        final otp = _otp!;
        return OtpScreen(
          session: session,
          mobileNumber: otp.mobileNumber,
          resendAfter: otp.resendAfter,
          onBack: () => setState(() => _step = _Step.mobile),
        );
    }
  }
}
