import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<List<Map<String,dynamic>>> load() async {
    final id = SupabaseService.instance.currentUser?.id;
    if (id == null) return [];
    final rows = await SupabaseService.instance.client
      .from('notifications').select().eq('user_id', id).order('created_at', ascending: false);
    return List<Map<String,dynamic>>.from(rows);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notifications')),
    body: FutureBuilder<List<Map<String,dynamic>>>(
      future: load(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final rows = snap.data!;
        if (rows.isEmpty) return const Center(child: Text('No notifications.'));
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(rows[i]['title'] as String? ?? ''),
            subtitle: Text(rows[i]['body'] as String? ?? ''),
          ),
        );
      },
    ),
  );
}
