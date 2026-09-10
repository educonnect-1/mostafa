import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/errors/exception_mapper.dart';
import '../models/calendar_event.dart';

/// RLS (`calendar_select_relevant_or_teacher` in schema.sql) already
/// scopes results to global events plus events for the student's own
/// groups.
class CalendarRepository {
  CalendarRepository(this._client);

  final SupabaseClient _client;

  Future<List<CalendarEventItem>> getMyEvents() {
    return runGuarded(() async {
      final rows = await _client.from('calendar_events').select().order('starts_at');
      return (rows as List)
          .map((r) => CalendarEventItem.fromJson(r as Map<String, dynamic>))
          .toList();
    });
  }
}

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(SupabaseConfig.client);
});
