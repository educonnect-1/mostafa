import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class MessageRepository {
  final SupabaseClient _client = SupabaseService.instance.client;

  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) {
    return _client.from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at');
  }

  Future<void> send(String conversationId, String body) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'body': body.trim(),
    });
  }
}
