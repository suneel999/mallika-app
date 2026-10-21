import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/auth_api.dart';
import '../../core/phone.dart';
import '../../core/session/session_controller.dart';
import 'family_member_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.session});

  final SessionController session;

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

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Scaffold(
      backgroundColor: MallikaColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: MallikaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final people = session.profiles.isEmpty && session.profile != null
              ? [session.profile!]
              : session.profiles;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: MallikaColors.error)),
                const SizedBox(height: 12),
              ],
              for (final person in people) ...[
                _PersonCard(
                  person: person,
                  onEdit: person.relationship == 'self'
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => FamilyMemberScreen(session: session, person: person),
                            ),
                          );
                        },
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FamilyMemberScreen(session: session),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add family member'),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _busy ? null : _logout,
                child: Text(_busy ? 'Signing out...' : 'Log out'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person, this.onEdit});

  final PatientProfile person;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final label = person.relationship == 'self'
        ? 'You'
        : (familyRelationships[person.relationship] ?? person.relationship);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            person.fullName,
            style: const TextStyle(
              color: MallikaColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: MallikaColors.secondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Patient number ${person.patientNumber}'),
          const SizedBox(height: 4),
          Text(formatIndianMobile(person.mobileNumber)),
        ],
      ),
        ),
      ),
    );
  }
}
