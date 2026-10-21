import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/auth_api.dart';
import '../../core/phone.dart';
import '../../core/session/session_controller.dart';
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
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove')),
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
      setState(() => _error = 'Enter the full name as it appears on an identity document.');
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
        title: Text(widget.person == null ? 'Add family member' : 'Edit family member'),
        backgroundColor: MallikaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'This person is saved on your account. You can request appointments for them.',
            style: TextStyle(color: MallikaColors.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 16),
          const Text('Full name *', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            key: const Key('family-full-name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Relationship *', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final entry in familyRelationships.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  selected: _relationship == entry.key,
                  onSelected: (_) => setState(() => _relationship = entry.key),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Mobile number (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _mobile,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            decoration: InputDecoration(
              hintText: '10-digit Indian mobile',
              prefixText: '+91  ',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: MallikaColors.error)),
          ],
          const SizedBox(height: 20),
          MallikaButton(
            label: widget.person == null ? 'Save family member' : 'Save changes',
            busy: _busy,
            onPressed: _save,
          ),
          if (widget.person != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy ? null : _remove,
              child: const Text('Remove family member'),
            ),
          ],
        ],
      ),
    );
  }
}
