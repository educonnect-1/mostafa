import 'package:flutter_test/flutter_test.dart';
import 'package:offline_math_solver/features/solver/math_solver.dart';

void main() {
  final solver = MathSolver();

  test('solves linear equation', () {
    final result = solver.solve('2x + 6 = 14');
    expect(result.success, true);
    expect(result.answer, contains('x = 4'));
  });

  test('solves quadratic equation', () {
    final result = solver.solve('x^2 - 5x + 6 = 0');
    expect(result.success, true);
    expect(result.answer, contains('2'));
    expect(result.answer, contains('3'));
  });

  test('solves inequality', () {
    final result = solver.solve('3x - 4 > 8');
    expect(result.success, true);
    expect(result.answer, contains('x > 4'));
  });

  test('evaluates arithmetic', () {
    final result = solver.solve('2 + 5 * 3');
    expect(result.success, true);
    expect(result.answer, '17');
  });
}
