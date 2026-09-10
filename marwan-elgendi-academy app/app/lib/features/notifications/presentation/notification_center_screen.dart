import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/notification_deep_link.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_state_view.dart';
import '../../../models/app_notification.dart';
import '../application/notifications_controller.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationsControllerProvider).markAllAsRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorRetryView(
          error: err,
          onRetry: () => ref.invalidate(notificationsStreamProvider),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyView(
              icon: Icons.notifications_none,
              title: 'No notifications yet',
            );
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _NotificationTile(notification: notifications[i]),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});
  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      tileColor: notification.read ? null : AppBrand.primary.withOpacity(0.05),
      leading: CircleAvatar(
        backgroundColor: AppBrand.primary.withOpacity(0.1),
        child: Icon(_iconFor(notification.iconName), color: AppBrand.primary),
      ),
      title: Text(
        notification.title,
        style: TextStyle(fontWeight: notification.read ? FontWeight.normal : FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            DateFormat.yMMMd().add_jm().format(notification.createdAt.toLocal()),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      isThreeLine: true,
      onTap: () {
        if (!notification.read) {
          ref.read(notificationsControllerProvider).markAsRead(notification.id);
        }
        final path = deepLinkPathForNotificationData({
          'type': _typeKey(notification.type),
          ...notification.data,
        });
        context.push(path);
      },
    );
  }

  String _typeKey(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.liveRoom:
        return 'live_room';
      case AppNotificationType.newAssignment:
        return 'new_assignment';
      case AppNotificationType.newExam:
        return 'new_exam';
      case AppNotificationType.announcement:
        return 'announcement';
      case AppNotificationType.assignmentGraded:
        return 'assignment_graded';
      case AppNotificationType.examGraded:
        return 'exam_graded';
      case AppNotificationType.general:
        return 'general';
    }
  }

  IconData _iconFor(IconDataName name) {
    switch (name) {
      case IconDataName.liveRoom:
        return Icons.videocam;
      case IconDataName.assignment:
        return Icons.assignment;
      case IconDataName.exam:
        return Icons.quiz;
      case IconDataName.announcement:
        return Icons.campaign;
      case IconDataName.general:
        return Icons.notifications;
    }
  }
}
