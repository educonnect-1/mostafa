import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../models/exam.dart';
import '../../../repositories/exam_repository.dart';

class ExamTakingState {
  const ExamTakingState({
    this.attempt,
    this.questions = const [],
    this.answers = const {},
    this.currentIndex = 0,
    this.loading = true,
    this.submitting = false,
    this.submitted = false,
    this.remaining,
    this.error,
    this.savingQuestionId,
  });

  final ExamAttempt? attempt;
  final List<ExamQuestion> questions;

  /// questionId -> answerData, kept in sync with what's been autosaved.
  final Map<String, Map<String, dynamic>> answers;
  final int currentIndex;
  final bool loading;
  final bool submitting;
  final bool submitted;
  final Duration? remaining;
  final AppException? error;
  final String? savingQuestionId;

  ExamQuestion? get currentQuestion =>
      questions.isEmpty ? null : questions[currentIndex.clamp(0, questions.length - 1)];

  int get answeredCount => answers.keys.where((k) => (answers[k]?.isNotEmpty ?? false)).length;

  ExamTakingState copyWith({
    ExamAttempt? attempt,
    List<ExamQuestion>? questions,
    Map<String, Map<String, dynamic>>? answers,
    int? currentIndex,
    bool? loading,
    bool? submitting,
    bool? submitted,
    Duration? remaining,
    AppException? error,
    bool clearError = false,
    String? savingQuestionId,
    bool clearSaving = false,
  }) {
    return ExamTakingState(
      attempt: attempt ?? this.attempt,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      submitted: submitted ?? this.submitted,
      remaining: remaining ?? this.remaining,
      error: clearError ? null : (error ?? this.error),
      savingQuestionId: clearSaving ? null : (savingQuestionId ?? this.savingQuestionId),
    );
  }
}

class ExamTakingController extends StateNotifier<ExamTakingState> {
  ExamTakingController(this._repository, this._exam) : super(const ExamTakingState()) {
    _init();
  }

  final ExamRepository _repository;
  final Exam _exam;
  Timer? _countdownTimer;
  bool _autoSubmitTriggered = false;

  Future<void> _init() async {
    try {
      ExamAttempt attempt = _exam.myAttempt ?? await _repository.startAttempt(_exam.id);
      final questions = await _repository.getQuestionsForStudent(_exam.id);
      final existingAnswers = attempt.status == AttemptStatus.inProgress
          ? await _repository.getMyAnswers(attempt.id)
          : <ExamAnswer>[];

      final answerMap = <String, Map<String, dynamic>>{
        for (final a in existingAnswers) a.questionId: a.answerData,
      };

      state = state.copyWith(
        attempt: attempt,
        questions: questions,
        answers: answerMap,
        loading: false,
        submitted: attempt.status != AttemptStatus.inProgress,
      );

      if (attempt.status == AttemptStatus.inProgress) {
        _startCountdown(attempt);
      }
    } on AppException catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  void _startCountdown(ExamAttempt attempt) {
    final durationEnd = attempt.startedAt.add(Duration(minutes: _exam.durationMinutes));
    // The local countdown is a UI convenience only (spec §20) — the
    // database re-validates the real deadline independently on submit.
    final cap = durationEnd.isBefore(_exam.deadline) ? durationEnd : _exam.deadline;

    void tick() {
      final remaining = cap.difference(DateTime.now().toUtc());
      if (remaining.isNegative) {
        state = state.copyWith(remaining: Duration.zero);
        if (!_autoSubmitTriggered) {
          _autoSubmitTriggered = true;
          submit();
        }
        _countdownTimer?.cancel();
        return;
      }
      state = state.copyWith(remaining: remaining);
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  void goTo(int index) {
    if (index < 0 || index >= state.questions.length) return;
    state = state.copyWith(currentIndex: index);
  }

  void next() => goTo(state.currentIndex + 1);
  void previous() => goTo(state.currentIndex - 1);

  /// Updates the answer locally immediately (so the UI never loses
  /// what the student typed) and autosaves to the backend in the
  /// background per spec §19.
  Future<void> answer(String questionId, Map<String, dynamic> data) async {
    final updated = Map<String, Map<String, dynamic>>.from(state.answers);
    updated[questionId] = data;
    state = state.copyWith(answers: updated, savingQuestionId: questionId);

    if (state.attempt == null) return;
    try {
      await _repository.saveAnswer(
        attemptId: state.attempt!.id,
        questionId: questionId,
        answerData: data,
      );
    } on AppException catch (e) {
      state = state.copyWith(error: e);
    } finally {
      state = state.copyWith(clearSaving: true);
    }
  }

  Future<bool> submit() async {
    if (state.attempt == null || state.submitting || state.submitted) return false;
    state = state.copyWith(submitting: true, clearError: true);
    try {
      await _repository.submitAttempt(state.attempt!.id);
      _countdownTimer?.cancel();
      state = state.copyWith(submitting: false, submitted: true);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(submitting: false, error: e);
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}

final examTakingControllerProvider = StateNotifierProvider.autoDispose
    .family<ExamTakingController, ExamTakingState, Exam>((ref, exam) {
  return ExamTakingController(ref.read(examRepositoryProvider), exam);
});
