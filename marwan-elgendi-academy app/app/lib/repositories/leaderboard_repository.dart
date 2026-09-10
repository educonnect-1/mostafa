import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/errors/exception_mapper.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardRepository {
  LeaderboardRepository(this._client);

  final SupabaseClient _client;

  /// Distinguishes "leaderboard disabled" from "no grades yet" — the
  /// `get_leaderboard` RPC alone can't tell those apart since both
  /// return an empty list (spec §26 — never show it when disabled).
  Future<bool> isEnabled(String groupId) {
    return runGuarded(() async {
      final row = await _client
          .from('leaderboard_settings')
          .select('enabled')
          .eq('group_id', groupId)
          .maybeSingle();
      return (row?['enabled'] as bool?) ?? false;
    });
  }

  Future<List<LeaderboardEntry>> getLeaderboard(String groupId) {
    return runGuarded(() async {
      final rows = await _client.rpc('get_leaderboard', params: {'p_group_id': groupId});
      return (rows as List)
          .map((r) => LeaderboardEntry.fromJson(r as Map<String, dynamic>))
          .toList();
    });
  }
}

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(SupabaseConfig.client);
});
