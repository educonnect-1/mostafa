import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../../repositories/progress_repository.dart';

class LessonScreen extends StatefulWidget {
  final String lessonId;
  const LessonScreen({required this.lessonId, super.key});
  @override State<LessonScreen> createState() => _LessonScreenState();
}
class _LessonScreenState extends State<LessonScreen> {
  String? url;
  bool loading = true;
  String? error;

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final signed = await StorageService().createSignedVideoUrl(widget.lessonId);
      if (mounted) setState(() { url = signed; loading = false; });
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> complete() async {
    await ProgressRepository().updateLesson(lessonId: widget.lessonId, progress: 100, completed: true);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson completed.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lesson')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
          ? Center(child: Text('Video unavailable: $error'))
          : Column(children: [
              Expanded(child: Center(child: Text(
                'Signed video URL ready. Connect this URL to the production video player.',
                textAlign: TextAlign.center,
              ))),
              if (url != null) FilledButton(onPressed: complete, child: const Text('Mark complete')),
            ]),
    ),
  );
}
