class TransformationStep {
  final String before;
  final String operation;
  final String after;
  final String? leftOperation;
  final String? rightOperation;

  const TransformationStep({
    required this.before,
    required this.operation,
    required this.after,
    this.leftOperation,
    this.rightOperation,
  });
}

class Solution {
  final bool success;
  final String answer;
  final List<TransformationStep> steps;
  final String? error;

  const Solution({
    required this.success,
    required this.answer,
    this.steps = const [],
    this.error,
  });
}
