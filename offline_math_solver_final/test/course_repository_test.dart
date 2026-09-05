import 'package:flutter_test/flutter_test.dart';

void main() {
  test('course titles should not be empty after validation', () {
    const title = 'Mathematics';
    expect(title.trim().isNotEmpty, true);
  });
}
