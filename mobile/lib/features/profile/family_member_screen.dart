import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/auth_api.dart';
import '../../core/phone.dart';
import '../../core/session/session_controller.dart';
import '../authentication/auth_chrome.dart';
import '../shared/mallika_widgets.dart';

const familyRelationships = <String, String>{
  'spouse': 'Spouse',
  'parent': 'Parent',
  'child': 'Child',
  'sibling': 'Sibling',
  'other': 'Other',
};

class FamilyMemberScreen extends StatefulWidget {
  const FamilyMemberScreen({super.key, required this.session, this.person});

  final SessionController session;
  final PatientProfile? person;

  @override
  State<FamilyMemberScreen> createState() => _FamilyMemberScreenState();
}

class _FamilyMemberScreenState extends State<FamilyMemberScreen> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  String? _relationship;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final person = widget.person;
    if (person != null) {
      _name.text = person.fullName;
      _relationship = person.relationship;
      _mobile.text = nationalDigits(person.mobileNumber);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _remove() async {
    final person = widget.person;
    if (person == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove family member'),
        content: Text('Remove ${person.fullName} from your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.removeFamilyMember(person);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.displayMessage);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      setState(
        () => _error =
            'Enter the full name as it appears on an identity document.',
      );
      return;
    }
    final relationship = _relationship;
    if (relationship == null) {
      setState(() => _error = 'Choose how this person is related to you.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final person = widget.person;
      if (person == null) {
        await widget.session.addFamilyMember(
          fullName: name,
          relationship: relationship,
          mobileNumber: _mobile.text.trim(),
        );
      } else {
        await widget.session.updateFamilyMember(
          person: person,
          fullName: name,
          relationship: relationship,
          mobileNumber: _mobile.text.trim(),
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.displayMessage);
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
      appBar: AppBar(
        title: Text(
          widget.person == null ? 'Add family member' : 'Edit family member',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MallikaColors.tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: MallikaColors.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This person is saved on your account. You can request appointments for them.',
                    style: TextStyle(
                      color: MallikaColors.ink,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AuthLabeledField(
            label: 'Full name *',
            child: TextField(
              key: const Key('family-full-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: authInputDecoration(
                'As on an identity document',
              ).copyWith(fillColor: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          const AuthLabeledField(
            label: 'Relationship *',
            child: SizedBox.shrink(),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in familyRelationships.entries)
                _RelationChip(
                  label: entry.value,
                  selected: _relationship == entry.key,
                  onTap: () => setState(() => _relationship = entry.key),
                ),
            ],
          ),
          const SizedBox(height: 18),
          AuthLabeledField(
            label: 'Mobile number (optional)',
            child: AuthMobileField(controller: _mobile),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: MallikaColors.error)),
          ],
          const SizedBox(height: 20),
          MallikaButton(
            label: widget.person == null
                ? 'Save family member'
                : 'Save changes',
            icon: Icons.check,
            busy: _busy,
            onPressed: _save,
          ),
          if (widget.person != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _remove,
              style: TextButton.styleFrom(foregroundColor: MallikaColors.error),
              child: const Text('Remove family member'),
            ),
          ],
        ],
      ),
    );
  }
}

class _RelationChip extends StatelessWidget {
  const _RelationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? MallikaColors.primary : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? MallikaColors.primary : MallikaColors.outline,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : MallikaColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
