import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/exception_mapper.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  static const _pageSize = 50;

  Future<List<AppNotification>> getMyNotifications() {
    return runGuarded(() async {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw const SessionExpiredException();
      final rows = await _client
          .from('notifications')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(_pageSize);
      return (rows as List)
          .map((r) => AppNotification.fromJson(r as Map<String, dynamic>))
          .toList();
    });
  }

  /// Realtime so a badge count / notification center updates the
  /// instant the teacher grades something or posts an announcement —
  /// notifications persist in-app even if the OS banner was dismissed
  /// (spec §13).
  Stream<List<AppNotification>> watchMyNotifications() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const Stream.empty();
    return _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(_pageSize)
        .map((rows) => rows.map((r) => AppNotification.fromJson(r)).toList());
  }

  Future<void> markAsRead(String id) {
    return runGuarded(() async {
      await _client.from('notifications').update({'read': true}).eq('id', id);
    });
  }

  Future<void> markAllAsRead() {
    return runGuarded(() async {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('user_id', uid)
          .eq('read', false);
    });
  }

  /// A student may have multiple devices (spec §12) — this upserts so
  /// re-registering the same token on the same device is a no-op.
  Future<void> registerPushToken({required String token, required String platform}) {
    return runGuarded(() async {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;
      await _client.from('push_tokens').upsert(
        {'user_id': uid, 'token': token, 'platform': platform},
        onConflict: 'user_id,token',
      );
    });
  }

  Future<void> removePushToken(String token) {
    return runGuarded(() async {
      await _client.from('push_tokens').delete().eq('token', token);
    });
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(SupabaseConfig.client);
});
