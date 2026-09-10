import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/leaderboard_entry.dart';
import '../../../repositories/leaderboard_repository.dart';

final leaderboardEnabledProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, groupId) {
  return ref.read(leaderboardRepositoryProvider).isEnabled(groupId);
});

final leaderboardProvider =
    FutureProvider.autoDispose.family<List<LeaderboardEntry>, String>((ref, groupId) {
  return ref.read(leaderboardRepositoryProvider).getLeaderboard(groupId);
});

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key, required this.groupId, required this.groupName});
  final String groupId;
  final String groupName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledAsync = ref.watch(leaderboardEnabledProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: Text('$groupName Leaderboard')),
      body: enabledAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorRetryView(
          error: err,
          onRetry: () => ref.invalidate(leaderboardEnabledProvider(groupId)),
        ),
        data: (enabled) {
          if (!enabled) {
            return const EmptyView(
              icon: Icons.leaderboard_outlined,
              title: 'Leaderboard is not enabled',
              subtitle: 'Your teacher hasn\'t turned this on for this group yet.',
            );
          }
          return _LeaderboardList(groupId: groupId);
        },
      ),
    );
  }
}

class _LeaderboardList extends ConsumerWidget {
  const _LeaderboardList({required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(leaderboardProvider(groupId));

    return RefreshIndicator(
      onRefresh: () => ref.refresh(leaderboardProvider(groupId).future),
      child: entriesAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorRetryView(
          error: err,
          onRetry: () => ref.invalidate(leaderboardProvider(groupId)),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const EmptyView(
              icon: Icons.leaderboard_outlined,
              title: 'No grades yet',
              subtitle: 'The leaderboard will fill in as assignments are graded.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, i) => _RankTile(rank: i + 1, entry: entries[i]),
          );
        },
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({required this.rank, required this.entry});
  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };

    return Card(
      child: ListTile(
        leading: SizedBox(
          width: 40,
          child: Center(
            child: medal != null
                ? Text(medal, style: const TextStyle(fontSize: 20))
                : Text('$rank', style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        title: Text(entry.fullName),
        trailing: Text(
          entry.averageGrade != null ? entry.averageGrade!.toStringAsFixed(1) : '—',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppBrand.primary),
        ),
      ),
    );
  }
}
