import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/auth_api.dart';
import '../../core/api/booking_api.dart';
import '../../core/api/catalogue_api.dart';
import '../../core/session/session_controller.dart';
import '../shared/mallika_widgets.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen>
    with SingleTickerProviderStateMixin {
  var _loading = true;
  String? _error;
  List<BookingSummary> _bookings = const [];
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      _bookings = await widget.session.loadBookings();
      _error = null;
    } on ApiException catch (error) {
      _error = error.displayMessage;
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _canCancel(String status) {
    return status == 'requested' ||
        status == 'under_review' ||
        status == 'confirmed';
  }

  List<BookingSummary> _inGroup(_BookingGroup group) {
    return [
      for (final booking in _bookings)
        if (_bookingGroup(booking.status) == group) booking,
    ];
  }

  Future<void> _cancel(BookingSummary booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request cancellation'),
        content: Text('Ask the hospital to cancel ${booking.reference}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: MallikaColors.error),
            child: const Text('Request cancellation'),
          ),
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
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: MallikaColors.accent,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFFB9C6E8),
          labelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Missed'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? MallikaNotice(
              icon: Icons.cloud_off_outlined,
              title: _error!,
              onRetry: _load,
            )
          : TabBarView(
              controller: _tabs,
              children: [
                _BookingPage(
                  bookings: _inGroup(_BookingGroup.upcoming),
                  emptyIcon: Icons.calendar_month,
                  onCancel: _cancel,
                  canCancel: _canCancel,
                  onRefresh: () => _load(quiet: true),
                ),
                _BookingPage(
                  bookings: _inGroup(_BookingGroup.completed),
                  emptyIcon: Icons.verified,
                  onCancel: _cancel,
                  canCancel: _canCancel,
                  onRefresh: () => _load(quiet: true),
                ),
                _BookingPage(
                  bookings: _inGroup(_BookingGroup.missed),
                  emptyIcon: Icons.event_busy,
                  onCancel: _cancel,
                  canCancel: _canCancel,
                  onRefresh: () => _load(quiet: true),
                ),
              ],
            ),
    );
  }
}

enum _BookingGroup { upcoming, completed, missed }

_BookingGroup _bookingGroup(String status) {
  switch (status) {
    case 'completed':
      return _BookingGroup.completed;
    case 'no_show':
    case 'cancelled':
    case 'rejected':
      return _BookingGroup.missed;
    default:
      return _BookingGroup.upcoming;
  }
}

/// Text and background colour for a booking status label.
(Color, Color) _statusColors(String status) {
  switch (status) {
    case 'confirmed':
    case 'completed':
      return (const Color(0xFF0B7A43), const Color(0xFFE3F6EC));
    case 'requested':
    case 'under_review':
      return (const Color(0xFF9A5B00), const Color(0xFFFFF3D6));
    case 'cancellation_requested':
      return (const Color(0xFFB54708), const Color(0xFFFFEBD9));
    case 'rejected':
    case 'cancelled':
    case 'no_show':
      return (const Color(0xFFB42318), const Color(0xFFFEE9E7));
    default:
      return (MallikaColors.primary, MallikaColors.tint);
  }
}

class _BookingPage extends StatelessWidget {
  const _BookingPage({
    required this.bookings,
    required this.emptyIcon,
    required this.onCancel,
    required this.canCancel,
    required this.onRefresh,
  });

  final List<BookingSummary> bookings;
  final IconData emptyIcon;
  final Future<void> Function(BookingSummary booking) onCancel;
  final bool Function(String status) canCancel;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return MallikaNotice(
        icon: emptyIcon,
        title: 'You have not booked any appointment yet.',
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _BookingCard(
            booking: booking,
            onCancel: canCancel(booking.status)
                ? () => onCancel(booking)
                : null,
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, this.onCancel});

  final BookingSummary booking;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final (color, background) = _statusColors(booking.status);
    final confirmedFor = booking.confirmedFor ?? '';
    final slot = booking.preferredTimeSlot;
    return MallikaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconTile(
                icon: booking.serviceName == null
                    ? Icons.medical_services_rounded
                    : Icons.medical_information_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.targetName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: MallikaColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      booking.reference,
                      style: const TextStyle(
                        color: MallikaColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StatusPill(
                      label: bookingStatusLabel(booking.status),
                      color: color,
                      background: background,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: MallikaColors.outline),
          const SizedBox(height: 12),
          _Fact(
            icon: Icons.event_outlined,
            text:
                '${prettyDate(booking.requestedDate)}${slot == null ? '' : ' · $slot'}',
          ),
          const SizedBox(height: 8),
          _Fact(icon: Icons.person_outline, text: booking.patientName),
          if (confirmedFor.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F6EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF0B7A43),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Confirmed for ${prettyDateTime(confirmedFor)}',
                      style: const TextStyle(
                        color: Color(0xFF0B5C33),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onCancel != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: MallikaColors.error,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Request cancellation'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: MallikaColors.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: MallikaColors.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class PublishedServicesScreen extends StatefulWidget {
  const PublishedServicesScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<PublishedServicesScreen> createState() =>
      _PublishedServicesScreenState();
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
      appBar: AppBar(title: const Text('Services')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? MallikaNotice(
              icon: Icons.cloud_off_outlined,
              title: _error!,
              onRetry: _load,
            )
          : _services.isEmpty
          ? const MallikaNotice(
              icon: Icons.medical_information_outlined,
              title: 'The hospital has not published a service yet.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _services.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Text(
                      'Choose a service to request a date and time.',
                      style: TextStyle(
                        color: MallikaColors.muted,
                        fontSize: 14,
                      ),
                    ),
                  );
                }
                final service = _services[index - 1];
                final description = (service.description ?? '').trim();
                return MallikaCard(
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
                  child: Row(
                    children: [
                      const IconTile(icon: Icons.medical_information_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                color: MallikaColors.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: MallikaColors.muted,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right,
                        color: MallikaColors.muted,
                      ),
                    ],
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

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickDate() async {
    final today = _today;
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
    final fingerprint =
        '$profileId|${_service?.id}|${_iso(date)}|$time|${_note.text.trim()}';
    if (_idempotencyKey == null || _fingerprint != fingerprint) {
      _idempotencyKey =
          '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 30)}';
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
      await showDialog<void>(
        context: context,
        builder: (context) => _RequestSentDialog(
          reference: created.reference,
          status: bookingStatusLabel(created.status),
          when: '${prettyDay(date)} · $time',
        ),
      );
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
    final doctor = _options?.doctor;
    final target = _isConsultation
        ? (doctor?.fullName ?? 'Consultation')
        : (_service?.name ?? 'Service');
    final qualification = _isConsultation
        ? (doctor?.qualification ?? '').trim()
        : (_service?.description ?? '').trim();
    final slots = _options?.timeSlots ?? const <String>[];
    final blocked =
        _loading || (_isConsultation ? doctor == null : _service == null);
    final today = _today;
    final days = [for (var i = 0; i < 14; i++) today.add(Duration(days: i))];
    final date = _date;
    final offStrip = date != null && !days.contains(date);
    return Scaffold(
      backgroundColor: MallikaColors.background,
      appBar: AppBar(
        title: Text(_isConsultation ? 'Consultation' : 'Request service'),
      ),
      bottomNavigationBar: _loading
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: MallikaColors.outline)),
                ),
                child: MallikaButton(
                  label: 'Send request',
                  icon: Icons.send_rounded,
                  busy: _busy,
                  onPressed: blocked ? null : _submit,
                ),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                MallikaCard(
                  child: Row(
                    children: [
                      if (_isConsultation)
                        _DoctorPhoto(photoUrl: doctor?.photoUrl)
                      else
                        const IconTile(
                          icon: Icons.medical_information_rounded,
                          size: 56,
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              target,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                color: MallikaColors.primary,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                            if (qualification.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                qualification,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: MallikaColors.muted,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
                          'Choose a date and a time. The hospital reviews this request. Nothing is confirmed or paid in the app.',
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
                Row(
                  children: [
                    const Expanded(child: SectionLabel('Choose a date')),
                    TextButton.icon(
                      onPressed: _busy || blocked ? null : _pickDate,
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: Text(offStrip ? prettyDay(date) : 'Calendar'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 78,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final day = days[index];
                      return _DayChip(
                        day: day,
                        selected: day == date,
                        onTap: _busy || blocked
                            ? null
                            : () => setState(() => _date = day),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const SectionLabel('Choose a time'),
                const SizedBox(height: 10),
                if (slots.isEmpty)
                  const Text(
                    'The hospital has not listed a time yet.',
                    style: TextStyle(color: MallikaColors.muted),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final slot in slots)
                        _TimeChip(
                          label: slot,
                          selected: _time == slot,
                          onTap: _busy || blocked
                              ? null
                              : () => setState(
                                  () => _time = _time == slot ? null : slot,
                                ),
                        ),
                    ],
                  ),
                const SizedBox(height: 20),
                const SectionLabel('Note for the hospital'),
                const SizedBox(height: 10),
                TextField(
                  controller: _note,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Optional. Anything the hospital should know.',
                    hintStyle: const TextStyle(
                      color: Color(0xFF9AA5B8),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(14),
                    border: _noteBorder(MallikaColors.outline),
                    enabledBorder: _noteBorder(MallikaColors.outline),
                    focusedBorder: _noteBorder(MallikaColors.primary, 1.6),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: MallikaColors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 18,
                          color: MallikaColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: MallikaColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

OutlineInputBorder _noteBorder(Color color, [double width = 1]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, required this.selected, this.onTap});

  final DateTime day;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final front = selected ? Colors.white : MallikaColors.ink;
    final soft = selected ? const Color(0xFFD6E3FF) : MallikaColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: prettyDay(day),
      excludeSemantics: true,
      child: Material(
        color: selected ? MallikaColors.primary : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? MallikaColors.primary : MallikaColors.outline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weekdayShort(day),
                  style: TextStyle(
                    color: soft,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: front,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                Text(
                  monthShort(day),
                  style: TextStyle(
                    color: soft,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

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

class _RequestSentDialog extends StatelessWidget {
  const _RequestSentDialog({
    required this.reference,
    required this.status,
    required this.when,
  });

  final String reference;
  final String status;
  final String when;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.check_circle, color: Color(0xFF0B7A43), size: 52),
      title: const Text('Request sent', textAlign: TextAlign.center),
      content: Text(
        '$reference is $status.\n$when\n\nThe hospital will review it. You can follow it under Bookings.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(minimumSize: const Size(160, 46)),
          child: const Text('Done'),
        ),
      ],
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
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: MallikaColors.accent, width: 2),
      ),
      child: CircleAvatar(
        radius: 34,
        backgroundColor: MallikaColors.tint,
        backgroundImage: hasPhoto ? NetworkImage(url) : null,
        child: hasPhoto
            ? null
            : const Icon(Icons.person, size: 36, color: MallikaColors.primary),
      ),
    );
  }
}

String _iso(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
