import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/phone.dart';
import '../../core/session/session_controller.dart';
import '../authentication/auth_chrome.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _mobile = TextEditingController();
  String _title = '';
  var _agreed = false;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _mobile.text = nationalDigits(widget.session.account?.mobileNumber ?? '');
  }

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
    if (!_agreed) {
      setState(() => _error = 'Agree to the terms to continue.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.completeProfile(
        fullName: name,
        preferredLanguage: widget.session.language,
      );
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
            title: 'Complete your profile',
            subtitle:
                'Tell us your name so the hospital knows who is visiting.',
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
                    key: const Key('profile-full-name'),
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
                  label: 'Mobile Number',
                  child: AuthMobileField(controller: _mobile, readOnly: true),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(color: MallikaColors.error),
                  ),
                ],
                const SizedBox(height: 16),
                AuthAgreeRow(
                  checked: _agreed,
                  onChanged: (value) => setState(() => _agreed = value),
                ),
                const SizedBox(height: 18),
                AuthGradientButton(
                  label: 'Save and continue',
                  busy: _busy,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
