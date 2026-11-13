import 'package:flutter/material.dart';

import '../../core/session/session_controller.dart';
import '../bookings/booking_screens.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../updates/updates_screen.dart';

const brandNavy = Color(0xFF0C1B5B);

class PatientShell extends StatefulWidget {
  const PatientShell({super.key, required this.session});

  final SessionController session;

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  var _index = 0;

  void _open(int index) {
    setState(() => _index = index);
  }

  Widget _page(SessionController session) {
    switch (_index) {
      case 1:
        return BookingListScreen(session: session);
      case 2:
        return UpdatesScreen(session: session);
      case 3:
        return ProfileScreen(session: session, onOpenHome: () => _open(0));
      default:
        return HomeScreen(
          session: session,
          onOpenProfile: () => _open(3),
          onOpenBookings: () => _open(1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Scaffold(
      body: _page(session),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE3EAF5))),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: const Color(0xFFE8F0FE),
          height: 68,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              color: selected ? brandNavy : const Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );
          }),
          onDestinationSelected: _open,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: brandNavy),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month, color: brandNavy),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications, color: brandNavy),
              label: 'Updates',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: brandNavy),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
