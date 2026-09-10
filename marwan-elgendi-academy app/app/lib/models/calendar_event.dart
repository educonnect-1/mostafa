import 'package:equatable/equatable.dart';

enum CalendarEventType { liveClass, assignmentDeadline, examDeadline, event }

CalendarEventType _typeFromString(String value) {
  switch (value) {
    case 'live_class':
      return CalendarEventType.liveClass;
    case 'assignment_deadline':
      return CalendarEventType.assignmentDeadline;
    case 'exam_deadline':
      return CalendarEventType.examDeadline;
    default:
      return CalendarEventType.event;
  }
}

class CalendarEventItem extends Equatable {
  const CalendarEventItem({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.startsAt,
    this.endsAt,
  });

  final String id;
  final String title;
  final String? description;
  final CalendarEventType type;
  final DateTime startsAt;
  final DateTime? endsAt;

  factory CalendarEventItem.fromJson(Map<String, dynamic> json) {
    return CalendarEventItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: _typeFromString(json['event_type'] as String),
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: json['ends_at'] == null ? null : DateTime.parse(json['ends_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, title, description, type, startsAt, endsAt];
}
