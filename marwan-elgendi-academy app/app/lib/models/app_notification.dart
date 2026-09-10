import 'package:equatable/equatable.dart';

enum AppNotificationType {
  liveRoom,
  newAssignment,
  newExam,
  announcement,
  assignmentGraded,
  examGraded,
  general,
}

AppNotificationType _typeFromString(String? value) {
  switch (value) {
    case 'live_room':
      return AppNotificationType.liveRoom;
    case 'new_assignment':
      return AppNotificationType.newAssignment;
    case 'new_exam':
      return AppNotificationType.newExam;
    case 'announcement':
      return AppNotificationType.announcement;
    case 'assignment_graded':
      return AppNotificationType.assignmentGraded;
    case 'exam_graded':
      return AppNotificationType.examGraded;
    default:
      return AppNotificationType.general;
  }
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime createdAt;

  IconDataName get iconName {
    switch (type) {
      case AppNotificationType.liveRoom:
        return IconDataName.liveRoom;
      case AppNotificationType.newAssignment:
      case AppNotificationType.assignmentGraded:
        return IconDataName.assignment;
      case AppNotificationType.newExam:
      case AppNotificationType.examGraded:
        return IconDataName.exam;
      case AppNotificationType.announcement:
        return IconDataName.announcement;
      case AppNotificationType.general:
        return IconDataName.general;
    }
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: _typeFromString(json['type'] as String?),
      title: json['title'] as String,
      body: json['body'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      read: (json['read'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, type, title, body, data, read, createdAt];
}

/// Kept decoupled from Flutter's IconData so the model has no UI
/// dependency; the presentation layer maps this to an actual icon.
enum IconDataName { liveRoom, assignment, exam, announcement, general }
