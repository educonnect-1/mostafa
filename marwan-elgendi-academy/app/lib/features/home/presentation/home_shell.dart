import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/profile.dart';
import '../../../repositories/profile_repository.dart';
import '../../auth/application/auth_controller.dart';
import '../../groups/application/groups_controller.dart';
import '../../assignments/application/assignments_controller.dart';
import '../../exams/application/exams_controller.dart';
import '../../rooms/application/rooms_controller.dart';
import '../../rooms/presentation/rooms_list_screen.dart' show joinRoom;
import '../../announcements/application/announcements_controller.dart';
import '../../notifications/application/notifications_controller.dart';
import '../../../models/assignment.dart';
import '../../../models/exam.dart';
import '../../../models/room.dart';

/// Home dashboard tab: real profile data plus live previews of groups,
/// assignments, exams, live rooms, and announcements, plus a
/// quick-access grid to calendar/attendance/resources/progress.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppBrand.academyName),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => context.push('/search'),
          ),
          _NotificationBellAction(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myProfileProvider.future),
        child: profileAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => ErrorRetryView(
            error: err,
            onRetry: () => ref.invalidate(myProfileProvider),
          ),
          data: (profile) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: profile.avatarUrl != null
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    child: profile.avatarUrl == null
                        ? Text(profile.fullName.isNotEmpty
                            ? profile.fullName[0].toUpperCase()
                            : '?')
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${profile.fullName}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          profile.email,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _LiveRoomsBanner(),
              _GroupsPreviewCard(),
              const SizedBox(height: AppSpacing.md),
              _AssignmentsPreviewCard(),
              const SizedBox(height: AppSpacing.md),
              _ExamsPreviewCard(),
              const SizedBox(height: AppSpacing.md),
              _AnnouncementsPreviewCard(),
              const SizedBox(height: AppSpacing.lg),
              Text('Quick Access', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _QuickAccessGrid(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'That\'s the full app — thanks for using Marwan Elgendi Academy!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentsPreviewCard extends ConsumerWidget {
  const _AssignmentsPreviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(myAssignmentsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Assignments', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.push('/assignments'),
                  child: const Text('See all'),
                ),
              ],
            ),
            assignmentsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: LoadingView(),
              ),
              error: (err, _) => ErrorRetryView(
                error: err,
                onRetry: () => ref.invalidate(myAssignmentsProvider),
              ),
              data: (assignments) {
                final upcoming =
                    assignments.where((a) => !a.isClosed).take(3).toList();
                if (upcoming.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Text('No open assignments right now.'),
                  );
                }
                return Column(
                  children: upcoming
                      .map((a) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.assignment_outlined, color: AppBrand.primary),
                            title: Text(a.title),
                            subtitle: Text(_dueLabel(a)),
                            onTap: () => context.push('/assignments/${a.id}'),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _dueLabel(Assignment a) {
    final diff = a.deadline.difference(DateTime.now());
    if (diff.inHours < 1) return 'Due in ${diff.inMinutes.clamp(0, 59)}m';
    if (diff.inDays < 1) return 'Due in ${diff.inHours}h';
    return 'Due in ${diff.inDays}d';
  }
}

class _ExamsPreviewCard extends ConsumerWidget {
  const _ExamsPreviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examsAsync = ref.watch(myExamsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Exams', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.push('/exams'),
                  child: const Text('See all'),
                ),
              ],
            ),
            examsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: LoadingView(),
              ),
              error: (err, _) => ErrorRetryView(
                error: err,
                onRetry: () => ref.invalidate(myExamsProvider),
              ),
              data: (exams) {
                final upcoming = exams
                    .where((e) => e.myAttempt?.status != AttemptStatus.graded)
                    .take(3)
                    .toList();
                if (upcoming.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Text('No pending exams right now.'),
                  );
                }
                return Column(
                  children: upcoming
                      .map((e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.quiz_outlined, color: AppBrand.primary),
                            title: Text(e.title),
                            subtitle: Text(
                              'Due ${e.deadline.toLocal().toString().split(' ').first}',
                            ),
                            onTap: () => context.push('/exams/${e.id}'),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupsPreviewCard extends ConsumerWidget {
  const _GroupsPreviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('My Groups', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.push('/groups'),
                  child: const Text('See all'),
                ),
              ],
            ),
            groupsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: LoadingView(),
              ),
              error: (err, _) => ErrorRetryView(
                error: err,
                onRetry: () => ref.invalidate(myGroupsProvider),
              ),
              data: (groups) {
                if (groups.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Text('You\'re not in any groups yet.'),
                  );
                }
                final preview = groups.take(3);
                return Column(
                  children: preview
                      .map((g) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.groups_outlined, color: AppBrand.primary),
                            title: Text(g.name),
                            subtitle: Text('${g.memberCount} members'),
                            onTap: () => context.push('/groups/${g.id}'),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid();

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      (Icons.calendar_month_outlined, 'Calendar', '/calendar'),
      (Icons.event_available_outlined, 'Attendance', '/attendance'),
      (Icons.folder_open_outlined, 'Resources', '/resources'),
      (Icons.insights_outlined, 'Progress', '/progress'),
      (Icons.videocam_outlined, 'Live Classes', '/rooms'),
      (Icons.campaign_outlined, 'Announcements', '/announcements'),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.1,
      children: items
          .map((item) => _QuickAccessTile(icon: item.$1, label: item.$2, route: item.$3))
          .toList(),
    );
  }
}

class _QuickAccessTile extends StatelessWidget {
  const _QuickAccessTile({required this.icon, required this.label, required this.route});
  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppBrand.primary),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBellAction extends ConsumerWidget {
  const _NotificationBellAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () => context.push('/notifications'),
        ),
        if (unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppBrand.danger,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }
}

class _LiveRoomsBanner extends ConsumerWidget {
  const _LiveRoomsBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(myRoomsStreamProvider);

    return roomsAsync.maybeWhen(
      data: (rooms) {
        final live = rooms.where((r) => r.status == RoomStatus.live).toList();
        if (live.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Card(
            color: AppBrand.danger.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔴 Live Now',
                    style: TextStyle(color: AppBrand.danger, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ...live.map((room) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(child: Text(room.title)),
                            FilledButton(
                              onPressed: () => joinRoom(context, ref, room),
                              child: const Text('Join'),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _AnnouncementsPreviewCard extends ConsumerWidget {
  const _AnnouncementsPreviewCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(myAnnouncementsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Announcements', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.push('/announcements'),
                  child: const Text('See all'),
                ),
              ],
            ),
            announcementsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: LoadingView(),
              ),
              error: (err, _) => ErrorRetryView(
                error: err,
                onRetry: () => ref.invalidate(myAnnouncementsProvider),
              ),
              data: (announcements) {
                if (announcements.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Text('No announcements yet.'),
                  );
                }
                return Column(
                  children: announcements
                      .take(2)
                      .map((a) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.campaign_outlined, color: AppBrand.secondary),
                            title: Text(a.title),
                            subtitle: Text(a.body, maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () => context.push('/announcements'),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
