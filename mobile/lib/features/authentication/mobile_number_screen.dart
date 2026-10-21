import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/auth_api.dart';
import '../../core/session/session_controller.dart';
import '../shared/mallika_widgets.dart';

class MobileNumberScreen extends StatefulWidget {
  const MobileNumberScreen({
    super.key,
    required this.session,
    required this.onBack,
    required this.onSent,
  });

  final SessionController session;
  final VoidCallback onBack;
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
      setState(() => _error = 'Enter a 10-digit Indian mobile number.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
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
      backgroundColor: MallikaColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            MallikaBackBar(title: 'Mallika Hospitals', onBack: widget.onBack),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined, color: MallikaColors.secondary, size: 16),
                SizedBox(width: 6),
                Text('NABH Accredited', style: TextStyle(color: MallikaColors.secondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MallikaColors.primary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const Text(
              'తిరిగి స్వాగతం',
              textAlign: TextAlign.center,
              style: TextStyle(color: MallikaColors.secondary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your mobile number to access appointments, lab records, and emergency consultations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: MallikaColors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 24),
            const Text('Mobile Number *', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              key: const Key('mobile-number'),
              controller: _mobile,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
              decoration: InputDecoration(
                hintText: '10-Digit Indian Mobile',
                prefixText: '+91  ',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: MallikaColors.error)),
            ],
            const SizedBox(height: 12),
            const Text(
              'We’ll send you a 6-digit one-time password (OTP) via SMS to verify your identity.',
              style: TextStyle(color: MallikaColors.onSurfaceVariant, fontSize: 13),
            ),
            const Text(
              'మీ మొబైల్ నంబరుకు ఓటీపీ (OTP) పంపబడుతుంది.',
              style: TextStyle(color: MallikaColors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 20),
            MallikaButton(label: 'Send OTP', busy: _busy, onPressed: _send),
            const SizedBox(height: 24),
            const Text(
              'Patient Data Protected',
              style: TextStyle(fontWeight: FontWeight.w600, color: MallikaColors.primary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your medical records and personal info are encrypted under strict clinical guidelines.',
              style: TextStyle(color: MallikaColors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('The hospital desk number is not confirmed yet.')),
                );
              },
              icon: const Icon(Icons.call),
              label: const Text('Call Desk'),
            ),
          ],
        ),
      ),
    );
  }
}
