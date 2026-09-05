class Lesson {
  final String id;
  final String moduleId;
  final String title;
  final String description;
  final String? videoObjectKey;
  final int position;
  final bool isPreview;

  const Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.description,
    this.videoObjectKey,
    required this.position,
    required this.isPreview,
  });

  factory Lesson.fromMap(Map<String, dynamic> map) => Lesson(
    id: map['id'] as String,
    moduleId: map['module_id'] as String,
    title: map['title'] as String,
    description: map['description'] as String? ?? '',
    videoObjectKey: map['video_object_key'] as String?,
    position: map['position'] as int? ?? 0,
    isPreview: map['is_preview'] as bool? ?? false,
  );
}
