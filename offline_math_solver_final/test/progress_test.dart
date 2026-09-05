import 'package:flutter_test/flutter_test.dart';

void main() {
  test('progress remains in valid range', () {
    expect(0.0.clamp(0, 100), 0);
    expect(100.0.clamp(0, 100), 100);
  });
}
