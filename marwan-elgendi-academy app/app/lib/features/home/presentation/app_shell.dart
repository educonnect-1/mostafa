import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/notification_deep_link.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../services/presence_service.dart';
import '../../../services/push_notification_service.dart';
import '../../assignments/presentation/assignments_list_screen.dart';
import '../../exams/presentation/exams_list_screen.dart';
import '../../groups/presentation/groups_list_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'home_shell.dart';

/// Bottom-nav shell per spec §6's example navigation. Calendar,
/// Attendance, Resources, Progress, and Leaderboard are reached from
/// Home's quick-access grid and from each group's detail screen rather
/// than as additional bottom-nav tabs, to keep the nav bar to a sane
/// number of destinations.
///
/// This is also where app-wide background services are started, since
/// this widget only ever mounts once the user is authenticated (the
/// router's redirect guarantees that): presence tracking and push
/// notification registration + deep-link routing (spec §10, §12).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _tabs = [
    HomeShell(),
    GroupsListScreen(),
    AssignmentsListScreen(),
    ExamsListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startBackgroundServices());
  }

  Future<void> _startBackgroundServices() async {
    final presence = ref.read(presenceServiceProvider);
    WidgetsBinding.instance.addObserver(presence);
    await presence.start();

    final push = ref.read(pushNotificationServiceProvider);
    push.onNotificationTap = (data) {
      final path = deepLinkPathForNotificationData(data);
      ref.read(appRouterProvider).push(path);
    };
    await push.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(ref.read(presenceServiceProvider));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: IndexedStack(index: _index, children: _tabs)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Groups'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Assignments'),
          NavigationDestination(icon: Icon(Icons.quiz_outlined), selectedIcon: Icon(Icons.quiz), label: 'Exams'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
