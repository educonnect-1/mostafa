import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/group.dart';
import '../application/groups_controller.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Groups')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myGroupsProvider.future),
        child: groupsAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => ErrorRetryView(
            error: err,
            onRetry: () => ref.invalidate(myGroupsProvider),
          ),
          data: (groups) {
            if (groups.isEmpty) {
              return const EmptyView(
                icon: Icons.groups_outlined,
                title: 'No groups yet',
                subtitle: 'Your teacher will add you to a group once one is available.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _GroupTile(group: groups[index]),
            );
          },
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: AppBrand.primary.withOpacity(0.1),
          child: const Icon(Icons.groups, color: AppBrand.primary),
        ),
        title: Text(group.name, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text('${group.memberCount} members'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/groups/${group.id}'),
      ),
    );
  }
}
