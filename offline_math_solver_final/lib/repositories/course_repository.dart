import '../models/course.dart';
import '../services/supabase_service.dart';

class CourseRepository {
  final _client = SupabaseService.instance.client;

  Future<List<Course>> publishedCourses() async {
    final rows = await _client.from('courses')
        .select()
        .eq('published', true)
        .order('created_at', ascending: false);
    return rows.map<Course>((e) => Course.fromMap(e)).toList();
  }

  Future<Course> create({
    required String title,
    required String description,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    final row = await _client.from('courses').insert({
      'teacher_id': user.id,
      'title': title,
      'description': description,
    }).select().single();
    return Course.fromMap(row);
  }

  Future<void> publish(String courseId, bool value) async {
    await _client.from('courses').update({'published': value}).eq('id', courseId);
  }
}
