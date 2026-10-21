import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/phone.dart';
import '../../core/session/session_controller.dart';
import '../shared/mallika_widgets.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  DateTime? _dob;
  String? _sex;
  late String _language;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _language = widget.session.language;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 30),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Enter your full name as it appears on an identity document.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.completeProfile(
        fullName: name,
        dateOfBirth: _dob == null ? null : _iso(_dob!),
        sex: _sex,
        preferredLanguage: _language,
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
    final mobile = widget.session.account?.mobileNumber ?? '';
    return Scaffold(
      backgroundColor: MallikaColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text(
              'Profile Setup',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MallikaColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Step 2 of 2: Profile',
              textAlign: TextAlign.center,
              style: TextStyle(color: MallikaColors.secondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              'Let’s Set Up Your Profile',
              style: TextStyle(
                color: MallikaColors.primary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const Text(
              'మీ ప్రొఫైల్‌ను సెటప్ చేద్దాం',
              style: TextStyle(color: MallikaColors.secondary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'A few quick details will help us manage your appointment requests accurately.',
              style: TextStyle(color: MallikaColors.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Text('Full Name (as per Aadhaar/Govt ID) *', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              key: const Key('profile-full-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'పూర్తి పేరు',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Registered Mobile Number', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(child: Text(formatIndianMobile(mobile))),
                  const Icon(Icons.check_circle, color: MallikaColors.secondary, size: 18),
                  const SizedBox(width: 4),
                  const Text('Verified', style: TextStyle(color: MallikaColors.secondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Date of Birth (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(_dob == null ? 'పుట్టిన తేదీ' : _iso(_dob!)),
            ),
            const SizedBox(height: 16),
            const Text('Gender (Optional)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Male'),
                  selected: _sex == 'male',
                  onSelected: (_) => setState(() => _sex = _sex == 'male' ? null : 'male'),
                ),
                ChoiceChip(
                  label: const Text('Female'),
                  selected: _sex == 'female',
                  onSelected: (_) => setState(() => _sex = _sex == 'female' ? null : 'female'),
                ),
                ChoiceChip(
                  label: const Text('Other'),
                  selected: _sex == 'other',
                  onSelected: (_) => setState(() => _sex = _sex == 'other' ? null : 'other'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Preferred Communication Language', style: TextStyle(fontWeight: FontWeight.w600)),
            _LanguageChoice(
              label: 'English',
              selected: _language == 'en',
              onTap: () => setState(() => _language = 'en'),
            ),
            _LanguageChoice(
              label: 'తెలుగు (Telugu)',
              selected: _language == 'te',
              onTap: () => setState(() => _language = 'te'),
            ),
            const Text(
              'We do not ask for full address or identity documents at this stage. Only basic information needed for hospital appointments.',
              style: TextStyle(color: MallikaColors.onSurfaceVariant, fontSize: 13, height: 1.4),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: MallikaColors.error)),
            ],
            const SizedBox(height: 16),
            MallikaButton(label: 'Complete Setup', busy: _busy, onPressed: _submit),
            const SizedBox(height: 8),
            const Text(
              'You can update your profile and add family members anytime in Settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: MallikaColors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _iso(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: MallikaColors.secondary,
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}
