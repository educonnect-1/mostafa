import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/exception_mapper.dart';
import '../models/exam.dart';

class ExamRepository {
  ExamRepository(this._client);

  final SupabaseClient _client;

  Future<List<Exam>> getMyExams() {
    return runGuarded(() async {
      final rows = await _client
          .from('exams')
          .select('*, exam_attempts(*)')
          .order('deadline');
      return (rows as List).map((r) => Exam.fromJson(r as Map<String, dynamic>)).toList();
    });
  }

  Future<Exam> getExamById(String id) {
    return runGuarded(() async {
      final row = await _client
          .from('exams')
          .select('*, exam_attempts(*)')
          .eq('id', id)
          .single();
      return Exam.fromJson(row);
    });
  }

  /// Never queries `exam_questions` directly — that table has no
  /// student SELECT policy (schema.sql §18). This RPC is the only path
  /// to questions, and it never returns `correct_answer`.
  Future<List<ExamQuestion>> getQuestionsForStudent(String examId) {
    return runGuarded(() async {
      final rows = await _client.rpc(
        'get_exam_questions_for_student',
        params: {'p_exam_id': examId},
      );
      final questions = (rows as List)
          .map((r) => ExamQuestion.fromJson(r as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      return questions;
    });
  }

  /// Creates a new attempt. The `enforce_exam_attempt_rules` trigger
  /// (schema.sql) rejects this at the SQL level if the deadline has
  /// passed and late submission isn't allowed, or if the exam was
  /// manually closed — never trust a client-side deadline check alone.
  Future<ExamAttempt> startAttempt(String examId) {
    return runGuarded(() async {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw const SessionExpiredException();
      final row = await _client
          .from('exam_attempts')
          .insert({'exam_id': examId, 'student_id': uid})
          .select()
          .single();
      return ExamAttempt.fromJson(row);
    });
  }

  Future<List<ExamAnswer>> getMyAnswers(String attemptId) {
    return runGuarded(() async {
      final rows =
          await _client.from('exam_answers').select().eq('attempt_id', attemptId);
      return (rows as List)
          .map((r) => ExamAnswer.fromJson(r as Map<String, dynamic>))
          .toList();
    });
  }

  /// Autosaves a single answer as the student works through the exam
  /// (spec §19 — "persist draft answers safely while the exam is
  /// active"). Safe to call repeatedly; upserts on (attempt_id, question_id).
  Future<void> saveAnswer({
    required String attemptId,
    required String questionId,
    required Map<String, dynamic> answerData,
  }) {
    return runGuarded(() async {
      await _client.from('exam_answers').upsert(
        {
          'attempt_id': attemptId,
          'question_id': questionId,
          'answer_data': answerData,
        },
        onConflict: 'attempt_id,question_id',
      );
    });
  }

  /// Locks the attempt. The trigger re-validates the deadline
  /// server-side and rejects late submission unless the exam explicitly
  /// allows it (spec §20 — "the backend remains authoritative").
  Future<void> submitAttempt(String attemptId) {
    return runGuarded(() async {
      await _client
          .from('exam_attempts')
          .update({'status': 'submitted'}).eq('id', attemptId);
    });
  }
}

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return ExamRepository(SupabaseConfig.client);
});
