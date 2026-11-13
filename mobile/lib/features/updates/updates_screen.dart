import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/updates_api.dart';
import '../../core/session/session_controller.dart';
import '../shared/mallika_widgets.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  var _loading = true;
  String? _error;
  List<HospitalBanner> _banners = const [];
  List<HospitalUpdate> _updates = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final banners = await widget.session.loadBanners();
      final updates = await widget.session.loadUpdates();
      _banners = banners;
      _updates = updates;
      _error = null;
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
      appBar: AppBar(title: const Text('Updates')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? MallikaNotice(
              icon: Icons.cloud_off_outlined,
              title: _error!,
              onRetry: _load,
            )
          : _banners.isEmpty && _updates.isEmpty
          ? const MallikaNotice(
              icon: Icons.notifications_off_outlined,
              title: 'No updates yet.',
              message: 'Changes to your bookings appear here.',
            )
          : RefreshIndicator(
              onRefresh: () => _load(quiet: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  for (final banner in _banners) ...[
                    _UpdateCard(
                      icon: Icons.campaign_rounded,
                      title: banner.title,
                      body: '',
                      when: '',
                    ),
                    const SizedBox(height: 12),
                  ],
                  for (final update in _updates) ...[
                    _UpdateCard(
                      icon: Icons.event_available_rounded,
                      title: update.title,
                      body: update.body,
                      when: prettyDateTime(update.createdAt),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.when,
  });

  final IconData icon;
  final String title;
  final String body;
  final String when;

  @override
  Widget build(BuildContext context) {
    return MallikaCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: MallikaColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      color: MallikaColors.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
                if (when.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    when,
                    style: const TextStyle(
                      color: MallikaColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
