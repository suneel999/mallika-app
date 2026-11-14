import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/auth_api.dart';
import '../../core/config.dart';
import '../../core/session/session_controller.dart';
import 'auth_chrome.dart';

class MobileNumberScreen extends StatefulWidget {
  const MobileNumberScreen({
    super.key,
    required this.session,
    required this.onRegister,
    required this.onSent,
  });

  final SessionController session;
  final VoidCallback onRegister;
  final ValueChanged<OtpRequest> onSent;

  @override
  State<MobileNumberScreen> createState() => _MobileNumberScreenState();
}

class _MobileNumberScreenState extends State<MobileNumberScreen> {
  final _mobile = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final digits = _mobile.text.trim();
    if (digits.length != 10) {
      setState(() => _error = 'Enter your 10-digit WhatsApp number.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      widget.session.pendingProfileName = null;
      final request = await widget.session.requestOtp(digits);
      if (!mounted) {
        return;
      }
      widget.onSent(request);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AuthLogoHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
              children: [
                const Text(
                  'Patient Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: authNavy,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in with your WhatsApp number',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: authMuted, fontSize: 14),
                ),
                const SizedBox(height: 26),
                AuthLabeledField(
                  label: 'WhatsApp Number',
                  child: AuthMobileField(
                    controller: _mobile,
                    hint: 'Enter WhatsApp number',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFBA1A1A)),
                  ),
                ],
                if (AppConfig.demoOtp.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Demo sign-in. The code is ${AppConfig.demoOtp}.',
                    style: const TextStyle(color: authMuted, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'We send a 6-digit code to this number on WhatsApp.',
                  style: TextStyle(color: authMuted, fontSize: 12.5),
                ),
                const SizedBox(height: 20),
                AuthGradientButton(
                  label: 'Login',
                  busy: _busy,
                  onPressed: _send,
                ),
                const SizedBox(height: 12),
                const AuthConsentNote(),
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : widget.onRegister,
                    child: const Text(
                      'New Registration?',
                      style: TextStyle(
                        color: authLink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
