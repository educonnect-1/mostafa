class Course {
  final String id;
  final String teacherId;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final bool published;

  const Course({
    required this.id,
    required this.teacherId,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.published,
  });

  factory Course.fromMap(Map<String, dynamic> map) => Course(
    id: map['id'] as String,
    teacherId: map['teacher_id'] as String,
    title: map['title'] as String,
    description: map['description'] as String? ?? '',
    thumbnailUrl: map['thumbnail_url'] as String?,
    published: map['published'] as bool? ?? false,
  );
}
