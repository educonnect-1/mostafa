import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/announcement.dart';
import '../application/announcements_controller.dart';

class AnnouncementsListScreen extends ConsumerWidget {
  const AnnouncementsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(myAnnouncementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myAnnouncementsProvider.future),
        child: announcementsAsync.when(
          loading: () => const LoadingView(),
          error: (err, _) => ErrorRetryView(
            error: err,
            onRetry: () => ref.invalidate(myAnnouncementsProvider),
          ),
          data: (announcements) {
            if (announcements.isEmpty) {
              return const EmptyView(
                icon: Icons.campaign_outlined,
                title: 'No announcements yet',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: announcements.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => _AnnouncementTile(announcement: announcements[i]),
            );
          },
        ),
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.announcement});
  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.campaign, color: AppBrand.secondary),
        title: Text(announcement.title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(DateFormat.yMMMd().add_jm().format(announcement.createdAt.toLocal())),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(announcement.body),
          ),
        ],
      ),
    );
  }
}
