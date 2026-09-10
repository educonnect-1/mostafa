import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/assignment.dart';
import '../models/attendance_record.dart';
import '../models/exam.dart';
import '../models/progress_summary.dart';
import 'assignment_repository.dart';
import 'attendance_repository.dart';
import 'exam_repository.dart';

/// Deliberately built on top of the existing repositories rather than a
/// new SQL view — every number here is already scoped by the same RLS
/// that governs assignments/exams/attendance directly, so there's no
/// separate access-control surface to get wrong (spec §25 — never
/// expose another student's progress; this only ever reads the
/// signed-in student's own rows).
class ProgressRepository {
  ProgressRepository(this._assignments, this._exams, this._attendance);

  final AssignmentRepository _assignments;
  final ExamRepository _exams;
  final AttendanceRepository _attendance;

  Future<ProgressSummary> getMyProgress() async {
    final assignments = await _assignments.getMyAssignments();
    final exams = await _exams.getMyExams();
    final attendance = await _attendance.getMyAttendance();

    final submittedAssignments = assignments.where((a) => a.mySubmission != null).length;
    final gradedAssignments =
        assignments.where((a) => a.mySubmission?.status == SubmissionStatus.graded).toList();
    final avgAssignmentPercent = _average(
      gradedAssignments.map((a) {
        final s = a.mySubmission!;
        return s.maxGrade > 0 ? (s.grade ?? 0) / s.maxGrade * 100 : 0.0;
      }),
    );

    final submittedExams = exams.where((e) => e.myAttempt != null).length;
    final gradedExams =
        exams.where((e) => e.myAttempt?.status == AttemptStatus.graded).toList();
    final avgExamPercent = _average(
      gradedExams.map((e) {
        final attempt = e.myAttempt!;
        final max = attempt.maxScore ?? 0;
        return max > 0 ? (attempt.score ?? 0) / max * 100 : 0.0;
      }),
    );

    double? attendancePercent;
    if (attendance.isNotEmpty) {
      final presentOrLate = attendance
          .where((r) => r.status == AttendanceStatus.present || r.status == AttendanceStatus.late)
          .length;
      attendancePercent = presentOrLate / attendance.length * 100;
    }

    return ProgressSummary(
      totalAssignments: assignments.length,
      submittedAssignments: submittedAssignments,
      gradedAssignments: gradedAssignments.length,
      averageAssignmentPercent: avgAssignmentPercent,
      totalExams: exams.length,
      submittedExams: submittedExams,
      gradedExams: gradedExams.length,
      averageExamPercent: avgExamPercent,
      attendancePercent: attendancePercent,
    );
  }

  double? _average(Iterable<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository(
    ref.read(assignmentRepositoryProvider),
    ref.read(examRepositoryProvider),
    ref.read(attendanceRepositoryProvider),
  );
});
