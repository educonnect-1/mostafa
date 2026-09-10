import 'package:equatable/equatable.dart';

class ProgressSummary extends Equatable {
  const ProgressSummary({
    required this.totalAssignments,
    required this.submittedAssignments,
    required this.gradedAssignments,
    this.averageAssignmentPercent,
    required this.totalExams,
    required this.submittedExams,
    required this.gradedExams,
    this.averageExamPercent,
    this.attendancePercent,
  });

  final int totalAssignments;
  final int submittedAssignments;
  final int gradedAssignments;
  final double? averageAssignmentPercent;

  final int totalExams;
  final int submittedExams;
  final int gradedExams;
  final double? averageExamPercent;

  final double? attendancePercent;

  double get assignmentCompletionRatio =>
      totalAssignments == 0 ? 0 : submittedAssignments / totalAssignments;

  double get examCompletionRatio => totalExams == 0 ? 0 : submittedExams / totalExams;

  @override
  List<Object?> get props => [
        totalAssignments,
        submittedAssignments,
        gradedAssignments,
        averageAssignmentPercent,
        totalExams,
        submittedExams,
        gradedExams,
        averageExamPercent,
        attendancePercent,
      ];
}
