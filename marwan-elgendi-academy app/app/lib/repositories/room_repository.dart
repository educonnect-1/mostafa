import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/errors/exception_mapper.dart';
import '../models/room.dart';

/// RLS (`rooms_select_member_or_teacher` in schema.sql) already scopes
/// results to rooms assigned to one of the student's groups.
class RoomRepository {
  RoomRepository(this._client);

  final SupabaseClient _client;

  Future<List<Room>> getMyRooms() {
    return runGuarded(() async {
      final rows =
          await _client.from('rooms').select().order('starts_at', ascending: false);
      return (rows as List).map((r) => Room.fromJson(r as Map<String, dynamic>)).toList();
    });
  }

  Future<Room> getRoomById(String id) {
    return runGuarded(() async {
      final row = await _client.from('rooms').select().eq('id', id).single();
      return Room.fromJson(row);
    });
  }

  /// Realtime so a scheduled room flipping to "live" on the teacher's
  /// dashboard is reflected immediately without a manual refresh.
  Stream<List<Room>> watchMyRooms() {
    return _client
        .from('rooms')
        .stream(primaryKey: ['id'])
        .order('starts_at', ascending: false)
        .map((rows) => rows.map((r) => Room.fromJson(r)).toList());
  }
}

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository(SupabaseConfig.client);
});
