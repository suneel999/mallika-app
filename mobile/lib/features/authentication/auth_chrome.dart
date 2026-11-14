import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

/// Navy of the hospital logo. Sign-in screens use it with the theme blue and
/// the amber accent.
const authNavy = Color(0xFF0C1B5B);
const authNavyLight = Color(0xFF1D3A8F);
const authInk = Color(0xFF1A2744);
const authMuted = Color(0xFF64748B);
const authLink = MallikaColors.secondary;

class AuthGradientButton extends StatelessWidget {
  const AuthGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x400C1B5B),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onPressed,
          child: Ink(
            height: 54,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [authNavy, authNavyLight]),
            ),
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthLogoHeader extends StatelessWidget {
  const AuthLogoHeader({super.key, this.tall = true});

  final bool tall;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final height = tall ? MediaQuery.sizeOf(context).height * 0.40 : 168.0;
    return SizedBox(
      height: height + (tall ? 0 : top),
      width: double.infinity,
      child: CustomPaint(
        painter: _LoginWavePainter(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, top + 12, 28, tall ? 56 : 28),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: tall ? 22 : 14,
                vertical: tall ? 14 : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(tall ? 24 : 16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/home/mallika_logo.png',
                height: tall ? 104 : 56,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact navy header for the registration and profile forms.
class AuthFormHeader extends StatelessWidget {
  const AuthFormHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, top + 14, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MallikaColors.headerStart,
            authNavy,
            MallikaColors.headerEnd,
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        border: Border(
          bottom: BorderSide(color: MallikaColors.accent, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null) ...[
                IconButton(
                  onPressed: onBack,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0x26FFFFFF),
                  ),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const Spacer(),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(
                  'assets/home/mallika_logo.png',
                  height: 44,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: MallikaColors.primaryFixed,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Navy wave with a thin amber edge under it.
class _LoginWavePainter extends CustomPainter {
  Path _wave(Size size, double drop) {
    final h = size.height - 8 + drop;
    final path = Path()..lineTo(0, h * 0.74);
    path.cubicTo(
      size.width * 0.20,
      h * 0.60,
      size.width * 0.40,
      h * 1.00,
      size.width * 0.66,
      h * 0.82,
    );
    path.cubicTo(
      size.width * 0.84,
      h * 0.69,
      size.width * 0.93,
      h * 0.90,
      size.width,
      h * 0.96,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(_wave(size, 8), Paint()..color = MallikaColors.accent);
    final navy = _wave(size, 0);
    canvas.drawPath(
      navy,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MallikaColors.headerStart,
            authNavy,
            MallikaColors.headerEnd,
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.save();
    canvas.clipPath(navy);
    final ring = Paint()..color = const Color(0x12FFFFFF);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.08), 96, ring);
    canvas.drawCircle(Offset(size.width * 0.04, size.height * 0.52), 64, ring);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AuthLabeledField extends StatelessWidget {
  const AuthLabeledField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: authInk,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

InputDecoration authInputDecoration(String hint) {
  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: Color(0xFF9AA5B8),
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: MallikaColors.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    border: border(MallikaColors.secondaryFixed),
    enabledBorder: border(MallikaColors.secondaryFixed),
    focusedBorder: border(authNavy, 1.6),
  );
}

class AuthMobileField extends StatelessWidget {
  const AuthMobileField({
    super.key,
    required this.controller,
    this.readOnly = false,
    this.onChanged,
    this.hint = 'Enter Mobile Number',
  });

  final TextEditingController controller;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('mobile-number'),
      controller: controller,
      readOnly: readOnly,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      onChanged: onChanged,
      style: const TextStyle(
        color: authInk,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
      decoration: authInputDecoration(hint).copyWith(
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_iphone, size: 20, color: authNavy),
              SizedBox(width: 6),
              Text(
                '+91',
                style: TextStyle(
                  color: authNavy,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 10),
              SizedBox(
                height: 22,
                child: VerticalDivider(
                  width: 1,
                  color: MallikaColors.secondaryFixed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One quiet line under the button. There is no box to tick.
class AuthConsentNote extends StatelessWidget {
  const AuthConsentNote({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'By continuing, you agree to the Privacy Policy and Terms of Service of Mallika Hospitals.',
      textAlign: TextAlign.center,
      style: TextStyle(color: authMuted, fontSize: 12, height: 1.4),
    );
  }
}

const authTitles = <String>['Mr', 'Mrs', 'Ms', 'Dr'];

String authFullName({
  required String title,
  required String first,
  required String last,
}) {
  return [
    title.trim(),
    first.trim(),
    last.trim(),
  ].where((part) => part.isNotEmpty).join(' ');
}
