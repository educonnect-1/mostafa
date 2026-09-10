import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

import '../core/errors/app_exception.dart';

/// Wraps the Jitsi Meet SDK. The student app only ever *consumes* a
/// room URL the teacher already created via the dashboard (spec §11)
/// — there is no room-creation path here at all.
///
/// NOTE: this was written without the ability to run `flutter pub get`
/// or `flutter analyze` in this environment (see README). Verify the
/// `JitsiMeetConferenceOptions`/`JitsiMeetUserInfo` constructor shape
/// against the exact `jitsi_meet_flutter_sdk` version pinned in
/// pubspec.yaml on first local build — the SDK's public API has
/// changed across versions.
class JitsiService {
  final JitsiMeet _jitsiMeet = JitsiMeet();

  Future<void> joinRoom({
    required String roomUrl,
    required String displayName,
    String? subject,
    String? avatarUrl,
  }) async {
    final Uri uri;
    try {
      uri = Uri.parse(roomUrl);
    } catch (_) {
      throw const ValidationAppException('This room\'s link looks invalid.');
    }

    final serverUrl = '${uri.scheme}://${uri.host}';
    final roomName =
        uri.pathSegments.isNotEmpty ? uri.pathSegments.last : uri.path.replaceAll('/', '');

    if (roomName.isEmpty) {
      throw const ValidationAppException('This room\'s link is missing a room name.');
    }

    final options = JitsiMeetConferenceOptions(
      serverURL: serverUrl,
      room: roomName,
      subject: subject,
      userInfo: JitsiMeetUserInfo(
        displayName: displayName,
        avatar: avatarUrl,
      ),
      featureFlags: const {
        'invite.enabled': false,
        'add-people.enabled': false,
        'live-streaming.enabled': false,
        'meeting-name.enabled': false,
        'welcomepage.enabled': false,
      },
      configOverrides: const {
        'startWithAudioMuted': true,
        'startWithVideoMuted': false,
        'prejoinPageEnabled': true,
      },
    );

    try {
      await _jitsiMeet.join(options);
    } catch (_) {
      throw const UnknownAppException(
        'Could not join the live class. Please check your connection and try again.',
      );
    }
  }

  Future<void> hangUp() => _jitsiMeet.hangUp();
}

final jitsiServiceProvider = Provider<JitsiService>((ref) => JitsiService());
