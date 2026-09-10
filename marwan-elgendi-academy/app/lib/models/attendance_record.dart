import 'package:equatable/equatable.dart';

enum AttendanceStatus { present, late, absent, excused }

AttendanceStatus _statusFromString(String value) {
  return AttendanceStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => AttendanceStatus.absent,
  );
}

class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.id,
    required this.status,
    required this.sessionDate,
    required this.groupName,
  });

  final String id;
  final AttendanceStatus status;
  final DateTime sessionDate;
  final String groupName;

  /// Expects a row selected with a nested session + group, e.g.
  /// `.select('*, session:attendance_sessions(session_date, group:groups(name))')`.
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final session = json['session'] as Map<String, dynamic>?;
    final group = session?['group'] as Map<String, dynamic>?;
    return AttendanceRecord(
      id: json['id'] as String,
      status: _statusFromString(json['status'] as String),
      sessionDate: DateTime.parse(session?['session_date'] as String),
      groupName: (group?['name'] as String?) ?? 'Unknown group',
    );
  }

  @override
  List<Object?> get props => [id, status, sessionDate, groupName];
}
