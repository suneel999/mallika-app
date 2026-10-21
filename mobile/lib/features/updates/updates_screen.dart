import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/updates_api.dart';
import '../../core/session/session_controller.dart';

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final banners = await widget.session.loadBanners();
      final updates = await widget.session.loadUpdates();
      _banners = banners;
      _updates = updates;
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
        title: const Text('Updates'),
        backgroundColor: MallikaColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _UpdatesNotice(text: _error!, onRetry: _load)
              : _banners.isEmpty && _updates.isEmpty
                  ? const _UpdatesNotice(text: 'No updates yet.')
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final banner in _banners) ...[
                          _UpdateCard(title: banner.title, body: ''),
                          const SizedBox(height: 12),
                        ],
                        for (final update in _updates) ...[
                          _UpdateCard(title: update.title, body: update.body),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: MallikaColors.primary, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(body),
          ],
        ],
      ),
    );
  }
}

class _UpdatesNotice extends StatelessWidget {
  const _UpdatesNotice({required this.text, this.onRetry});

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
