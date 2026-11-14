import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/auth_api.dart';
import '../../core/session/session_controller.dart';
import 'auth_chrome.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({
    super.key,
    required this.session,
    required this.onLogin,
    required this.onSent,
  });

  final SessionController session;
  final VoidCallback onLogin;
  final ValueChanged<OtpRequest> onSent;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _mobile = TextEditingController();
  String _title = '';
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = authFullName(
      title: _title,
      first: _first.text,
      last: _last.text,
    );
    if (_first.text.trim().length < 2) {
      setState(() => _error = 'Enter your full name.');
      return;
    }
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
      widget.session.pendingProfileName = name;
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
          AuthFormHeader(
            title: 'Create your account',
            subtitle: 'Register once to request visits at Mallika Hospitals.',
            onBack: _busy ? null : widget.onLogin,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              children: [
                AuthLabeledField(
                  label: 'Select title',
                  child: DropdownButtonFormField<String>(
                    initialValue: _title.isEmpty ? null : _title,
                    hint: const Text('Select title'),
                    decoration: authInputDecoration(''),
                    items: [
                      for (final title in authTitles)
                        DropdownMenuItem(value: title, child: Text(title)),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) => setState(() => _title = value ?? ''),
                  ),
                ),
                const SizedBox(height: 14),
                AuthLabeledField(
                  label: 'First Name',
                  child: TextField(
                    key: const Key('profile-first-name'),
                    controller: _first,
                    textCapitalization: TextCapitalization.words,
                    decoration: authInputDecoration('Enter First Name'),
                  ),
                ),
                const SizedBox(height: 14),
                AuthLabeledField(
                  label: 'Last Name',
                  child: TextField(
                    controller: _last,
                    textCapitalization: TextCapitalization.words,
                    decoration: authInputDecoration('Enter Last Name'),
                  ),
                ),
                const SizedBox(height: 14),
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
                    style: const TextStyle(color: MallikaColors.error),
                  ),
                ],
                const SizedBox(height: 18),
                AuthGradientButton(
                  label: 'Register',
                  busy: _busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 12),
                const AuthConsentNote(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: authMuted, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: _busy ? null : widget.onLogin,
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: authLink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
