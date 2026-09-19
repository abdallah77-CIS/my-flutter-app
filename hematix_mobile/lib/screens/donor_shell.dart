import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'appointments_screen.dart';
import 'dashboard_screen.dart';
import 'donations_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Tabbed container for the donor area — the mobile equivalent of the web
/// sidebar. Each tab keeps its own state via an IndexedStack so switching
/// back and forth doesn't refetch everything.
class DonorShell extends StatefulWidget {
  const DonorShell({super.key});

  @override
  State<DonorShell> createState() => _DonorShellState();
}

class _DonorShellState extends State<DonorShell> {
  int _index = 0;

  static const _titles = [
    'Dashboard',
    'Appointments',
    'Donations',
    'Notifications',
    'Profile',
  ];

  // Rebuilt on each tab switch via keys so a screen refetches when revisited,
  // which matters because admin actions change this data server-side.
  final _keys = List.generate(5, (_) => UniqueKey());

  static const List<Widget> _screens = [
    DashboardScreen(),
    AppointmentsScreen(),
    DonationsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.water_drop,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(_titles[_index]),
          ],
        ),
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < _screens.length; i++)
              KeyedSubtree(key: _keys[i], child: _screens[i]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() {
          // Give the target tab a fresh key so it reloads its data.
          if (i != _index) _keys[i] = UniqueKey();
          _index = i;
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism),
            label: 'Donations',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
