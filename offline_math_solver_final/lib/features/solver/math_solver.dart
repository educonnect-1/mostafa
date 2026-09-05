import 'dart:math' as math;
import '../../core/utils/math_text.dart';
import 'models/solution.dart';

/// Offline symbolic-first solver.
///
/// The engine keeps a small polynomial representation so transformations are
/// real algebraic transformations instead of only displaying a final formula.
class MathSolver {
  static const double _eps = 1e-10;

  Solution solve(String raw) {
    final input = MathText.normalize(raw).trim();
    if (input.isEmpty) {
      return const Solution(success: false, answer: '', error: 'Enter a mathematical expression first.');
    }

    if (input.contains('=')) return _solveEquation(input);
    return _solveExpression(input);
  }

  Solution _solveExpression(String input) {
    final complex = _tryComplexProductOfRoots(input);
    if (complex != null) return complex;

    try {
      final value = _ExpressionParser(input).parse();
      final answer = _fmt(value);
      return Solution(
        success: true,
        answer: answer,
        steps: [
          TransformationStep(before: input, operation: '=', after: answer),
        ],
      );
    } catch (_) {
      return const Solution(
        success: false,
        answer: '',
        error: 'This expression could not be parsed. Check brackets, operators, roots, and powers.',
      );
    }
  }

  Solution? _tryComplexProductOfRoots(String input) {
    final compact = input.replaceAll(' ', '');
    final m = RegExp(r'^√\(?(-?\d+(?:\.\d+)?)\)?\*√\(?(-?\d+(?:\.\d+)?)\)?$').firstMatch(compact);
    if (m == null) return null;
    final a = double.parse(m.group(1)!);
    final b = double.parse(m.group(2)!);
    if (a >= 0 || b >= 0) return null;

    final magnitude = math.sqrt((-a) * (-b));
    final answer = '-${_fmt(magnitude)}';
    final simplified = _simplifyRadicalProduct((-a), (-b));
    final exact = simplified ?? answer;
    return Solution(
      success: true,
      answer: exact,
      steps: [
        TransformationStep(before: input, operation: 'Rewrite negative square roots', after: 'i√${_fmt(-a)} × i√${_fmt(-b)}'),
        TransformationStep(before: 'i√${_fmt(-a)} × i√${_fmt(-b)}', operation: 'Use i² = −1', after: '−√${_fmt((-a) * (-b))}'),
        TransformationStep(before: '−√${_fmt((-a) * (-b))}', operation: 'Simplify the radical', after: exact),
      ],
    );
  }

  String? _simplifyRadicalProduct(double a, double b) {
    final n = a * b;
    final rounded = n.roundToDouble();
    if ((n - rounded).abs() > _eps || rounded < 0) return null;
    final integer = rounded.toInt();
    var outside = 1;
    var inside = integer;
    for (var p = 2; p * p <= inside; p++) {
      while (inside % (p * p) == 0) {
        outside *= p;
        inside ~/= p * p;
      }
    }
    if (inside == 1) return '−$outside';
    if (outside == 1) return '−√$inside';
    return '−${outside == 1 ? '' : outside}√$inside';
  }

  Solution _solveEquation(String input) {
    final parts = input.split('=');
    if (parts.length != 2) {
      return const Solution(success: false, answer: '', error: 'Use exactly one equals sign.');
    }
    final left = parts[0].trim();
    final right = parts[1].trim();
    final vars = RegExp(r'[A-Za-zθ]').allMatches('$left $right').map((m) => m.group(0)!).toSet();
    if (vars.isEmpty) return _compareNumeric(left, right);
    if (vars.length > 1) {
      return const Solution(success: false, answer: '', error: 'This offline version currently solves one-variable equations.');
    }
    final variable = vars.first;

    final lp = _PolynomialParser(left, variable).parse();
    final rp = _PolynomialParser(right, variable).parse();
    if (lp == null || rp == null) {
      return const Solution(success: false, answer: '', error: 'Could not build a symbolic polynomial from this equation.');
    }
    final p = lp.subtract(rp);
    final degree = p.degree;
    if (degree == 0) {
      final trueEq = p.c[0].abs() < _eps;
      return Solution(success: true, answer: trueEq ? 'All real numbers' : 'No solution', steps: [
        TransformationStep(before: input, operation: 'Move all terms to one side', after: '${p.format(variable)} = 0'),
      ]);
    }
    if (degree == 1) return _linearSolution(input, p, variable);
    if (degree == 2) return _quadraticSolution(input, p, variable);
    return const Solution(success: false, answer: '', error: 'Polynomial degree above 2 is not supported by this version yet.');
  }

  Solution _compareNumeric(String left, String right) {
    try {
      final l = _ExpressionParser(left).parse();
      final r = _ExpressionParser(right).parse();
      final equal = (l - r).abs() < _eps;
      return Solution(success: true, answer: equal ? 'True' : 'False', steps: [
        TransformationStep(before: '$left = $right', operation: 'Evaluate both sides', after: '${_fmt(l)} = ${_fmt(r)}'),
      ]);
    } catch (_) {
      return const Solution(success: false, answer: '', error: 'Could not evaluate both sides.');
    }
  }

  Solution _linearSolution(String input, _Polynomial p, String x) {
    final double a = (p.c.length > 1 ? p.c[1] : 0).toDouble();
    final double b = p.c[0].toDouble();
    if (a.abs() < _eps) return const Solution(success: false, answer: '', error: 'No unique solution.');
    final root = -b / a;
    final steps = <TransformationStep>[
      TransformationStep(
        before: input,
        operation: 'Move constant term to the other side',
        leftOperation: b.abs() < _eps ? null : _signedOperation(-b),
        rightOperation: b.abs() < _eps ? null : _signedOperation(-b),
        after: '${_term(a, x)} = ${_fmt(-b)}',
      ),
      TransformationStep(
        before: '${_term(a, x)} = ${_fmt(-b)}',
        operation: 'Divide both sides by ${_fmt(a)}',
        leftOperation: '÷ ${_fmt(a)}',
        rightOperation: '÷ ${_fmt(a)}',
        after: '$x = ${_fmt(root)}',
      ),
    ];
    return Solution(success: true, answer: '$x = ${_fmt(root)}', steps: steps);
  }

  Solution _quadraticSolution(String input, _Polynomial p, String x) {
    final double a = p.c[2].toDouble();
    final double b = p.c[1].toDouble();
    final double c = p.c[0].toDouble();
    final d = b * b - 4 * a * c;
    final standard = '${_term(a, '$x²')} ${_signedTerm(b, x)} ${_signedNumber(c)} = 0';
    if (d < -_eps) {
      final real = -b / (2 * a);
      final imag = math.sqrt(-d) / (2 * a).abs();
      final ans = '$x = ${_fmt(real)} ± ${_fmt(imag)}i';
      return Solution(success: true, answer: ans, steps: [
        TransformationStep(before: input, operation: 'Move everything to one side', after: standard),
        TransformationStep(before: standard, operation: 'Compute the discriminant', after: 'Δ = ${_fmt(d)}'),
        TransformationStep(before: 'Δ = ${_fmt(d)}', operation: 'Apply the quadratic formula', after: ans),
      ]);
    }
    final root = math.sqrt(math.max(0, d));
    final x1 = (-b + root) / (2 * a);
    final x2 = (-b - root) / (2 * a);
    final factor = _factorQuadratic(a, b, c, x);
    final steps = <TransformationStep>[
      TransformationStep(before: input, operation: 'Move everything to one side', after: standard),
      TransformationStep(before: standard, operation: 'Factor the quadratic', after: factor ?? standard),
    ];
    if (factor != null && (x1 - x2).abs() > _eps) {
      steps.add(TransformationStep(before: factor, operation: 'Set each factor equal to zero', after: '$x = ${_fmt(x1)}    OR    $x = ${_fmt(x2)}'));
    } else {
      steps.add(TransformationStep(before: standard, operation: 'Apply the quadratic formula', after: '$x = ${_fmt(x1)}    OR    $x = ${_fmt(x2)}'));
    }
    return Solution(success: true, answer: '$x = ${_fmt(x1)} or $x = ${_fmt(x2)}', steps: steps);
  }

  String? _factorQuadratic(double a, double b, double c, String x) {
    if (a.abs() < _eps) return null;
    final d = b * b - 4 * a * c;
    if (d < -_eps) return null;
    final s = math.sqrt(math.max(0, d));
    final r1 = (-b + s) / (2 * a);
    final r2 = (-b - s) / (2 * a);
    if (!_isInteger(a) || !_isInteger(r1) || !_isInteger(r2)) return null;
    final aInt = a.round();
    final p = -r1;
    final q = -r2;
    final left = aInt == 1 ? '($x ${_signedNumber(p)})' : '${aInt}($x ${_signedNumber(p)})';
    final right = '($x ${_signedNumber(q)})';
    return '$left$right = 0';
  }

  bool _isInteger(double n) => (n - n.roundToDouble()).abs() < _eps;
  String _signedOperation(double n) => n >= 0 ? '+ ${_fmt(n)}' : '− ${_fmt(n.abs())}';
  String _signedNumber(double n) => n >= 0 ? '+ ${_fmt(n)}' : '− ${_fmt(n.abs())}';
  String _signedTerm(double n, String x) => n >= 0 ? '+ ${_fmt(n)}$x' : '− ${_fmt(n.abs())}$x';
  String _term(double a, String x) {
    if (x.contains('²')) return '${_fmt(a)}$x';
    if ((a - 1).abs() < _eps) return x;
    if ((a + 1).abs() < _eps) return '−$x';
    return '${_fmt(a)}$x';
  }
  String _fmt(double n) {
    if (n.abs() < _eps) return '0';
    if ((n - n.roundToDouble()).abs() < _eps) return n.round().toString();
    return n.toStringAsFixed(10).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
}

class _Polynomial {
  final List<double> c;
  _Polynomial(this.c);
  int get degree {
    for (var i = c.length - 1; i >= 0; i--) {
      if (c[i].abs() > MathSolver._eps) return i;
    }
    return 0;
  }
  _Polynomial subtract(_Polynomial other) {
    final n = math.max(c.length, other.c.length);
    final out = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) out[i] = (i < c.length ? c[i] : 0) - (i < other.c.length ? other.c[i] : 0);
    return _Polynomial(out);
  }
  String format(String x) {
    final d = degree;
    if (d == 0) return _fmtLocal(c[0]);
    final b = StringBuffer();
    for (var i = d; i >= 0; i--) {
      final v = c[i];
      if (v.abs() < MathSolver._eps) continue;
      if (b.isNotEmpty) b.write(v >= 0 ? ' + ' : ' − ');
      else if (v < 0) b.write('−');
      final av = v.abs();
      if (i == 0) b.write(_fmtLocal(av));
      else {
        if ((av - 1).abs() > MathSolver._eps) b.write(_fmtLocal(av));
        b.write(x);
        if (i > 1) b.write(i == 2 ? '²' : '^$i');
      }
    }
    return b.toString();
  }
}

class _PolynomialParser {
  final String source;
  final String variable;
  int _i = 0;
  _PolynomialParser(this.source, this.variable);

  _Polynomial? parse() {
    try {
      final p = _sum();
      _skip();
      return _i == source.length ? p : null;
    } catch (_) {
      return null;
    }
  }

  _Polynomial _sum() {
    var a = _product();
    while (true) {
      _skip();
      if (_eat('+')) a = _add(a, _product(), 1);
      else if (_eat('-')) a = _add(a, _product(), -1);
      else return a;
    }
  }
  _Polynomial _product() {
    var a = _power();
    while (true) {
      _skip();
      if (_eat('*')) a = _mul(a, _power());
      else if (_nextStartsFactor()) a = _mul(a, _power());
      else if (_eat('/')) a = _div(a, _power());
      else return a;
    }
  }
  _Polynomial _power() {
    var a = _factor();
    _skip();
    if (_eat('^')) {
      _skip();
      final n = _number();
      final k = n.round();
      if ((n - k).abs() > MathSolver._eps || k < 0 || k > 8) throw FormatException();
      var out = _Polynomial([1]);
      for (var j = 0; j < k; j++) out = _mul(out, a);
      return out;
    }
    return a;
  }
  _Polynomial _factor() {
    _skip();
    if (_eat('+')) return _factor();
    if (_eat('-')) return _scale(_factor(), -1);
    if (_eat('(')) {
      final p = _sum();
      if (!_eat(')')) throw FormatException();
      return p;
    }
    if (_peekVariable()) {
      _i += variable.length;
      final out = List<double>.filled(2, 0); out[1] = 1; return _Polynomial(out);
    }
    return _Polynomial([_number()]);
  }
  bool _peekVariable() => source.startsWith(variable, _i);
  bool _nextStartsFactor() {
    _skip();
    if (_i >= source.length) return false;
    return source[_i] == '(' || source[_i] == '.' || RegExp(r'[0-9A-Za-zθ]').hasMatch(source[_i]);
  }
  double _number() {
    _skip();
    final m = RegExp(r'(?:\d+(?:\.\d*)?|\.\d+)').matchAsPrefix(source, _i);
    if (m == null) throw FormatException();
    _i = m.end;
    return double.parse(m.group(0)!);
  }
  void _skip() { while (_i < source.length && source[_i].trim().isEmpty) _i++; }
  bool _eat(String s) { _skip(); if (source.startsWith(s, _i)) { _i += s.length; return true; } return false; }

  _Polynomial _add(_Polynomial a, _Polynomial b, int sign) {
    final n = math.max(a.c.length, b.c.length); final o = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) o[i] = (i < a.c.length ? a.c[i] : 0) + sign * (i < b.c.length ? b.c[i] : 0);
    return _Polynomial(o);
  }
  _Polynomial _scale(_Polynomial a, double s) => _Polynomial(a.c.map((e) => e * s).toList());
  _Polynomial _mul(_Polynomial a, _Polynomial b) {
    final o = List<double>.filled(a.c.length + b.c.length - 1, 0);
    for (var i = 0; i < a.c.length; i++) for (var j = 0; j < b.c.length; j++) o[i + j] += a.c[i] * b.c[j];
    return _Polynomial(o);
  }
  _Polynomial _div(_Polynomial a, _Polynomial b) {
    if (b.degree != 0 || b.c[0].abs() < MathSolver._eps) throw FormatException();
    return _scale(a, 1 / b.c[0]);
  }
}

class _ExpressionParser {
  final String source;
  int _i = 0;
  _ExpressionParser(this.source);
  double parse() { final v = _sum(); _skip(); if (_i != source.length) throw FormatException(); return v; }
  double _sum() { var v = _product(); while (true) { _skip(); if (_eat('+')) v += _product(); else if (_eat('-')) v -= _product(); else return v; } }
  double _product() { var v = _power(); while (true) { _skip(); if (_eat('*')) v *= _power(); else if (_eat('/')) v /= _power(); else if (_nextStarts()) v *= _power(); else return v; } }
  double _power() { var v = _factor(); _skip(); if (_eat('^')) v = math.pow(v, _power()).toDouble(); return v; }
  double _factor() {
    _skip(); if (_eat('+')) return _factor(); if (_eat('-')) return -_factor();
    if (_eat('(')) { final v = _sum(); if (!_eat(')')) throw FormatException(); return v; }
    if (source.startsWith('sqrt', _i)) { _i += 4; return math.sqrt(_factor()); }
    if (source.startsWith('cbrt', _i)) { _i += 4; return math.pow(_factor(), 1 / 3).toDouble(); }
    if (source.startsWith('π', _i)) { _i++; return math.pi; }
    final m = RegExp(r'(?:\d+(?:\.\d*)?|\.\d+)').matchAsPrefix(source, _i);
    if (m == null) throw FormatException(); _i = m.end; return double.parse(m.group(0)!);
  }
  bool _nextStarts() { _skip(); return _i < source.length && (source[_i] == '(' || source[_i] == 'π' || RegExp(r'[0-9]').hasMatch(source[_i])); }
  void _skip() { while (_i < source.length && source[_i].trim().isEmpty) _i++; }
  bool _eat(String s) { _skip(); if (source.startsWith(s, _i)) { _i += s.length; return true; } return false; }
}

String _fmtLocal(double n) {
  if (n.abs() < MathSolver._eps) return '0';
  if ((n - n.roundToDouble()).abs() < MathSolver._eps) return n.round().toString();
  return n.toStringAsFixed(8).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}
