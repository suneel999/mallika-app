import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import 'theme.dart';

class MallikaApp extends StatelessWidget {
  const MallikaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mallika Hospitals',
      theme: buildMallikaTheme(),
      home: const HomeScreen(),
    );
  }
}
