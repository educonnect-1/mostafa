import 'dart:math' as math;
import 'package:math_expressions/math_expressions.dart';
import '../../core/utils/math_text.dart';
import 'models/solution.dart';

class MathSolver {
  Solution solve(String raw) {
    final input = MathText.normalize(raw);
    if (input.isEmpty) return const Solution.failure('Enter a problem first.');

    final lower = input.toLowerCase();

    if (lower.startsWith('derivative:')) {
      return _derivative(input.substring(input.indexOf(':') + 1).trim());
    }

    if (lower.startsWith('d/dx')) {
      final expression = input.replaceFirst(
        RegExp(r'^d/dx\s*\(?', caseSensitive: false),
        '',
      );
      return _derivative(expression.replaceFirst(RegExp(r'\)$'), ''));
    }

    if (input.contains(';')) {
      return _system(input);
    }

    final relation = _findRelation(input);
    if (relation != null) {
      final op = relation.operator;
      if (op == '=' && input.split('=').length == 2) {
        return _equation(input, relation.left, relation.right);
      }
      if (op != '=') {
        return _inequality(input, relation.left, relation.right, op);
      }
    }

    return _expression(input);
  }

  _Relation? _findRelation(String input) {
    final matches = RegExp(r'<=|>=|=|<|>').allMatches(input);
    if (matches.isEmpty) return null;
    final m = matches.first;
    return _Relation(
      operator: m.group(0)!,
      left: input.substring(0, m.start).trim(),
      right: input.substring(m.end).trim(),
    );
  }

  Solution _expression(String input) {
    try {
      final parser = Parser();
      final expression = parser.parse(input);
      final simplified = expression.simplify().toString();
      final value = expression.evaluate(EvaluationType.REAL, ContextModel());

      final answer = _prettyNumber(value);
      final steps = <TransformationStep>[];

      if (simplified != input && !_hasVariable(input)) {
        steps.add(
          TransformationStep(
            before: input,
            operation: 'Simplify',
            after: simplified,
          ),
        );
      }
      steps.add(
        TransformationStep(
          before: steps.isEmpty ? input : steps.last.after,
          operation: 'Evaluate',
          after: answer,
        ),
      );

      return Solution(
        success: true,
        kind: SolutionKind.expression,
        answer: answer,
        steps: steps,
      );
    } catch (_) {
      return const Solution.failure(
        'Unsupported expression. Check brackets, operators, and variable names.',
      );
    }
  }

  Solution _equation(String input, String left, String right) {
    final variable = _firstVariable('$left $right');
    if (variable == null) {
      try {
        final l = _evaluate(left);
        final r = _evaluate(right);
        return Solution(
          success: true,
          kind: SolutionKind.expression,
          answer: (l - r).abs() < 1e-10 ? 'True' : 'False',
          steps: [
            TransformationStep(
              before: input,
              operation: 'Evaluate both sides',
              after: '${_prettyNumber(l)} = ${_prettyNumber(r)}',
            ),
          ],
        );
      } catch (_) {
        return const Solution.failure('Both sides could not be evaluated.');
      }
    }

    final quad = _polynomialDifference(left, right, variable, 2);
    if (quad != null && quad[0].abs() > 1e-12) {
      return _quadratic(input, variable, quad);
    }

    final linear = _polynomialDifference(left, right, variable, 1);
    if (linear != null && linear[0].abs() > 1e-12) {
      return _linear(input, variable, linear[0], linear[1]);
    }

    return const Solution.failure(
      'This equation is outside the current exact solving engine.',
    );
  }

  Solution _linear(String input, String variable, double a, double b) {
    final rhs = -b;
    final x = rhs / a;
    final steps = <TransformationStep>[
      TransformationStep(
        before: input,
        operation: b.abs() < 1e-12
            ? 'Divide both sides by ${_prettyNumber(a)}'
            : 'Subtract ${_prettySigned(b)} from both sides',
        after: b.abs() < 1e-12
            ? '$variable = ${_prettyNumber(x)}'
            : '${_prettyNumber(a)}$variable = ${_prettyNumber(rhs)}',
      ),
    ];

    if (b.abs() >= 1e-12) {
      steps.add(
        TransformationStep(
          before: steps.last.after,
          operation: 'Divide both sides by ${_prettyNumber(a)}',
          after: '$variable = ${_prettyNumber(x)}',
        ),
      );
    }

    return Solution(
      success: true,
      kind: SolutionKind.linearEquation,
      answer: '$variable = ${_prettyNumber(x)}',
      steps: steps,
    );
  }

  Solution _quadratic(
    String input,
    String variable,
    List<double> c,
  ) {
    final a = c[0], b = c[1], d = c[2];
    final delta = b * b - 4 * a * d;

    final standard =
        '${_coefficient(a, variable, 2)} ${_prettySigned(b)}$variable ${_prettySigned(d)} = 0';

    final steps = <TransformationStep>[
      TransformationStep(
        before: input,
        operation: 'Move all terms to the left side',
        after: standard,
      ),
      TransformationStep(
        before: standard,
        operation: 'Calculate the discriminant b² − 4ac',
        after: 'Δ = ${_prettyNumber(delta)}',
      ),
    ];

    if (delta < -1e-12) {
      final real = -b / (2 * a);
      final imag = math.sqrt(-delta) / (2 * a);
      final answer =
          '$variable = ${_prettyNumber(real)} ± ${_prettyNumber(imag.abs())}i';

      steps.add(
        TransformationStep(
          before: 'Δ = ${_prettyNumber(delta)}',
          operation: 'Apply the quadratic formula',
          after: answer,
        ),
      );

      return Solution(
        success: true,
        kind: SolutionKind.quadraticEquation,
        answer: answer,
        steps: steps,
      );
    }

    final root = math.sqrt(math.max(0, delta));
    final x1 = (-b + root) / (2 * a);
    final x2 = (-b - root) / (2 * a);

    final answer = (x1 - x2).abs() < 1e-10
        ? '$variable = ${_prettyNumber(x1)}'
        : '$variable = ${_prettyNumber(x1)} or $variable = ${_prettyNumber(x2)}';

    steps.add(
      TransformationStep(
        before: 'Δ = ${_prettyNumber(delta)}',
        operation: 'Apply x = (−b ± √Δ) / 2a',
        after: answer,
      ),
    );

    return Solution(
      success: true,
      kind: SolutionKind.quadraticEquation,
      answer: answer,
      steps: steps,
    );
  }

  Solution _system(String input) {
    final equations = input
        .split(';')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (equations.length != 2) {
      return const Solution.failure(
        'Enter a 2×2 system using two equations separated by a semicolon.',
      );
    }

    final variables = <String>{};
    for (final eq in equations) {
      variables.addAll(RegExp(r'[a-zA-Z]').allMatches(eq).map((m) => m.group(0)!));
    }
    if (variables.length != 2) {
      return const Solution.failure('A 2×2 system must contain exactly two variables.');
    }

    final vars = variables.toList()..sort();
    final a = _systemCoefficients(equations[0], vars[0], vars[1]);
    final b = _systemCoefficients(equations[1], vars[0], vars[1]);

    if (a == null || b == null) {
      return const Solution.failure('Could not parse the system.');
    }

    final det = a[0] * b[1] - b[0] * a[1];
    if (det.abs() < 1e-12) {
      return const Solution.failure('The system has no unique solution.');
    }

    final x = (a[2] * b[1] - b[2] * a[1]) / det;
    final y = (a[0] * b[2] - b[0] * a[2]) / det;

    final elimination =
        '${_prettyNumber(det)}${vars[0]} = ${_prettyNumber(det * x)}';

    return Solution(
      success: true,
      kind: SolutionKind.system,
      answer:
          '${vars[0]} = ${_prettyNumber(x)}\n${vars[1]} = ${_prettyNumber(y)}',
      steps: [
        TransformationStep(
          before: '${equations[0]}\n${equations[1]}',
          operation: 'Write the system in standard form',
          after:
              '${_prettyNumber(a[0])}${vars[0]} + ${_prettyNumber(a[1])}${vars[1]} = ${_prettyNumber(a[2])}\n'
              '${_prettyNumber(b[0])}${vars[0]} + ${_prettyNumber(b[1])}${vars[1]} = ${_prettyNumber(b[2])}',
        ),
        TransformationStep(
          before:
              '${_prettyNumber(a[0])}${vars[0]} + ${_prettyNumber(a[1])}${vars[1]} = ${_prettyNumber(a[2])}\n'
              '${_prettyNumber(b[0])}${vars[0]} + ${_prettyNumber(b[1])}${vars[1]} = ${_prettyNumber(b[2])}',
          operation: 'Eliminate ${vars[1]}',
          after: elimination,
        ),
        TransformationStep(
          before: elimination,
          operation: 'Divide by ${_prettyNumber(det)}',
          after: '${vars[0]} = ${_prettyNumber(x)}',
        ),
        TransformationStep(
          before: '${vars[0]} = ${_prettyNumber(x)}',
          operation: 'Substitute into the other equation',
          after: '${vars[1]} = ${_prettyNumber(y)}',
        ),
      ],
    );
  }

  List<double>? _systemCoefficients(String equation, String x, String y) {
    final relation = _findRelation(equation);
    if (relation == null || relation.operator != '=') return null;
    final left = _linear2(relation.left, x, y);
    final right = _linear2(relation.right, x, y);
    if (left == null || right == null) return null;
    return [
      left[0] - right[0],
      left[1] - right[1],
      right[2] - left[2],
    ];
  }

  List<double>? _linear2(String expression, String x, String y) {
    final s = expression.replaceAll(' ', '').replaceAll('*', '');
    final terms = <String>[];
    var current = '';
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      if ((ch == '+' || ch == '-') && i > 0) {
        terms.add(current);
        current = ch;
      } else {
        current += ch;
      }
    }
    if (current.isNotEmpty) terms.add(current);

    double cx = 0, cy = 0, constant = 0;

    try {
      for (final term in terms) {
        if (term.contains(x)) {
          final c = term.replaceAll(x, '');
          cx += c.isEmpty || c == '+' ? 1 : c == '-' ? -1 : double.parse(c);
        } else if (term.contains(y)) {
          final c = term.replaceAll(y, '');
          cy += c.isEmpty || c == '+' ? 1 : c == '-' ? -1 : double.parse(c);
        } else {
          constant += double.parse(term);
        }
      }
      return [cx, cy, constant];
    } catch (_) {
      return null;
    }
  }

  Solution _inequality(
    String input,
    String left,
    String right,
    String operator,
  ) {
    final variable = _firstVariable('$left $right');
    if (variable == null) {
      return const Solution.failure('An inequality must contain a variable.');
    }

    final linear = _polynomialDifference(left, right, variable, 1);
    if (linear == null || linear[0].abs() < 1e-12) {
      return const Solution.failure('Only linear inequalities are supported.');
    }

    final a = linear[0];
    final b = linear[1];
    var boundary = -b / a;
    var op = operator;

    if (a < 0) op = _reverseInequality(op);

    boundary = -b / a;

    final answer = '$variable $op ${_prettyNumber(boundary)}';

    return Solution(
      success: true,
      kind: SolutionKind.inequality,
      answer: answer,
      steps: [
        TransformationStep(
          before: input,
          operation: 'Move constants to the right side',
          after: '${_prettyNumber(a)}$variable $op ${_prettyNumber(-b)}',
        ),
        TransformationStep(
          before: '${_prettyNumber(a)}$variable $op ${_prettyNumber(-b)}',
          operation: 'Divide by ${_prettyNumber(a)} and reverse the sign if the divisor is negative',
          after: answer,
        ),
      ],
    );
  }

  String _reverseInequality(String op) {
    switch (op) {
      case '<':
        return '>';
      case '>':
        return '<';
      case '<=':
        return '>=';
      case '>=':
        return '<=';
      default:
        return op;
    }
  }

  Solution _derivative(String expression) {
    final cleaned = expression.trim();
    if (cleaned.isEmpty) {
      return const Solution.failure('Enter an expression after derivative:.');
    }

    try {
      final parser = Parser();
      final parsed = parser.parse(cleaned);
      final derivative = parsed.derive('x').simplify().toString();

      return Solution(
        success: true,
        kind: SolutionKind.derivative,
        answer: derivative,
        steps: [
          TransformationStep(
            before: 'f(x) = $cleaned',
            operation: 'Differentiate with respect to x',
            after: "f'(x) = $derivative",
          ),
        ],
      );
    } catch (_) {
      return const Solution.failure('Could not differentiate this expression.');
    }
  }

  List<double>? _polynomialDifference(
    String left,
    String right,
    String variable,
    int degree,
  ) {
    final l = _polynomial(left, variable, degree);
    final r = _polynomial(right, variable, degree);
    if (l == null || r == null) return null;

    final out = List<double>.filled(degree + 1, 0);
    for (var i = 0; i <= degree; i++) {
      out[i] = l[i] - r[i];
    }
    return out;
  }

  List<double>? _polynomial(String expression, String variable, int degree) {
    var s = expression.replaceAll(' ', '');
    s = s.replaceAll('*', '');

    final terms = <String>[];
    var current = '';
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      if ((ch == '+' || ch == '-') && i > 0) {
        terms.add(current);
        current = ch;
      } else {
        current += ch;
      }
    }
    if (current.isNotEmpty) terms.add(current);

    final coeff = List<double>.filled(degree + 1, 0);

    try {
      for (final term in terms) {
        final pos = term.indexOf(variable);
        if (pos < 0) {
          coeff[degree] += double.parse(term);
          continue;
        }

        var c = term.substring(0, pos);
        if (c.isEmpty || c == '+') c = '1';
        if (c == '-') c = '-1';

        var power = 1;
        final tail = term.substring(pos + variable.length);
        if (tail.startsWith('^')) {
          power = int.parse(tail.substring(1));
        }
        if (power > degree) return null;

        coeff[degree - power] += double.parse(c);
      }

      // For degree 1, coeff[0] is x and coeff[1] is constant.
      // For degree 2, coeff[0] is x², coeff[1] is x, coeff[2] is constant.
      return coeff;
    } catch (_) {
      return null;
    }
  }

  bool _hasVariable(String input) => RegExp(r'[a-zA-Z]').hasMatch(input);

  String? _firstVariable(String input) {
    return RegExp(r'[a-zA-Z]').firstMatch(input)?.group(0);
  }

  double _evaluate(String expression) {
    final parser = Parser();
    return parser.parse(expression).evaluate(
          EvaluationType.REAL,
          ContextModel(),
        );
  }

  String _coefficient(double a, String variable, int degree) {
    final n = _prettyNumber(a);
    if ((a - 1).abs() < 1e-12) return '$variable²';
    if ((a + 1).abs() < 1e-12) return '-$variable²';
    return '$n$variable²';
  }

  String _prettySigned(double n) {
    if (n >= 0) return '+ ${_prettyNumber(n)}';
    return '- ${_prettyNumber(n.abs())}';
  }

  String _prettyNumber(num n) {
    final d = n.toDouble();
    if ((d - d.roundToDouble()).abs() < 1e-10) return d.round().toString();
    return d
        .toStringAsFixed(8)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _Relation {
  final String operator;
  final String left;
  final String right;

  const _Relation({
    required this.operator,
    required this.left,
    required this.right,
  });
}
