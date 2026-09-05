import 'package:flutter/material.dart';
import '../../repositories/profile_repository.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  final name = TextEditingController();
  final bio = TextEditingController();
  bool loading = true;

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    final profile = await ProfileRepository().current();
    if (profile != null) { name.text = profile.fullName; bio.text = profile.bio; }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: loading ? const Center(child: CircularProgressIndicator()) :
      ListView(padding: const EdgeInsets.all(20), children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
        const SizedBox(height: 12),
        TextField(controller: bio, maxLines: 4, decoration: const InputDecoration(labelText: 'Bio')),
        const SizedBox(height: 16),
                FilledButton(onPressed: () async {
          await ProfileRepository().update(fullName: name.text.trim(), bio: bio.text.trim());
          
          // استخدم context.mounted بدلاً من mounted
          if (!context.mounted) return; 
          
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved.')));
        }, child: const Text('Save')),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: () => AuthService().signOut(), child: const Text('Sign out')),
      ]),
  );
}
