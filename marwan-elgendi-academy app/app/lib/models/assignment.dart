import 'package:equatable/equatable.dart';

enum SubmissionStatus { notSubmitted, submitted, graded, closed }

SubmissionStatus _statusFromString(String? value) {
  switch (value) {
    case 'submitted':
      return SubmissionStatus.submitted;
    case 'graded':
      return SubmissionStatus.graded;
    case 'closed':
      return SubmissionStatus.closed;
    default:
      return SubmissionStatus.notSubmitted;
  }
}

class Assignment extends Equatable {
  const Assignment({
    required this.id,
    required this.title,
    this.description,
    required this.deadline,
    required this.manuallyClosed,
    this.mySubmission,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime deadline;
  final bool manuallyClosed;
  final AssignmentSubmission? mySubmission;

  bool get isPastDeadline => DateTime.now().toUtc().isAfter(deadline.toUtc());
  bool get isClosed => manuallyClosed || isPastDeadline;

  SubmissionStatus get effectiveStatus {
    if (mySubmission != null) return mySubmission!.status;
    return isClosed ? SubmissionStatus.closed : SubmissionStatus.notSubmitted;
  }

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      deadline: DateTime.parse(json['deadline'] as String),
      manuallyClosed: (json['manually_closed'] as bool?) ?? false,
      mySubmission: json['assignment_submissions'] is List &&
              (json['assignment_submissions'] as List).isNotEmpty
          ? AssignmentSubmission.fromJson(
              (json['assignment_submissions'] as List).first as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, title, description, deadline, manuallyClosed, mySubmission];
}

class AssignmentSubmission extends Equatable {
  const AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.photoStoragePath,
    required this.status,
    this.grade,
    required this.maxGrade,
    this.teacherComment,
    required this.submittedAt,
    this.gradedAt,
  });

  final String id;
  final String assignmentId;
  final String studentId;
  final String photoStoragePath;
  final SubmissionStatus status;
  final double? grade;
  final double maxGrade;
  final String? teacherComment;
  final DateTime submittedAt;
  final DateTime? gradedAt;

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmission(
      id: json['id'] as String,
      assignmentId: json['assignment_id'] as String,
      studentId: json['student_id'] as String,
      photoStoragePath: json['photo_storage_path'] as String,
      status: _statusFromString(json['status'] as String?),
      grade: (json['grade'] as num?)?.toDouble(),
      maxGrade: ((json['max_grade'] as num?) ?? 20).toDouble(),
      teacherComment: json['teacher_comment'] as String?,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      gradedAt: json['graded_at'] == null
          ? null
          : DateTime.parse(json['graded_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        assignmentId,
        studentId,
        photoStoragePath,
        status,
        grade,
        maxGrade,
        teacherComment,
        submittedAt,
        gradedAt,
      ];
}
