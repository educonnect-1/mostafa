import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:marwan_elgendi_academy/models/assignment.dart';
import 'package:marwan_elgendi_academy/models/attendance_record.dart';
import 'package:marwan_elgendi_academy/models/exam.dart';
import 'package:marwan_elgendi_academy/repositories/assignment_repository.dart';
import 'package:marwan_elgendi_academy/repositories/attendance_repository.dart';
import 'package:marwan_elgendi_academy/repositories/exam_repository.dart';
import 'package:marwan_elgendi_academy/repositories/progress_repository.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

class MockExamRepository extends Mock implements ExamRepository {}

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

AssignmentSubmission _submission({
  required SubmissionStatus status,
  double? grade,
  double maxGrade = 20,
}) {
  return AssignmentSubmission(
    id: 's',
    assignmentId: 'a',
    studentId: 'u',
    photoStoragePath: 'path.jpg',
    status: status,
    grade: grade,
    maxGrade: maxGrade,
    submittedAt: DateTime.now().toUtc(),
  );
}

void main() {
  late MockAssignmentRepository assignments;
  late MockExamRepository exams;
  late MockAttendanceRepository attendance;
  late ProgressRepository repository;

  setUp(() {
    assignments = MockAssignmentRepository();
    exams = MockExamRepository();
    attendance = MockAttendanceRepository();
    repository = ProgressRepository(assignments, exams, attendance);
  });

  test('averages graded assignment percentages correctly', () async {
    when(() => assignments.getMyAssignments()).thenAnswer((_) async => [
          Assignment(
            id: '1',
            title: 'A1',
            deadline: DateTime.now().toUtc(),
            manuallyClosed: false,
            mySubmission: _submission(status: SubmissionStatus.graded, grade: 18, maxGrade: 20), // 90%
          ),
          Assignment(
            id: '2',
            title: 'A2',
            deadline: DateTime.now().toUtc(),
            manuallyClosed: false,
            mySubmission: _submission(status: SubmissionStatus.graded, grade: 15, maxGrade: 20), // 75%
          ),
          Assignment(
            id: '3',
            title: 'A3 (not yet graded)',
            deadline: DateTime.now().toUtc(),
            manuallyClosed: false,
            mySubmission: _submission(status: SubmissionStatus.submitted),
          ),
        ]);
    when(() => exams.getMyExams()).thenAnswer((_) async => []);
    when(() => attendance.getMyAttendance()).thenAnswer((_) async => []);

    final summary = await repository.getMyProgress();

    expect(summary.totalAssignments, 3);
    expect(summary.submittedAssignments, 3);
    expect(summary.gradedAssignments, 2);
    expect(summary.averageAssignmentPercent, closeTo(82.5, 0.001)); // (90+75)/2
  });

  test('computes attendance percentage counting present and late as attended', () async {
    when(() => assignments.getMyAssignments()).thenAnswer((_) async => []);
    when(() => exams.getMyExams()).thenAnswer((_) async => []);
    when(() => attendance.getMyAttendance()).thenAnswer((_) async => [
          AttendanceRecord(
            id: '1',
            status: AttendanceStatus.present,
            sessionDate: DateTime.now(),
            groupName: 'G',
          ),
          AttendanceRecord(
            id: '2',
            status: AttendanceStatus.late,
            sessionDate: DateTime.now(),
            groupName: 'G',
          ),
          AttendanceRecord(
            id: '3',
            status: AttendanceStatus.absent,
            sessionDate: DateTime.now(),
            groupName: 'G',
          ),
          AttendanceRecord(
            id: '4',
            status: AttendanceStatus.excused,
            sessionDate: DateTime.now(),
            groupName: 'G',
          ),
        ]);

    final summary = await repository.getMyProgress();

    // 2 of 4 (present + late) = 50%
    expect(summary.attendancePercent, closeTo(50.0, 0.001));
  });

  test('returns null averages/attendance when there is no data yet', () async {
    when(() => assignments.getMyAssignments()).thenAnswer((_) async => []);
    when(() => exams.getMyExams()).thenAnswer((_) async => []);
    when(() => attendance.getMyAttendance()).thenAnswer((_) async => []);

    final summary = await repository.getMyProgress();

    expect(summary.averageAssignmentPercent, isNull);
    expect(summary.averageExamPercent, isNull);
    expect(summary.attendancePercent, isNull);
    expect(summary.assignmentCompletionRatio, 0);
  });
}
