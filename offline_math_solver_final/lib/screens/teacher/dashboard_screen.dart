import 'package:flutter/material.dart';
import '../../repositories/course_repository.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});
  @override State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}
class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final title = TextEditingController();
  final description = TextEditingController();
  bool busy = false;
  String? message;

  Future<void> createCourse() async {
    if (title.text.trim().isEmpty) return;
    setState(() { busy = true; message = null; });
    try {
      await CourseRepository().create(title: title.text.trim(), description: description.text.trim());
      title.clear(); description.clear();
      setState(() => message = 'Course created.');
    } catch (e) {
      setState(() => message = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Teacher Dashboard')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Create a course', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Course title')),
        const SizedBox(height: 12),
        TextField(controller: description, maxLines: 4, decoration: const InputDecoration(labelText: 'Description')),
        const SizedBox(height: 14),
        FilledButton(onPressed: busy ? null : createCourse, child: Text(busy ? 'Creating…' : 'Create course')),
        if (message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(message!)),
        const SizedBox(height: 28),
        const ListTile(title: Text('Manage lessons'), trailing: Icon(Icons.chevron_right)),
        const ListTile(title: Text('Create quizzes'), trailing: Icon(Icons.chevron_right)),
        const ListTile(title: Text('Students'), trailing: Icon(Icons.chevron_right)),
        const ListTile(title: Text('Groups'), trailing: Icon(Icons.chevron_right)),
      ],
    ),
  );
}
