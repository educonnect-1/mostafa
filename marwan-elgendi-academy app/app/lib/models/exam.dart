import 'package:equatable/equatable.dart';

enum QuestionType { mcq, trueFalse, shortAnswer, longAnswer, numerical }

QuestionType _questionTypeFromString(String value) {
  switch (value) {
    case 'mcq':
      return QuestionType.mcq;
    case 'true_false':
      return QuestionType.trueFalse;
    case 'short_answer':
      return QuestionType.shortAnswer;
    case 'long_answer':
      return QuestionType.longAnswer;
    case 'numerical':
      return QuestionType.numerical;
    default:
      return QuestionType.shortAnswer;
  }
}

enum AttemptStatus { inProgress, submitted, graded }

AttemptStatus _attemptStatusFromString(String? value) {
  switch (value) {
    case 'submitted':
      return AttemptStatus.submitted;
    case 'graded':
      return AttemptStatus.graded;
    default:
      return AttemptStatus.inProgress;
  }
}

class Exam extends Equatable {
  const Exam({
    required this.id,
    required this.title,
    this.description,
    this.instructions,
    required this.deadline,
    required this.durationMinutes,
    required this.allowLateSubmission,
    required this.manuallyClosed,
    this.myAttempt,
  });

  final String id;
  final String title;
  final String? description;
  final String? instructions;
  final DateTime deadline;
  final int durationMinutes;
  final bool allowLateSubmission;
  final bool manuallyClosed;
  final ExamAttempt? myAttempt;

  bool get isPastDeadline => DateTime.now().toUtc().isAfter(deadline.toUtc());
  bool get canStartOrContinue =>
      !manuallyClosed && (!isPastDeadline || allowLateSubmission);

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      instructions: json['instructions'] as String?,
      deadline: DateTime.parse(json['deadline'] as String),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 60,
      allowLateSubmission: (json['allow_late_submission'] as bool?) ?? false,
      manuallyClosed: (json['manually_closed'] as bool?) ?? false,
      myAttempt: json['exam_attempts'] is List && (json['exam_attempts'] as List).isNotEmpty
          ? ExamAttempt.fromJson((json['exam_attempts'] as List).first as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        instructions,
        deadline,
        durationMinutes,
        allowLateSubmission,
        manuallyClosed,
        myAttempt,
      ];
}

/// Never includes `correct_answer` — that column has no student SELECT
/// policy at all (schema.sql §18). This is decoded from the
/// `get_exam_questions_for_student` RPC response only.
class ExamQuestion extends Equatable {
  const ExamQuestion({
    required this.id,
    required this.examId,
    required this.type,
    required this.questionText,
    this.imageUrl,
    this.options,
    required this.points,
    required this.orderIndex,
  });

  final String id;
  final String examId;
  final QuestionType type;
  final String questionText;
  final String? imageUrl;
  final List<Map<String, dynamic>>? options;
  final double points;
  final int orderIndex;

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      id: json['id'] as String,
      examId: json['exam_id'] as String,
      type: _questionTypeFromString(json['type'] as String),
      questionText: json['question_text'] as String,
      imageUrl: json['image_url'] as String?,
      options: json['options'] == null
          ? null
          : List<Map<String, dynamic>>.from(json['options'] as List),
      points: ((json['points'] as num?) ?? 1).toDouble(),
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [id, examId, type, questionText, imageUrl, options, points, orderIndex];
}

class ExamAttempt extends Equatable {
  const ExamAttempt({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.status,
    required this.startedAt,
    this.submittedAt,
    this.score,
    this.maxScore,
    this.teacherFeedback,
    this.gradedAt,
  });

  final String id;
  final String examId;
  final String studentId;
  final AttemptStatus status;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final double? score;
  final double? maxScore;
  final String? teacherFeedback;
  final DateTime? gradedAt;

  factory ExamAttempt.fromJson(Map<String, dynamic> json) {
    return ExamAttempt(
      id: json['id'] as String,
      examId: json['exam_id'] as String,
      studentId: json['student_id'] as String,
      status: _attemptStatusFromString(json['status'] as String?),
      startedAt: DateTime.parse(json['started_at'] as String),
      submittedAt: json['submitted_at'] == null
          ? null
          : DateTime.parse(json['submitted_at'] as String),
      score: (json['score'] as num?)?.toDouble(),
      maxScore: (json['max_score'] as num?)?.toDouble(),
      teacherFeedback: json['teacher_feedback'] as String?,
      gradedAt: json['graded_at'] == null
          ? null
          : DateTime.parse(json['graded_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        examId,
        studentId,
        status,
        startedAt,
        submittedAt,
        score,
        maxScore,
        teacherFeedback,
        gradedAt,
      ];
}

/// `answerData` shape depends on question type:
///   mcq          -> {"selected": "optionId"}
///   trueFalse    -> {"value": true|false}
///   shortAnswer  -> {"text": "..."}
///   longAnswer   -> {"text": "..."}
///   numerical    -> {"value": 42.5}
class ExamAnswer extends Equatable {
  const ExamAnswer({
    required this.questionId,
    required this.answerData,
  });

  final String questionId;
  final Map<String, dynamic> answerData;

  factory ExamAnswer.fromJson(Map<String, dynamic> json) {
    return ExamAnswer(
      questionId: json['question_id'] as String,
      answerData: Map<String, dynamic>.from(json['answer_data'] as Map? ?? {}),
    );
  }

  @override
  List<Object?> get props => [questionId, answerData];
}
