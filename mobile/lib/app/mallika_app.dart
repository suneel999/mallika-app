import 'package:flutter/material.dart';

import '../core/session/session_controller.dart';
import 'app_gate.dart';
import 'theme.dart';

class MallikaApp extends StatefulWidget {
  const MallikaApp({super.key, this.session});

  final SessionController? session;

  @override
  State<MallikaApp> createState() => _MallikaAppState();
}

class _MallikaAppState extends State<MallikaApp> {
  late final SessionController _session;
  late final bool _ownsSession;

  @override
  void initState() {
    super.initState();
    _ownsSession = widget.session == null;
    _session = widget.session ?? SessionController();
    if (_ownsSession) {
      _session.boot();
    }
  }

  @override
  void dispose() {
    if (_ownsSession) {
      _session.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mallika Hospitals',
      theme: buildMallikaTheme(),
      home: AppGate(session: _session),
    );
  }
}
