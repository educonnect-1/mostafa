import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/exception_mapper.dart';
import '../models/attendance_record.dart';

/// RLS (`attendance_records_select_own_or_teacher` in schema.sql)
/// already restricts students to their own records.
class AttendanceRepository {
  AttendanceRepository(this._client);

  final SupabaseClient _client;

  Future<List<AttendanceRecord>> getMyAttendance() {
    return runGuarded(() async {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw const SessionExpiredException();
      final rows = await _client
          .from('attendance_records')
          .select('*, session:attendance_sessions(session_date, group:groups(name))')
          .eq('student_id', uid)
          .order('created_at', ascending: false);
      return (rows as List)
          .map((r) => AttendanceRecord.fromJson(r as Map<String, dynamic>))
          .toList();
    });
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(SupabaseConfig.client);
});
