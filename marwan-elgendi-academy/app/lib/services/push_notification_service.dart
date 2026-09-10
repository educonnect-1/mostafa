import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/notification_repository.dart';

/// Must be a top-level function (not a class method) — this is how
/// firebase_messaging requires background handlers to be registered.
/// It intentionally does nothing: while the app is backgrounded/killed,
/// the OS displays the notification directly from the FCM payload's
/// `notification` block, and this app re-syncs the in-app notification
/// center from `public.notifications` (via realtime/refetch) once
/// foregrounded rather than duplicating that work here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Handles FCM registration/token lifecycle, foreground notification
/// display via flutter_local_notifications, and routes notification
/// taps back out through [onNotificationTap] with the deep-link
/// payload described in spec §12.
class PushNotificationService {
  PushNotificationService(this._notificationRepository);

  final NotificationRepository _notificationRepository;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Set by the app shell once the router is available. Receives the
  /// notification's `data` payload, e.g. {"type": "new_assignment",
  /// "assignment_id": "..."}.
  void Function(Map<String, dynamic> data)? onNotificationTap;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    await _initLocalNotifications();

    final token = await messaging.getToken();
    if (token != null) await _registerToken(token);
    messaging.onTokenRefresh.listen(_registerToken);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (m) => onNotificationTap?.call(m.data),
    );

    // App was launched by tapping a notification while fully closed.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      onNotificationTap?.call(initialMessage.data);
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _notificationRepository.registerPushToken(
        token: token,
        platform: Platform.isIOS ? 'ios' : 'android',
      );
    } catch (_) {
      // Token registration failing shouldn't block app usage; the
      // next successful foreground/refresh will retry.
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false, // already requested via FirebaseMessaging above
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        try {
          final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
          onNotificationTap?.call(data);
        } catch (_) {
          // Malformed payload — nothing sensible to navigate to.
        }
      },
    );
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'academy_default_channel',
      'Marwan Elgendi Academy',
      channelDescription: 'Assignments, exams, announcements, and live classes',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref.read(notificationRepositoryProvider));
});
