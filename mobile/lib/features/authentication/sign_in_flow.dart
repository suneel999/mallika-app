import 'package:flutter/material.dart';

import '../../core/api/auth_api.dart';
import '../../core/session/session_controller.dart';
import 'mobile_number_screen.dart';
import 'otp_screen.dart';
import 'registration_screen.dart';

enum _Step { login, register, otp }

class SignInFlow extends StatefulWidget {
  const SignInFlow({super.key, required this.session});

  final SessionController session;

  @override
  State<SignInFlow> createState() => _SignInFlowState();
}

class _SignInFlowState extends State<SignInFlow> {
  _Step _step = _Step.login;
  _Step _otpFrom = _Step.login;
  OtpRequest? _otp;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    switch (_step) {
      case _Step.login:
        return MobileNumberScreen(
          session: session,
          onRegister: () => setState(() => _step = _Step.register),
          onSent: (otp) => setState(() {
            _otp = otp;
            _otpFrom = _Step.login;
            _step = _Step.otp;
          }),
        );
      case _Step.register:
        return RegistrationScreen(
          session: session,
          onLogin: () => setState(() => _step = _Step.login),
          onSent: (otp) => setState(() {
            _otp = otp;
            _otpFrom = _Step.register;
            _step = _Step.otp;
          }),
        );
      case _Step.otp:
        final otp = _otp!;
        return OtpScreen(
          session: session,
          mobileNumber: otp.mobileNumber,
          resendAfter: otp.resendAfter,
          onBack: () => setState(() => _step = _otpFrom),
        );
    }
  }
}
