import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/announcements/presentation/announcements_list_screen.dart';
import '../../features/assignments/presentation/assignment_detail_screen.dart';
import '../../features/assignments/presentation/assignments_list_screen.dart';
import '../../features/attendance/presentation/attendance_screen.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/exams/presentation/exam_detail_screen.dart';
import '../../features/exams/presentation/exam_taking_screen.dart';
import '../../features/exams/presentation/exams_list_screen.dart';
import '../../features/groups/presentation/group_detail_screen.dart';
import '../../features/groups/presentation/groups_list_screen.dart';
import '../../features/home/presentation/app_shell.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/notifications/presentation/notification_center_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/resources/presentation/resources_screen.dart';
import '../../features/rooms/presentation/room_detail_screen.dart';
import '../../features/rooms/presentation/rooms_list_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../models/exam.dart';

/// Central router. Auth gating happens here via `redirect`, not by
/// scattering `if (isSignedIn)` checks through feature screens.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Deliberately `ref.read`, not `ref.watch`, in the provider body:
  // recreating the GoRouter instance on every auth change would reset
  // its internal navigation stack. `refreshListenable` below is what
  // makes it re-evaluate `redirect` when auth state changes, while
  // `ref.read` inside `redirect` always gets the current value at the
  // moment of navigation.
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthRefreshNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final loggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/forgot-password';

      switch (authState.status) {
        case AuthStatus.initial:
          return state.matchedLocation == '/' ? null : '/';
        case AuthStatus.unauthenticated:
          return loggingIn ? null : '/login';
        case AuthStatus.authenticated:
          if (loggingIn || state.matchedLocation == '/') return '/home';
          return null;
      }
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const AppShell()),
      GoRoute(
        path: '/groups',
        builder: (context, state) => const GroupsListScreen(),
      ),
      GoRoute(
        path: '/groups/:groupId',
        builder: (context, state) => GroupDetailScreen(
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/chat',
        builder: (context, state) => ChatScreen(
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: '/assignments',
        builder: (context, state) => const AssignmentsListScreen(),
      ),
      GoRoute(
        path: '/assignments/:assignmentId',
        builder: (context, state) => AssignmentDetailScreen(
          assignmentId: state.pathParameters['assignmentId']!,
        ),
      ),
      GoRoute(
        path: '/exams',
        builder: (context, state) => const ExamsListScreen(),
      ),
      GoRoute(
        path: '/exams/:examId',
        builder: (context, state) => ExamDetailScreen(
          examId: state.pathParameters['examId']!,
        ),
      ),
      GoRoute(
        path: '/exams/:examId/take',
        builder: (context, state) => ExamTakingScreen(
          exam: state.extra as Exam,
        ),
      ),
      GoRoute(
        path: '/announcements',
        builder: (context, state) => const AnnouncementsListScreen(),
      ),
      GoRoute(
        path: '/rooms',
        builder: (context, state) => const RoomsListScreen(),
      ),
      GoRoute(
        path: '/rooms/:roomId',
        builder: (context, state) => RoomDetailScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: '/resources',
        builder: (context, state) => const ResourcesScreen(),
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/groups/:groupId/leaderboard',
        builder: (context, state) => LeaderboardScreen(
          groupId: state.pathParameters['groupId']!,
          groupName: (state.extra as String?) ?? 'Group',
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      // Route list complete for the student app's spec (§1–§31).
    ],
  );
});

/// Bridges Riverpod state changes into something GoRouter's
/// `refreshListenable` (a plain `Listenable`) can react to.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}
