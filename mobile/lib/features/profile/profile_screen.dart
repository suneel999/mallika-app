import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/phone.dart';
import '../../core/session/session_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var _busy = false;

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
    final profile = widget.session.profile;
    final account = widget.session.account;
    final language = (profile?.preferredLanguage ?? account?.preferredLanguage) == 'te' ? 'తెలుగు' : 'English';
    return Scaffold(
      backgroundColor: MallikaColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: MallikaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            profile?.fullName ?? 'Patient',
            style: const TextStyle(
              color: MallikaColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 8),
          Text(profile == null ? '' : 'Patient number ${profile.patientNumber}'),
          const SizedBox(height: 4),
          Text(formatIndianMobile(account?.mobileNumber ?? profile?.mobileNumber ?? '')),
          const SizedBox(height: 4),
          Text('Language: $language'),
          const SizedBox(height: 16),
          const Text(
            'Family members can be added after that part of the record is available.',
            style: TextStyle(color: MallikaColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: _busy ? null : _logout,
            child: Text(_busy ? 'Signing out...' : 'Log out'),
          ),
        ],
      ),
    );
  }
}
