import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/errors/exception_mapper.dart';
import '../models/announcement.dart';

/// RLS (`announcements_select_member_or_teacher` in schema.sql) already
/// scopes results to announcements targeting one of the student's
/// groups — no group filter needed client-side.
class AnnouncementRepository {
  AnnouncementRepository(this._client);

  final SupabaseClient _client;

  Future<List<Announcement>> getMyAnnouncements() {
    return runGuarded(() async {
      final rows = await _client
          .from('announcements')
          .select()
          .order('created_at', ascending: false);
      return (rows as List)
          .map((r) => Announcement.fromJson(r as Map<String, dynamic>))
          .toList();
    });
  }
}

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository(SupabaseConfig.client);
});
