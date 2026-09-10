import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/room.dart';
import '../application/rooms_controller.dart';
import 'rooms_list_screen.dart' show joinRoom;

class RoomDetailScreen extends ConsumerWidget {
  const RoomDetailScreen({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomByIdProvider(roomId));

    return Scaffold(
      appBar: AppBar(title: const Text('Live Class')),
      body: roomAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorRetryView(
          error: err,
          onRetry: () => ref.invalidate(roomByIdProvider(roomId)),
        ),
        data: (room) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (room.isLive)
                const Text('🔴 Live Now', style: TextStyle(color: AppBrand.danger, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.xs),
              Text(room.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(room.hostDisplayName, style: Theme.of(context).textTheme.bodyMedium),
              if (room.startsAt != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  DateFormat.yMMMd().add_jm().format(room.startsAt!.toLocal()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (room.isLive)
                ElevatedButton.icon(
                  icon: const Icon(Icons.videocam),
                  label: const Text('Join Class'),
                  onPressed: () => joinRoom(context, ref, room),
                )
              else
                Text(
                  room.status == RoomStatus.scheduled
                      ? 'This class hasn\'t started yet.'
                      : 'This class has ended.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
