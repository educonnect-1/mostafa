import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/profile.dart';
import '../application/groups_controller.dart';

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupByIdProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.maybeWhen(
          data: (g) => Text(g.name),
          orElse: () => const Text('Group'),
        ),
      ),
      body: groupAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorRetryView(
          error: err,
          onRetry: () => ref.invalidate(groupByIdProvider(groupId)),
        ),
        data: (group) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(groupByIdProvider(groupId));
            ref.invalidate(groupMembersProvider(groupId));
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (group.description != null && group.description!.isNotEmpty) ...[
                Text(group.description!, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
              ],
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.chat_bubble_outline,
                    color: group.chatEnabled
                        ? AppBrand.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                  title: const Text('Group Chat'),
                  subtitle: Text(
                    group.chatEnabled
                        ? 'Chat with your group'
                        : 'Chat is currently disabled by your teacher',
                  ),
                  trailing: group.chatEnabled ? const Icon(Icons.chevron_right) : null,
                  enabled: group.chatEnabled,
                  onTap: group.chatEnabled
                      ? () => context.push('/groups/$groupId/chat')
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.leaderboard_outlined, color: AppBrand.secondary),
                  title: const Text('Leaderboard'),
                  subtitle: const Text('See how the group is ranked'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/groups/$groupId/leaderboard', extra: group.name),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.folder_open_outlined, color: AppBrand.primary),
                  title: const Text('Resources'),
                  subtitle: const Text('Files and links shared with your groups'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/resources'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Members (${group.memberCount})',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              membersAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: LoadingView(),
                ),
                error: (err, _) => ErrorRetryView(
                  error: err,
                  onRetry: () => ref.invalidate(groupMembersProvider(groupId)),
                ),
                data: (members) => Column(
                  children: members.map((m) => _MemberTile(profile: m)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.profile});
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundImage:
                profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
            child: profile.avatarUrl == null
                ? Text(profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : '?')
                : null,
          ),
          if (profile.online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppBrand.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(profile.fullName),
      subtitle: Text(profile.online ? 'Online' : _lastSeenLabel(profile.lastSeenAt)),
    );
  }

  String _lastSeenLabel(DateTime? lastSeen) {
    if (lastSeen == null) return 'Offline';
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return 'Last seen just now';
    if (diff.inHours < 1) return 'Last seen ${diff.inMinutes}m ago';
    if (diff.inDays < 1) return 'Last seen ${diff.inHours}h ago';
    return 'Last seen ${diff.inDays}d ago';
  }
}
