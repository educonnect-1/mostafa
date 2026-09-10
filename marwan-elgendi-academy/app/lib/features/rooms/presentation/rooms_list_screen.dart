import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/room.dart';
import '../../../repositories/profile_repository.dart' show myProfileProvider;
import '../../../services/jitsi_service.dart';
import '../application/rooms_controller.dart';

class RoomsListScreen extends ConsumerWidget {
  const RoomsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(myRoomsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Live Classes')),
      body: roomsAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorRetryView(
          error: err,
          onRetry: () => ref.invalidate(myRoomsStreamProvider),
        ),
        data: (rooms) {
          if (rooms.isEmpty) {
            return const EmptyView(
              icon: Icons.videocam_outlined,
              title: 'No live classes scheduled',
            );
          }
          final live = rooms.where((r) => r.status == RoomStatus.live).toList();
          final scheduled = rooms.where((r) => r.status == RoomStatus.scheduled).toList();
          final past = rooms
              .where((r) => r.status == RoomStatus.ended || r.status == RoomStatus.cancelled)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (live.isNotEmpty) ...[
                _SectionHeader(label: 'Live Now'),
                ...live.map((r) => _RoomTile(room: r)),
                const SizedBox(height: AppSpacing.md),
              ],
              if (scheduled.isNotEmpty) ...[
                _SectionHeader(label: 'Upcoming'),
                ...scheduled.map((r) => _RoomTile(room: r)),
                const SizedBox(height: AppSpacing.md),
              ],
              if (past.isNotEmpty) ...[
                _SectionHeader(label: 'Past'),
                ...past.map((r) => _RoomTile(room: r)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(label, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _RoomTile extends ConsumerWidget {
  const _RoomTile({required this.room});
  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: room.isLive ? AppBrand.danger.withOpacity(0.06) : null,
      child: ListTile(
        leading: Icon(
          room.isLive ? Icons.podcasts : Icons.videocam_outlined,
          color: room.isLive ? AppBrand.danger : Theme.of(context).colorScheme.outline,
        ),
        title: Row(
          children: [
            if (room.isLive) ...[
              const Text('🔴 ', style: TextStyle(fontSize: 12)),
            ],
            Expanded(child: Text(room.title)),
          ],
        ),
        subtitle: Text(
          room.isLive
              ? room.hostDisplayName
              : room.startsAt != null
                  ? DateFormat.yMMMd().add_jm().format(room.startsAt!.toLocal())
                  : room.hostDisplayName,
        ),
        trailing: room.isLive
            ? FilledButton(
                onPressed: () => joinRoom(context, ref, room),
                child: const Text('Join'),
              )
            : null,
      ),
    );
  }
}

Future<void> joinRoom(BuildContext context, WidgetRef ref, Room room) async {
  try {
    final profile = await ref.read(myProfileProvider.future);
    if (!context.mounted) return;
    await ref.read(jitsiServiceProvider).joinRoom(
          roomUrl: room.jitsiRoomUrl,
          displayName: profile.fullName,
          subject: room.title,
          avatarUrl: profile.avatarUrl,
        );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not join the class: $e')),
    );
  }
}
