import '../models/profile.dart';
import '../services/supabase_service.dart';

class ProfileRepository {
  final _client = SupabaseService.instance.client;

  Future<Profile?> current() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final row = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
    return row == null ? null : Profile.fromMap(row);
  }

  Future<void> update({required String fullName, String? bio}) async {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw StateError('Not authenticated');
    await _client.from('profiles').update({
      'full_name': fullName,
      if (bio != null) 'bio': bio,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
