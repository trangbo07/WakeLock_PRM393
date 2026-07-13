import 'package:flutter/material.dart';

import '../../features/alarm_management/presentation/pages/alarm_list_page.dart';
import '../../features/feed/presentation/pages/feed_page.dart';
import '../../features/friends/presentation/pages/friends_page.dart';
import '../../features/habit/presentation/pages/habit_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

/// Root app shell: the 5-tab bottom navigation that wraps the top-level screens
/// (Home / Feed / Friends / Habit / Profile).
///
/// Today only Home is real (the alarm list); the other four are "coming soon"
/// placeholders until their UIs are built (see the social-expansion plan).
/// Detail screens are still pushed on the ROOT navigator via named routes, so
/// the full-screen ring-launch wiring in `app.dart` (navigatorKey) is untouched.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // IndexedStack keeps each tab's state alive across switches. Each tab root
  // lives in its own file (owned per developer) — see docs/team-work-split.md.
  static const List<Widget> _tabs = [
    AlarmListPage(),
    FeedPage(),
    FriendsPage(),
    HabitPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm),
            label: 'Báo thức',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Bạn bè',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Thói quen',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
