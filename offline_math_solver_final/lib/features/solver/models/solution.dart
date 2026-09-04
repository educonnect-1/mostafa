enum SolutionKind {
  expression,
  linearEquation,
  quadraticEquation,
  system,
  inequality,
  derivative,
}

class TransformationStep {
  final String before;
  final String operation;
  final String after;

  const TransformationStep({
    required this.before,
    required this.operation,
    required this.after,
  });
}

class Solution {
  final bool success;
  final SolutionKind kind;
  final String answer;
  final List<TransformationStep> steps;
  final String? error;

  const Solution({
    required this.success,
    required this.kind,
    required this.answer,
    this.steps = const [],
    this.error,
  });

  const Solution.failure(String message)
      : success = false,
        kind = SolutionKind.expression,
        answer = '',
        steps = const [],
        error = message;
}
