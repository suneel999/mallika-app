import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/auth_api.dart';
import '../../core/api/booking_api.dart';
import '../../core/api/catalogue_api.dart';
import '../../core/session/session_controller.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  var _loading = true;
  String? _error;
  List<BookingSummary> _bookings = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _bookings = await widget.session.loadBookings();
    } on ApiException catch (error) {
      _error = error.displayMessage;
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _canCancel(String status) {
    return status == 'requested' || status == 'under_review' || status == 'confirmed';
  }

  Future<void> _cancel(BookingSummary booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request cancellation'),
        content: Text('Ask the hospital to cancel ${booking.reference}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Request cancellation')),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      final updated = await widget.session.requestCancellation(booking.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _bookings = [
          for (final item in _bookings)
            if (item.id == updated.id) updated else item,
        ];
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error.displayMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MallikaColors.background,
      appBar: AppBar(
        title: const Text('Bookings'),
        backgroundColor: MallikaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _Notice(text: _error!, onRetry: _load)
              : _bookings.isEmpty
                  ? const _Notice(text: 'You have no appointment requests yet.')
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookings.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final booking = _bookings[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.targetName,
                                style: const TextStyle(
                                  color: MallikaColors.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${booking.patientName} · ${booking.requestedDate}'
                                '${booking.preferredTimeSlot == null ? '' : ' · ${booking.preferredTimeSlot}'}',
                              ),
                              const SizedBox(height: 4),
                              Text(booking.reference),
                              const SizedBox(height: 8),
                              Text(
                                bookingStatusLabel(booking.status),
                                style: const TextStyle(
                                  color: MallikaColors.secondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if ((booking.confirmedFor ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Confirmed for ${booking.confirmedFor}'),
                              ],
                              if (_canCancel(booking.status))
                                TextButton(
                                  onPressed: () => _cancel(booking),
                                  child: const Text('Request cancellation'),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}

class PublishedServicesScreen extends StatefulWidget {
  const PublishedServicesScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<PublishedServicesScreen> createState() => _PublishedServicesScreenState();
}

class _PublishedServicesScreenState extends State<PublishedServicesScreen> {
  var _loading = true;
  String? _error;
  List<CatalogueService> _services = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _services = await widget.session.loadServices();
    } on ApiException catch (error) {
      _error = error.displayMessage;
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MallikaColors.background,
      appBar: AppBar(
        title: const Text('Services'),
        backgroundColor: MallikaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _Notice(text: _error!, onRetry: _load)
              : _services.isEmpty
                  ? const _Notice(text: 'The hospital has not published a service yet.')
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _services.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final service = _services[index];
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => BookingRequestScreen(
                                    session: widget.session,
                                    service: service,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                service.name,
                                style: const TextStyle(
                                  color: MallikaColors.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class BookingRequestScreen extends StatefulWidget {
  const BookingRequestScreen({
    super.key,
    required this.session,
    this.consultation = false,
    this.service,
  });

  final SessionController session;
  final bool consultation;
  final CatalogueService? service;

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  final _note = TextEditingController();
  final _random = Random();
  String? _profileId;
  DateTime? _date;
  String? _time;
  BookingOptions? _options;
  CatalogueService? _service;
  var _loading = true;
  var _busy = false;
  String? _error;
  String? _idempotencyKey;
  String? _fingerprint;

  bool get _isConsultation => widget.consultation || widget.service == null;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final options = await widget.session.loadBookingOptions();
      await widget.session.loadProfiles();
      _options = options;
      _profileId = _selectedProfile(widget.session.profiles);
      if (!_isConsultation && widget.service == null) {
        _error = 'Choose a published service.';
      } else if (_isConsultation && options.doctor == null) {
        _error = 'The hospital has not published the consultation doctor yet.';
      }
    } on ApiException catch (error) {
      _error = error.displayMessage;
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String? _selectedProfile(List<PatientProfile> profiles) {
    for (final person in profiles) {
      if (person.relationship == 'self') {
        return person.id;
      }
    }
    if (profiles.isNotEmpty) {
      return profiles.first.id;
    }
    return null;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  List<PatientProfile> get _people => widget.session.profiles;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 180)),
      initialDate: _date ?? today,
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _submit() async {
    final profileId = _profileId;
    final date = _date;
    if (profileId == null) {
      setState(() => _error = 'Choose who this request is for.');
      return;
    }
    if (date == null) {
      setState(() => _error = 'Choose a preferred date.');
      return;
    }
    final time = _time;
    if (time == null) {
      setState(() => _error = 'Choose a time.');
      return;
    }
    final fingerprint = '$profileId|${_service?.id}|${_iso(date)}|$time|${_note.text.trim()}';
    if (_idempotencyKey == null || _fingerprint != fingerprint) {
      _idempotencyKey = '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 30)}';
      _fingerprint = fingerprint;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = await widget.session.requestBooking(
        idempotencyKey: _idempotencyKey!,
        patientProfileId: profileId,
        serviceId: _isConsultation ? null : _service?.id,
        requestedDate: _iso(date),
        timeSlot: time,
        note: _note.text.trim(),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${created.reference} is ${bookingStatusLabel(created.status)}.')),
      );
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
    final doctor = _options?.doctor;
    final target = _isConsultation ? (doctor?.fullName ?? 'Consultation') : (_service?.name ?? 'Service');
    final people = _people;
    final slots = _options?.timeSlots ?? const <String>[];
    final blocked = _loading || (_isConsultation ? doctor == null : _service == null);
    return Scaffold(
      backgroundColor: MallikaColors.background,
      appBar: AppBar(
        title: Text(_isConsultation ? 'Consultation' : 'Request service'),
        backgroundColor: MallikaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isConsultation) ...[
            _DoctorPhoto(photoUrl: doctor?.photoUrl),
            const SizedBox(height: 12),
          ],
          Text(
            target,
            style: const TextStyle(
              color: MallikaColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_isConsultation && (doctor?.qualification ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(doctor!.qualification!),
          ],
          const SizedBox(height: 8),
          const Text(
            'Choose a date and a time. The hospital reviews this request. Nothing is confirmed or paid in the app.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _profileId,
            decoration: const InputDecoration(labelText: 'Who is this for?', filled: true, fillColor: Colors.white),
            items: [
              for (final person in people)
                DropdownMenuItem(value: person.id, child: Text(person.fullName)),
            ],
            onChanged: _busy || blocked ? null : (value) => setState(() => _profileId = value),
          ),
          const SizedBox(height: 12),
          const Text('Choose a time', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slot in slots)
                ChoiceChip(
                  label: Text(slot),
                  selected: _time == slot,
                  onSelected: _busy || blocked
                      ? null
                      : (selected) => setState(() => _time = selected ? slot : null),
                ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : _pickDate,
            child: Text(_date == null ? 'Choose a preferred date' : _iso(_date!)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note for the hospital',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: MallikaColors.error)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy || blocked ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: MallikaColors.primary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(_busy ? 'Sending...' : 'Send request'),
          ),
        ],
      ),
    );
  }
}

class _DoctorPhoto extends StatelessWidget {
  const _DoctorPhoto({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    final hasPhoto = url != null && url.isNotEmpty;
    return CircleAvatar(
      radius: 48,
      backgroundColor: MallikaColors.primaryFixed,
      backgroundImage: hasPhoto ? NetworkImage(url) : null,
      child: hasPhoto ? null : const Icon(Icons.person, size: 48, color: MallikaColors.primary),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

String _iso(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
