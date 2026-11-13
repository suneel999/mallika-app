import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/config.dart';
import '../../core/session/session_controller.dart';
import 'auth_chrome.dart';

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
    if (AppConfig.demoOtp.isNotEmpty) {
      _code.text = AppConfig.demoOtp;
    }
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

  String get _sentTo {
    final digits = widget.mobileNumber.replaceAll(RegExp('[^0-9]'), '');
    if (digits.length < 4) {
      return 'your mobile';
    }
    return 'the number ending ${digits.substring(digits.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final digits = _code.text;
    final clock =
        '${(_remaining ~/ 60).toString().padLeft(2, '0')}:${(_remaining % 60).toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: widget.onBack,
                style: IconButton.styleFrom(
                  backgroundColor: MallikaColors.background,
                  side: const BorderSide(color: MallikaColors.secondaryFixed),
                ),
                icon: const Icon(Icons.arrow_back, color: authNavy, size: 22),
              ),
            ),
            const SizedBox(height: 28),
            const Center(child: _CodeBadge()),
            const SizedBox(height: 24),
            const Text(
              'Enter Verification Code',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: authNavy,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConfig.demoOtp.isEmpty
                  ? 'Code sent to $_sentTo'
                  : 'Demo code ${AppConfig.demoOtp}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: authMuted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 10.0;
                final box = ((constraints.maxWidth - gap * 5) / 6).clamp(
                  40.0,
                  54.0,
                );
                final rowWidth = box * 6 + gap * 5;
                return Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: rowWidth,
                    height: box * 1.16,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          children: List.generate(6, (index) {
                            final filled = index < digits.length;
                            final active = index == digits.length;
                            return Container(
                              width: box,
                              height: box * 1.16,
                              margin: EdgeInsets.only(
                                left: index == 0 ? 0 : gap,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: filled
                                    ? Colors.white
                                    : MallikaColors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: active || filled
                                      ? authNavy
                                      : MallikaColors.secondaryFixed,
                                  width: active ? 1.8 : 1.2,
                                ),
                              ),
                              child: Text(
                                filled ? digits[index] : '',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: authNavy,
                                ),
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
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
                  ),
                );
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: MallikaColors.error),
              ),
            ],
            const SizedBox(height: 24),
            AuthGradientButton(
              label: 'Verify',
              busy: _busy,
              onPressed: _verify,
            ),
            const SizedBox(height: 14),
            if (_remaining == 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Did not get the code?',
                    style: TextStyle(color: authMuted, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _resend,
                    child: const Text(
                      'Resend OTP',
                      style: TextStyle(
                        color: authLink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(color: authMuted, fontSize: 14),
                    children: [
                      const TextSpan(text: 'Resend code in '),
                      TextSpan(
                        text: clock,
                        style: const TextStyle(
                          color: authNavy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Navy badge with an amber ring, in place of the drawn lock artwork.
class _CodeBadge extends StatelessWidget {
  const _CodeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE8F0FE),
      ),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [authNavy, authNavyLight],
          ),
          border: Border.all(color: MallikaColors.accent, width: 3),
        ),
        child: const Icon(
          Icons.verified_user_rounded,
          color: Colors.white,
          size: 38,
        ),
      ),
    );
  }
}
