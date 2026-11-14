import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/phone.dart';
import '../../core/session/session_controller.dart';
import '../bookings/booking_screens.dart';
import '../shared/mallika_widgets.dart';
import 'home_content.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.session,
    this.onOpenProfile,
    this.onOpenBookings,
  });

  final SessionController session;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenBookings;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: MallikaColors.background,
        body: SingleChildScrollView(
          child: Stack(
            children: [
              // Navy band behind the greeting and the top half of the banner.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: top + 196,
                child: const _HeaderBand(),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, top + 14, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GreetingBar(
                      session: session,
                      onOpenProfile: onOpenProfile,
                    ),
                    const SizedBox(height: 16),
                    _ConsultationBanner(
                      onTap: () =>
                          _openRequest(context, session, consultation: true),
                    ),
                    if (onOpenBookings != null) ...[
                      const SizedBox(height: 14),
                      _AppointmentsRow(onTap: onOpenBookings!),
                    ],
                    const SizedBox(height: 22),
                    const Text(
                      'Services',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: MallikaColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ServiceGrid(session: session),
                    const SizedBox(height: 18),
                    const _EmergencyStrip(),
                    const SizedBox(height: 12),
                    const _CampusCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBand extends StatelessWidget {
  const _HeaderBand();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MallikaColors.headerStart,
              MallikaColors.primary,
              MallikaColors.headerEnd,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -50,
              child: _ring(170, const Color(0x14FFFFFF)),
            ),
            Positioned(
              left: -60,
              bottom: -90,
              child: _ring(190, const Color(0x0FFFFFFF)),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 3,
              child: ColoredBox(color: MallikaColors.accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _GreetingBar extends StatelessWidget {
  const _GreetingBar({required this.session, this.onOpenProfile});

  final SessionController session;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final first = givenName(session.profile?.fullName ?? '');
    final initial = first.isEmpty ? 'H' : first[0].toUpperCase();
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: MallikaColors.accent, width: 2),
          ),
          child: Text(
            initial,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: MallikaColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                first.isEmpty ? 'Hi' : 'Hi $first',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'How can we help you today?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: MallikaColors.primaryFixed,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          button: true,
          label: 'Profile',
          child: Material(
            color: const Color(0x26FFFFFF),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onOpenProfile,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.person, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConsultationBanner extends StatelessWidget {
  const _ConsultationBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330C1B5B),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Semantics(
        button: true,
        label: 'Book Your Consultation',
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                'assets/home/banner_consultation.jpg',
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentsRow extends StatelessWidget {
  const _AppointmentsRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Your appointments',
      excludeSemantics: true,
      child: MallikaCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: const Row(
          children: [
            IconTile(
              icon: Icons.event_note_rounded,
              color: Colors.white,
              background: MallikaColors.primary,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your appointments',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: MallikaColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Track requests and confirmed visits',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: MallikaColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.chevron_right, color: MallikaColors.muted),
          ],
        ),
      ),
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    const columns = 2;
    const gap = 12.0;
    final rows = <Widget>[];
    for (var index = 0; index < clinicalCards.length; index += columns) {
      final rowCards = clinicalCards.skip(index).take(columns).toList();
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : gap),
          // Both cards in a row are as tall as the taller one.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var column = 0; column < rowCards.length; column++) ...[
                  if (column > 0) const SizedBox(width: gap),
                  Expanded(
                    child: _ServiceCard(
                      card: rowCards[column],
                      onTap: () =>
                          _tapService(context, session, rowCards[column]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.card, required this.onTap});

  final ClinicalCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final soon = card.tap == HomeTap.soon;
    final photo = card.photo;
    return Semantics(
      button: true,
      label: card.title,
      excludeSemantics: true,
      child: MallikaCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(
                  icon: card.icon,
                  size: 46,
                  color: Colors.white,
                  background: soon
                      ? card.color.withValues(alpha: 0.45)
                      : card.color,
                ),
                if (photo != null) ...[
                  const SizedBox(width: 8),
                  // The doctor's face, beside the icon.
                  Container(
                    width: 50,
                    height: 50,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: MallikaColors.accent, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        photo,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ],
                // Whatever is on the right shrinks before it can push the row too wide.
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: soon
                        ? const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: StatusPill(
                              label: 'Coming soon',
                              color: Color(0xFF9A5B00),
                              background: Color(0xFFFFF3D6),
                            ),
                          )
                        : photo != null
                        ? const SizedBox.shrink()
                        : const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Color(0xFF9AA5B8),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              card.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: soon ? MallikaColors.muted : MallikaColors.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              card.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: MallikaColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyStrip extends StatelessWidget {
  const _EmergencyStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const IconTile(
            icon: Icons.emergency_rounded,
            color: Colors.white,
            background: Color(0xFFD92D20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '24/7 Emergency & Trauma',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Color(0xFFB42318),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ambulance and ICU on wheels',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Color(0xFFB42318), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => _open(context, Uri.parse(emergencyPhoneUri)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD92D20),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.call, size: 15),
            label: const Text(
              'SOS Call',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampusCard extends StatelessWidget {
  const _CampusCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open in Google Maps',
      excludeSemantics: true,
      child: MallikaCard(
        onTap: () => _open(context, Uri.parse(hospitalMapsUri)),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const IconTile(
              icon: Icons.location_on,
              color: Colors.white,
              background: MallikaColors.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mallika Hospitals',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: MallikaColors.ink,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Open in Google Maps',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: MallikaColors.secondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/home/photo_campus.png',
                width: 76,
                height: 54,
                fit: BoxFit.cover,
                alignment: Alignment.centerLeft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _tapService(
  BuildContext context,
  SessionController session,
  ClinicalCard card,
) {
  switch (card.tap) {
    case HomeTap.book:
      _openRequest(context, session, consultation: true);
    case HomeTap.service:
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BookingRequestScreen(
            session: session,
            serviceName: card.serviceName,
          ),
        ),
      );
    case HomeTap.soon:
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${card.title} booking is coming soon. Call the hospital for now.',
            ),
          ),
        );
    case HomeTap.call:
      _open(context, Uri.parse(emergencyPhoneUri));
    case HomeTap.map:
      _open(context, Uri.parse(hospitalMapsUri));
  }
}

void _openRequest(
  BuildContext context,
  SessionController session, {
  bool consultation = false,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          BookingRequestScreen(session: session, consultation: consultation),
    ),
  );
}

Future<void> _open(BuildContext context, Uri uri) async {
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open that link on this device.')),
    );
  }
}
