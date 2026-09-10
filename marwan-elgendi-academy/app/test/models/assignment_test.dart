import 'package:flutter_test/flutter_test.dart';
import 'package:marwan_elgendi_academy/models/assignment.dart';

void main() {
  group('Assignment', () {
    test('is not closed when the deadline is in the future', () {
      final assignment = Assignment(
        id: '1',
        title: 'Homework',
        deadline: DateTime.now().toUtc().add(const Duration(days: 1)),
        manuallyClosed: false,
      );
      expect(assignment.isClosed, isFalse);
      expect(assignment.effectiveStatus, SubmissionStatus.notSubmitted);
    });

    test('is closed once the deadline has passed', () {
      final assignment = Assignment(
        id: '1',
        title: 'Homework',
        deadline: DateTime.now().toUtc().subtract(const Duration(days: 1)),
        manuallyClosed: false,
      );
      expect(assignment.isClosed, isTrue);
      expect(assignment.effectiveStatus, SubmissionStatus.closed);
    });

    test('is closed when manually closed even before the deadline', () {
      final assignment = Assignment(
        id: '1',
        title: 'Homework',
        deadline: DateTime.now().toUtc().add(const Duration(days: 1)),
        manuallyClosed: true,
      );
      expect(assignment.isClosed, isTrue);
    });

    test('effectiveStatus reflects the submission once one exists', () {
      final assignment = Assignment(
        id: '1',
        title: 'Homework',
        deadline: DateTime.now().toUtc().add(const Duration(days: 1)),
        manuallyClosed: false,
        mySubmission: AssignmentSubmission(
          id: 's1',
          assignmentId: '1',
          studentId: 'u1',
          photoStoragePath: 'assignment-submissions/1/u1/photo.jpg',
          status: SubmissionStatus.graded,
          grade: 18,
          maxGrade: 20,
          submittedAt: DateTime.now().toUtc(),
        ),
      );
      expect(assignment.effectiveStatus, SubmissionStatus.graded);
    });
  });
}
