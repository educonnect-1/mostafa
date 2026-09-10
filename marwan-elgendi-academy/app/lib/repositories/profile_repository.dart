import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/exception_mapper.dart';
import '../models/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  /// Fetches the signed-in user's own full profile row (includes phone /
  /// parent_phone — this is the one context where that's appropriate).
  Future<Profile> getMyProfile() {
    return runGuarded(() async {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw const SessionExpiredException();
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', uid)
          .single();
      return Profile.fromJson(row);
    });
  }

  Future<void> updateMyProfile({
    String? fullName,
    int? age,
    String? phone,
    String? avatarUrl,
  }) {
    return runGuarded(() async {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw const SessionExpiredException();
      final updates = <String, dynamic>{
        if (fullName != null) 'full_name': fullName,
        if (age != null) 'age': age,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };
      if (updates.isEmpty) return;
      await _client.from('profiles').update(updates).eq('id', uid);
    });
  }

  /// Privacy-safe lookup for "who else is in this group" UI (chat
  /// headers, member lists, leaderboard names). Deliberately uses the
  /// `get_group_member_profiles` RPC rather than `select()` on
  /// `profiles`, so parent_phone/phone/email are never fetched
  /// client-side for anyone but the signed-in user themselves.
  Future<List<Profile>> getGroupMemberProfiles(String groupId) {
    return runGuarded(() async {
      final rows = await _client.rpc(
        'get_group_member_profiles',
        params: {'p_group_id': groupId},
      );
      return (rows as List)
          .map((r) => Profile.fromGroupMemberJson(r as Map<String, dynamic>))
          .toList();
    });
  }

  /// Presence: updates online/last_seen_at for the signed-in user only.
  /// Debounced by the caller (see PresenceService) to avoid excessive
  /// writes per spec §10.
  Future<void> setOnlineStatus({required bool online}) {
    return runGuarded(() async {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return;
      await _client.from('profiles').update({
        'online': online,
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', uid);
    });
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(SupabaseConfig.client);
});

final myProfileProvider = FutureProvider.autoDispose<Profile>((ref) {
  return ref.read(profileRepositoryProvider).getMyProfile();
});
