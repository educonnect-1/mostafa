import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/profile_repository.dart';

/// Tracks app foreground/background state and writes online/last_seen_at
/// at most once per [_minInterval], per spec §10 ("avoid excessive
/// database writes... use throttling/debouncing").
///
/// Wire this up once in main.dart:
/// ```dart
/// WidgetsBinding.instance.addObserver(presenceService);
/// ```
class PresenceService with WidgetsBindingObserver {
  PresenceService(this._profileRepository);

  final ProfileRepository _profileRepository;
  static const _minInterval = Duration(seconds: 30);
  static const _heartbeatInterval = Duration(minutes: 2);

  DateTime? _lastWrite;
  Timer? _heartbeat;

  Future<void> start() async {
    await _writeOnline(true);
    _heartbeat = Timer.periodic(_heartbeatInterval, (_) => _writeOnline(true));
  }

  void dispose() {
    _heartbeat?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _writeOnline(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _writeOnline(false, force: true);
    }
  }

  Future<void> _writeOnline(bool online, {bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _lastWrite != null &&
        now.difference(_lastWrite!) < _minInterval) {
      return;
    }
    _lastWrite = now;
    try {
      await _profileRepository.setOnlineStatus(online: online);
    } catch (_) {
      // Presence failures are non-critical; never surface to the user.
    }
  }
}

final presenceServiceProvider = Provider<PresenceService>((ref) {
  final service = PresenceService(ref.read(profileRepositoryProvider));
  ref.onDispose(service.dispose);
  return service;
});
