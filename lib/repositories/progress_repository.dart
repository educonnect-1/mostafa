import '../services/supabase_service.dart';

class ProgressRepository {
  final _client = SupabaseService.instance.client;

  Future<void> updateLesson({
    required String lessonId,
    required double progress,
    required bool completed,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    await _client.from('lesson_progress').upsert({
      'student_id': user.id,
      'lesson_id': lessonId,
      'progress': progress.clamp(0, 100),
      'completed': completed,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'student_id,lesson_id');
  }

  Future<Map<String, dynamic>?> getLesson(String lessonId) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _client.from('lesson_progress')
        .select()
        .eq('student_id', user.id)
        .eq('lesson_id', lessonId)
        .maybeSingle();
  }
}
