import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/app_notification.dart';
import '../../../repositories/notification_repository.dart';

final notificationsStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  return ref.read(notificationRepositoryProvider).watchMyNotifications();
});

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notifications = ref.watch(notificationsStreamProvider).valueOrNull ?? const [];
  return notifications.where((n) => !n.read).length;
});

class NotificationsController {
  NotificationsController(this._repository);
  final NotificationRepository _repository;

  Future<void> markAsRead(String id) => _repository.markAsRead(id);
  Future<void> markAllAsRead() => _repository.markAllAsRead();
}

final notificationsControllerProvider = Provider<NotificationsController>((ref) {
  return NotificationsController(ref.read(notificationRepositoryProvider));
});
