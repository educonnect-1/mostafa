import 'package:flutter_test/flutter_test.dart';
import 'package:marwan_elgendi_academy/models/exam.dart';

void main() {
  group('Exam.canStartOrContinue', () {
    test('true when deadline is in the future and not manually closed', () {
      final exam = Exam(
        id: '1',
        title: 'Midterm',
        deadline: DateTime.now().toUtc().add(const Duration(hours: 1)),
        durationMinutes: 60,
        allowLateSubmission: false,
        manuallyClosed: false,
      );
      expect(exam.canStartOrContinue, isTrue);
    });

    test('false once the deadline passes and late submission is not allowed', () {
      final exam = Exam(
        id: '1',
        title: 'Midterm',
        deadline: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        durationMinutes: 60,
        allowLateSubmission: false,
        manuallyClosed: false,
      );
      expect(exam.canStartOrContinue, isFalse);
    });

    test('true past the deadline when late submission is explicitly allowed', () {
      final exam = Exam(
        id: '1',
        title: 'Midterm',
        deadline: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        durationMinutes: 60,
        allowLateSubmission: true,
        manuallyClosed: false,
      );
      expect(exam.canStartOrContinue, isTrue);
    });

    test('false when manually closed regardless of deadline', () {
      final exam = Exam(
        id: '1',
        title: 'Midterm',
        deadline: DateTime.now().toUtc().add(const Duration(hours: 1)),
        durationMinutes: 60,
        allowLateSubmission: true,
        manuallyClosed: true,
      );
      expect(exam.canStartOrContinue, isFalse);
    });
  });
}
