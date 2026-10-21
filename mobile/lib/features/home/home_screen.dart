import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import 'home_content.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onOpenProfile});

  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MallikaColors.background,
      body: Column(
        children: [
          const _HomeHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: const [
                _HeroBanner(),
                SizedBox(height: 12),
                _OfferRow(),
                SizedBox(height: 16),
                _EmergencyRibbon(),
                SizedBox(height: 20),
                _ServicesSection(),
                SizedBox(height: 20),
                _SpecialistsSection(),
                SizedBox(height: 20),
                _FindHospitalCard(),
                SizedBox(height: 20),
                _TrustBanner(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _HomeBottomNav(onOpenProfile: onOpenProfile),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 8, 8, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MallikaColors.headerStart,
            MallikaColors.headerMid,
            MallikaColors.headerEnd,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _soon(context),
            icon: const Icon(Icons.menu, color: Colors.white),
            tooltip: 'Open Menu',
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MALLIKA HOSPITALS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'ఆపదలో మీ నేస్తం',
                  style: TextStyle(
                    color: MallikaColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: const Color(0xFF051737),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => _soon(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2B589A)),
                ),
                child: const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'EN',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: '  |  ', style: TextStyle(color: Colors.white54)),
                      TextSpan(
                        text: 'తెలుగు',
                        style: TextStyle(
                          color: MallikaColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _soon(context),
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: 'Notifications',
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF061E47), Color(0xFF092E66), Color(0xFF0C397B)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: MallikaColors.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Excellence in Heart Care',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Advanced Cardiac Care for a Healthier Tomorrow',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            'Expert Doctors • Cutting-edge Technology • Compassionate Care',
            style: TextStyle(color: Color(0xFF80A8D3), fontSize: 12),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _soon(context),
            style: FilledButton.styleFrom(
              backgroundColor: MallikaColors.accent,
              foregroundColor: MallikaColors.headerStart,
              minimumSize: const Size(0, 48),
            ),
            icon: const Text(
              'Book Appointment',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            label: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}

class _OfferRow extends StatelessWidget {
  const _OfferRow();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _OfferChip(
            icon: Icons.health_and_safety,
            label: 'Complete Heart Health Checkup @ 40% Off',
            filled: true,
          ),
          SizedBox(width: 8),
          _OfferChip(
            icon: Icons.biotech_outlined,
            label: 'Preventive Blood Screening Packages',
            filled: false,
          ),
        ],
      ),
    );
  }
}

class _OfferChip extends StatelessWidget {
  const _OfferChip({required this.icon, required this.label, required this.filled});

  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: filled ? MallikaColors.secondaryFixed : const Color(0xFFE5E8EC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: filled ? MallikaColors.secondary : MallikaColors.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _EmergencyRibbon extends StatelessWidget {
  const _EmergencyRibbon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MallikaColors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: MallikaColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emergency, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMERGENCY HOTLINE  24x7',
                  style: TextStyle(
                    color: MallikaColors.error,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'ఆపదలో అత్యవసరం: Instant Doctor & ICU',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => _open(context, Uri.parse(emergencyPhoneUri)),
            style: FilledButton.styleFrom(
              backgroundColor: MallikaColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 48),
            ),
            icon: const Icon(Icons.call),
            label: const Text('Call Now'),
          ),
        ],
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Our Medical Services', style: Theme.of(context).textTheme.headlineSmall),
                  const Text(
                    'వైద్య సేవలు • Tap any service for details',
                    style: TextStyle(color: MallikaColors.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${medicalServices.length} Dedicated Wings',
              style: const TextStyle(
                color: MallikaColors.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final service in medicalServices)
                  SizedBox(
                    width: service.urgent ? constraints.maxWidth : cardWidth,
                    child: _ServiceCard(service: service),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final MedicalService service;

  @override
  Widget build(BuildContext context) {
    final urgent = service.urgent;
    return Material(
      color: urgent ? MallikaColors.errorContainer : MallikaColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (service.title == 'Emergency' || service.title == 'Ambulance') {
            _open(context, Uri.parse(emergencyPhoneUri));
            return;
          }
          _soon(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: urgent ? MallikaColors.error : MallikaColors.primaryFixed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      service.icon,
                      color: urgent ? Colors.white : MallikaColors.primary,
                    ),
                  ),
                  if (urgent) ...[
                    const SizedBox(width: 8),
                    const Text(
                      'URGENT',
                      style: TextStyle(
                        color: MallikaColors.error,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                service.title,
                style: TextStyle(
                  color: urgent ? MallikaColors.error : MallikaColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              Text(
                service.subtitle,
                style: const TextStyle(fontSize: 12, color: MallikaColors.onSurfaceVariant),
              ),
              Text(
                service.telugu,
                style: const TextStyle(fontSize: 11, color: Color(0xFF1D496F)),
              ),
              const SizedBox(height: 8),
              Text(
                service.action,
                style: TextStyle(
                  color: urgent ? MallikaColors.error : MallikaColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecialistsSection extends StatelessWidget {
  const _SpecialistsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Specialists', style: Theme.of(context).textTheme.headlineSmall),
        const Text(
          'అనుభవజ్ఞులైన వైద్య బృందం',
          style: TextStyle(color: MallikaColors.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: specialists.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final doctor = specialists[index];
              return Container(
                width: 240,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MallikaColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.availability,
                      style: const TextStyle(
                        color: MallikaColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        color: MallikaColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      doctor.qualification,
                      style: const TextStyle(fontSize: 12, color: MallikaColors.onSurfaceVariant),
                    ),
                    Text(
                      'Experience  ${doctor.experience}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _soon(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: MallikaColors.primary,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Book Consultation'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FindHospitalCard extends StatelessWidget {
  const _FindHospitalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MallikaColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Find Mallika Hospitals', style: Theme.of(context).textTheme.headlineSmall),
          const Text(
            'ఆసుపత్రి చిరునామా మరియు దారి',
            style: TextStyle(color: MallikaColors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mallika Multi-Speciality Campus',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const Text('Opp. Collectorate Road, Near Metro Junction'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => _open(
              context,
              Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(hospitalDirectionsQuery)}',
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: MallikaColors.primaryContainer,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.directions),
            label: const Text('Get Directions'),
          ),
        ],
      ),
    );
  }
}

class _TrustBanner extends StatelessWidget {
  const _TrustBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF071D49), Color(0xFF092B60), Color(0xFF071D49)],
        ),
      ),
      child: const Column(
        children: [
          Text(
            'ఆపదలో మీ నేస్తం',
            style: TextStyle(
              color: MallikaColors.accent,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Always by your side during critical emergencies. Trusted by over 100,000+ families for compassionate healthcare.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({this.onOpenProfile});

  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      backgroundColor: MallikaColors.surface,
      indicatorColor: MallikaColors.secondaryFixed,
      onDestinationSelected: (index) {
        if (index == 3 && onOpenProfile != null) {
          onOpenProfile!();
          return;
        }
        if (index != 0) {
          _soon(context);
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Bookings'),
        NavigationDestination(icon: Icon(Icons.notifications_active_outlined), label: 'Updates'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

void _soon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('This screen is next.')),
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
