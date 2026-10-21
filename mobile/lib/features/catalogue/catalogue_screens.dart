import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/catalogue_api.dart';
import '../../core/session/session_controller.dart';
import '../bookings/booking_screens.dart';

enum CatalogueKind { departments, doctors, services }

class CatalogueListScreen extends StatefulWidget {
  const CatalogueListScreen({super.key, required this.session, required this.kind});

  final SessionController session;
  final CatalogueKind kind;

  @override
  State<CatalogueListScreen> createState() => _CatalogueListScreenState();
}

class _CatalogueListScreenState extends State<CatalogueListScreen> {
  final _search = TextEditingController();
  var _loading = true;
  String? _error;
  List<CatalogueDepartment> _departments = const [];
  List<CatalogueDoctor> _doctors = const [];
  List<CatalogueService> _services = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final search = _search.text.trim();
      switch (widget.kind) {
        case CatalogueKind.departments:
          _departments = await widget.session.loadDepartments(search: search);
        case CatalogueKind.doctors:
          _doctors = await widget.session.loadDoctors(search: search);
        case CatalogueKind.services:
          _services = await widget.session.loadServices(search: search);
      }
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
        title: Text(_title),
        backgroundColor: MallikaColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (widget.kind == CatalogueKind.services)
            IconButton(
              tooltip: 'Departments',
              onPressed: () => _open(CatalogueKind.departments),
              icon: const Icon(Icons.account_tree_outlined),
            ),
          if (widget.kind != CatalogueKind.doctors)
            IconButton(
              tooltip: 'Doctors',
              onPressed: () => _open(CatalogueKind.doctors),
              icon: const Icon(Icons.groups_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  String get _title {
    switch (widget.kind) {
      case CatalogueKind.departments:
        return 'Departments';
      case CatalogueKind.doctors:
        return 'Doctors';
      case CatalogueKind.services:
        return 'Services';
    }
  }

  Widget _body(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _Message(text: _error!, onRetry: _load);
    }
    if (_isEmpty) {
      return const _Message(
        text: 'The hospital has not published this list yet.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _count,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _card(context, index),
    );
  }

  bool get _isEmpty {
    switch (widget.kind) {
      case CatalogueKind.departments:
        return _departments.isEmpty;
      case CatalogueKind.doctors:
        return _doctors.isEmpty;
      case CatalogueKind.services:
        return _services.isEmpty;
    }
  }

  int get _count {
    switch (widget.kind) {
      case CatalogueKind.departments:
        return _departments.length;
      case CatalogueKind.doctors:
        return _doctors.length;
      case CatalogueKind.services:
        return _services.length;
    }
  }

  Widget _card(BuildContext context, int index) {
    late final String title;
    late final String subtitle;
    switch (widget.kind) {
      case CatalogueKind.departments:
        final item = _departments[index];
        title = item.name;
        subtitle = item.description ?? '';
      case CatalogueKind.doctors:
        final item = _doctors[index];
        title = item.fullName;
        subtitle = item.specialtySummary ?? item.qualification ?? '';
      case CatalogueKind.services:
        final item = _services[index];
        title = item.name;
        subtitle = item.description ?? _serviceLabel(item.serviceType);
    }
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetail(index),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: MallikaColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _open(CatalogueKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CatalogueListScreen(session: widget.session, kind: kind),
      ),
    );
  }

  void _openDetail(int index) {
    final Widget page;
    switch (widget.kind) {
      case CatalogueKind.departments:
        page = DepartmentDetailScreen(department: _departments[index]);
      case CatalogueKind.doctors:
        page = DoctorDetailScreen(session: widget.session, doctor: _doctors[index]);
      case CatalogueKind.services:
        page = ServiceDetailScreen(session: widget.session, service: _services[index]);
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class DepartmentDetailScreen extends StatelessWidget {
  const DepartmentDetailScreen({super.key, required this.department});

  final CatalogueDepartment department;

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: department.name,
      lines: [if (department.description != null) department.description!],
    );
  }
}

class DoctorDetailScreen extends StatelessWidget {
  const DoctorDetailScreen({super.key, required this.session, required this.doctor});

  final SessionController session;
  final CatalogueDoctor doctor;

  @override
  Widget build(BuildContext context) {
    final departments = doctor.departments.map((item) => item.name).join(', ');
    return _DetailScaffold(
      title: doctor.fullName,
      lines: [
        if (doctor.qualification != null) doctor.qualification!,
        if (doctor.specialtySummary != null) doctor.specialtySummary!,
        if (departments.isNotEmpty) departments,
        if (doctor.bio != null) doctor.bio!,
        'This list does not show live appointment times. The hospital confirms a time after you request one.',
      ],
      actionLabel: 'Request this doctor',
      onAction: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BookingRequestScreen(session: session, consultation: true),
          ),
        );
      },
    );
  }
}

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key, required this.session, required this.service});

  final SessionController session;
  final CatalogueService service;

  @override
  Widget build(BuildContext context) {
    return _DetailScaffold(
      title: service.name,
      lines: [
        _serviceLabel(service.serviceType),
        if (service.description != null) service.description!,
        if (service.preparationInstructions != null) service.preparationInstructions!,
        'Fees are not shown here. Ask the hospital desk if you need a charge.',
      ],
      actionLabel: 'Request this service',
      onAction: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BookingRequestScreen(session: session, service: service),
          ),
        );
      },
    );
  }
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({required this.title, required this.lines, this.actionLabel, this.onAction});

  final String title;
  final List<String> lines;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MallikaColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: MallikaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final line in lines) ...[
            Text(line, style: const TextStyle(fontSize: 16, height: 1.4)),
            const SizedBox(height: 12),
          ],
          if (actionLabel != null && onAction != null)
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: MallikaColors.primary,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

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

String _serviceLabel(String serviceType) {
  switch (serviceType) {
    case 'diagnostics':
      return 'Diagnostics';
    case 'health_checkup':
      return 'Health checkup';
    case 'procedure':
      return 'Procedure';
    case 'consultation':
      return 'Consultation';
    default:
      return serviceType;
  }
}
