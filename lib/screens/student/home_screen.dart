import 'package:flutter/material.dart';
import '../../repositories/course_repository.dart';
import '../../models/course.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});
  @override State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}
class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final repo = CourseRepository();
  late Future<List<Course>> future;

  @override void initState() { super.initState(); future = repo.publishedCourses(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('EduConnect')),
    body: RefreshIndicator(
      onRefresh: () async => setState(() => future = repo.publishedCourses()),
      child: FutureBuilder<List<Course>>(
        future: future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Unable to load courses: ${snap.error}'));
          final courses = snap.data ?? [];
          if (courses.isEmpty) return const Center(child: Text('No published courses yet.'));
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => Card(
              child: ListTile(
                title: Text(courses[i].title),
                subtitle: Text(courses[i].description),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          );
        },
      ),
    ),
  );
}
