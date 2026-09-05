import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class StorageService {
  final SupabaseClient _client = SupabaseService.instance.client;

  Future<String> createSignedVideoUrl(String lessonId) async {
    final response = await _client.functions.invoke(
      'create-signed-url',
      body: {'lesson_id': lessonId},
    );
    final data = response.data as Map<String, dynamic>;
    return data['url'] as String;
  }

  Future<String> createUploadUrl({
    required String courseId,
    required String fileName,
    required String contentType,
  }) async {
    final response = await _client.functions.invoke(
      'create-upload-url',
      body: {
        'course_id': courseId,
        'file_name': fileName,
        'content_type': contentType,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return data['url'] as String;
  }
}
