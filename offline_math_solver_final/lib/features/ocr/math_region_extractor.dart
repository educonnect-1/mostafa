import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MathRegionExtractor {
  static String extract(TextRecognitionResult result) {
    final candidates = <String>[];

    for (final block in result.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;
        if (_looksMathematical(text)) {
          candidates.add(text);
        }
      }
    }

    // Prefer the smallest contiguous set of mathematical-looking lines.
    // This prevents instructions such as "Solve the following equation" from
    // entering the solver while preserving multi-line fractions/systems.
    if (candidates.isEmpty) return '';
    return candidates.join('\n');
  }

  static bool _looksMathematical(String text) {
    final s = text.trim();
    if (s.isEmpty) return false;

    final normalized = s
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll('√', 'sqrt')
        .replaceAll('∫', 'int')
        .replaceAll('≤', '<=')
        .replaceAll('≥', '>=');

    final hasDigit = RegExp(r'\d').hasMatch(normalized);
    final hasVariable = RegExp(r'\b[a-zA-Z]\b').hasMatch(normalized) ||
        RegExp(r'[a-zA-Z]\s*[=+\-*/^]').hasMatch(normalized);
    final hasOperator = RegExp(r'[=+\-*/^<>≤≥√∫]').hasMatch(s);
    final hasMathStructure = RegExp(r'[()\[\]{}]|\d\s*[a-zA-Z]|[a-zA-Z]\s*\d').hasMatch(normalized);

    // Strong mathematical signals.
    if (s.contains('=') || s.contains('≤') || s.contains('≥') || s.contains('√') || s.contains('∫')) {
      return true;
    }
    if (hasDigit && (hasOperator || hasMathStructure)) return true;
    if (hasVariable && hasOperator) return true;

    // Standalone numeric expressions such as "12 / 4".
    if (hasDigit && RegExp(r'^\s*[\d.]+\s*[+\-*/×÷]\s*[\d.]+\s*$').hasMatch(s)) {
      return true;
    }

    return false;
  }
}
