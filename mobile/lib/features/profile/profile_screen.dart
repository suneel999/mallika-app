import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/auth_api.dart';
import '../../core/phone.dart';
import '../../core/session/session_controller.dart';
import '../shell/patient_shell.dart';
import '../shared/mallika_widgets.dart';
import 'family_member_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.session, this.onOpenHome});

  final SessionController session;
  final VoidCallback? onOpenHome;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.session.account?.id != 'preview') {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      await widget.session.loadProfiles();
      if (mounted) {
        setState(() => _error = null);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    }
  }

  Future<void> _logout() async {
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
    await widget.session.logout();
  }

  void _back() {
    final openHome = widget.onOpenHome;
    if (openHome != null) {
      openHome();
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _deleteAccount() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'The hospital closes patient accounts. This app cannot delete the account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Scaffold(
      backgroundColor: MallikaColors.background,
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final people = session.profiles.isEmpty && session.profile != null
              ? [session.profile!]
              : session.profiles;
          final self = people.cast<PatientProfile?>().firstWhere(
            (person) => person!.relationship == 'self',
            orElse: () => people.isEmpty ? null : people.first,
          );
          final family = [
            for (final person in people)
              if (person.relationship != 'self') person,
          ];
          final name = (self?.fullName ?? session.account?.mobileNumber ?? '')
              .trim();
          final mobile =
              self?.mobileNumber ?? session.account?.mobileNumber ?? '';
          return Column(
            children: [
              _ProfileHeader(
                name: name.isEmpty ? 'Profile' : name,
                patientNumber: self?.patientNumber ?? '',
                onBack: _back,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -28),
                      child: _AccountCard(
                        mobile: mobile.isEmpty
                            ? '-'
                            : formatIndianMobile(mobile),
                        onDelete: _deleteAccount,
                      ),
                    ),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: const TextStyle(color: MallikaColors.error),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SectionLabel('Family members'),
                    const SizedBox(height: 4),
                    const Text(
                      'People saved on your account.',
                      style: TextStyle(
                        color: MallikaColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final person in family) ...[
                      _FamilyRow(
                        person: person,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => FamilyMemberScreen(
                                session: session,
                                person: person,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                FamilyMemberScreen(session: session),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_1, size: 20),
                      label: const Text('Add family member'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _LogoutButton(busy: _busy, onPressed: _logout),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.patientNumber,
    required this.onBack,
  });

  final String name;
  final String patientNumber;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final initial = name.isEmpty ? 'P' : name[0].toUpperCase();
    return ClipPath(
      clipper: _HeaderCurve(),
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
        child: Padding(
          padding: EdgeInsets.fromLTRB(4, top + 4, 16, 56),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: MallikaColors.accent, width: 3),
                ),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: MallikaColors.primary,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (patientNumber.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x26FFFFFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    patientNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCurve extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 36);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 28,
      size.width,
      size.height - 36,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.mobile, required this.onDelete});

  final String mobile;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return MallikaCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.phone_android,
            iconColor: brandNavy,
            iconBackground: MallikaColors.tint,
            title: 'Mobile Number',
            value: mobile,
          ),
          const Divider(height: 1, color: MallikaColors.outline),
          _DetailRow(
            icon: Icons.delete_outline,
            iconColor: const Color(0xFFD92D20),
            iconBackground: const Color(0xFFFFE9EC),
            title: 'Handled by the hospital',
            value: 'Delete Account',
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            IconTile(icon: icon, color: iconColor, background: iconBackground),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: MallikaColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: MallikaColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: MallikaColors.muted),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: const Icon(Icons.logout, size: 18),
      label: Text(busy ? 'Signing out...' : 'Logout'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFD92D20),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFF7C5C0)),
        minimumSize: const Size.fromHeight(50),
      ),
    );
  }
}

class _FamilyRow extends StatelessWidget {
  const _FamilyRow({required this.person, required this.onTap});

  final PatientProfile person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label =
        familyRelationships[person.relationship] ?? person.relationship;
    return MallikaCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const IconTile(icon: Icons.person_outline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: MallikaColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: MallikaColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: MallikaColors.muted),
        ],
      ),
    );
  }
}
