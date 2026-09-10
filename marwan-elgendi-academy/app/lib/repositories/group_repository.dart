import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/errors/exception_mapper.dart';
import '../models/group.dart';
import '../models/profile.dart';

/// Lists and fetches groups. No explicit "where student_id = me" filter
/// is needed for the base queries — `groups_select_member_or_teacher`
/// in schema.sql already restricts `select` on `groups` to rows the
/// signed-in student is a member of (or the teacher, who sees all).
/// This is the RLS-is-authoritative pattern the spec requires (§5).
class GroupRepository {
  GroupRepository(this._client);

  final SupabaseClient _client;

  Future<List<Group>> getMyGroups() {
    return runGuarded(() async {
      final rows = await _client
          .from('groups')
          .select('*, group_members(count)')
          .order('name');
      return (rows as List)
          .map((r) => Group.fromJson(r as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Group> getGroupById(String groupId) {
    return runGuarded(() async {
      final row = await _client
          .from('groups')
          .select('*, group_members(count)')
          .eq('id', groupId)
          .single();
      return Group.fromJson(row);
    });
  }

  /// Privacy-safe member list — see ProfileRepository.getGroupMemberProfiles.
  Future<List<Profile>> getGroupMembers(String groupId) {
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
}

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(SupabaseConfig.client);
});
