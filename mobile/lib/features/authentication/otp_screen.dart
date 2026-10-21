import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/phone.dart';
import '../../core/session/session_controller.dart';
import '../shared/mallika_widgets.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.session,
    required this.mobileNumber,
    required this.resendAfter,
    required this.onBack,
  });

  final SessionController session;
  final String mobileNumber;
  final int resendAfter;
  final VoidCallback onBack;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  Timer? _timer;
  late int _remaining;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _remaining = widget.resendAfter;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remaining <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _remaining -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_code.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.verifyOtp(_code.text.trim());
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

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final request = await widget.session.requestOtp(widget.mobileNumber);
      if (!mounted) {
        return;
      }
      setState(() => _remaining = request.resendAfter);
      _startTimer();
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
    final digits = _code.text;
    final clock = '${(_remaining ~/ 60).toString().padLeft(2, '0')}:${(_remaining % 60).toString().padLeft(2, '0')}s';
    return Scaffold(
      backgroundColor: MallikaColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            MallikaBackBar(title: 'OTP Verification', onBack: widget.onBack),
            const SizedBox(height: 12),
            const Text(
              'Verify Your Mobile',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MallikaColors.primary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const Text(
              'మొబైల్ నంబర్ ధృవీకరణ',
              textAlign: TextAlign.center,
              style: TextStyle(color: MallikaColors.secondary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              maskIndianMobile(widget.mobileNumber),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter 6-digit verification code',
              textAlign: TextAlign.center,
              style: TextStyle(color: MallikaColors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    final filled = index < digits.length;
                    return Container(
                      width: 46,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: filled ? MallikaColors.secondary : const Color(0xFFC2C7CF),
                        ),
                      ),
                      child: Text(
                        filled ? digits[index] : '',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    );
                  }),
                ),
                TextField(
                  key: const Key('otp-code'),
                  controller: _code,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  style: const TextStyle(color: Colors.transparent),
                  cursorColor: Colors.transparent,
                  showCursor: false,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: MallikaColors.error)),
            ],
            const SizedBox(height: 16),
            Text(
              _remaining > 0 ? "Didn't receive code? $clock" : "Didn't receive code?",
              textAlign: TextAlign.center,
              style: const TextStyle(color: MallikaColors.onSurfaceVariant),
            ),
            TextButton(
              onPressed: _remaining == 0 && !_busy ? _resend : null,
              child: const Text('Resend OTP'),
            ),
            MallikaButton(label: 'Verify & Continue', busy: _busy, onPressed: _verify),
            const SizedBox(height: 20),
            const Text(
              'Do not share your OTP with anyone. Mallika Hospitals staff will never ask for your verification code over call or message.',
              style: TextStyle(color: MallikaColors.onSurfaceVariant, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
