class MathVoiceNormalizer {
  static String normalize(String input) {
    var s = input.toLowerCase().trim();

    // Multi-word phrases first so their pieces are not replaced separately.
    const phrases = <String, String>{
      'square root of': 'sqrt ',
      'square root': 'sqrt ',
      'cube root of': 'cbrt ',
      'cube root': 'cbrt ',
      'to the power of': '^',
      'raised to the power of': '^',
      'multiplied by': '*',
      'divided by': '/',
      'equal to': '=',
      'is equal to': '=',
      'less than or equal to': '<=',
      'greater than or equal to': '>=',
      'less than or equals': '<=',
      'greater than or equals': '>=',
      'negative infinity': '-∞',
    };
    phrases.forEach((from, to) => s = s.replaceAll(from, ' $to '));

    const words = <String, String>{
      'root': 'sqrt ',
      'radical': 'sqrt ',
      'plus': '+',
      'add': '+',
      'minus': '-',
      'subtract': '-',
      'times': '*',
      'multiply': '*',
      'over': '/',
      'divided': '/',
      'divide': '/',
      'equals': '=',
      'equals to': '=',
      'power': '^',
      'squared': '^2',
      'square': '^2',
      'cubed': '^3',
      'cube': '^3',
      'point': '.',
      'decimal': '.',
      'pi': 'π',
      'infinity': '∞',
      'theta': 'θ',
      'alpha': 'α',
      'beta': 'β',
      'gamma': 'γ',
      'delta': 'δ',
    };

    // Replace words as tokens, not substrings inside variable names.
    final tokens = RegExp(r"[a-z]+|<=|>=|[0-9]+(?:\.[0-9]+)?|[+\-*/^=()\[\]{},]").allMatches(s);
    final out = <String>[];
    for (final match in tokens) {
      final token = match.group(0)!;
      if (token.isEmpty) continue;
      out.add(words[token] ?? token);
    }

    s = out.join(' ');
    s = _repairRoots(s);
    s = _joinImplicitMultiplication(s);
    return _pretty(s);
  }

  static String _repairRoots(String input) {
    var s = input;
    // sqrt x + 5 -> √(x + 5), sqrt 16 -> √16.
    // We group a plus/minus chain because spoken math commonly omits
    // parentheses around the radicand.
    s = s.replaceAllMapped(
      RegExp(r'\bsqrt\s+([a-zA-Zα-ωΑ-Ω0-9.]+(?:\s+[+\-]\s+[a-zA-Zα-ωΑ-Ω0-9.]+)+)'),
      (m) => '√(${m.group(1)})',
    );
    s = s.replaceAllMapped(
      RegExp(r'\bsqrt\s+(-?\d+(?:\.\d+)?)\b'),
      (m) => '√${m.group(1)}',
    );
    s = s.replaceAllMapped(
      RegExp(r'\bsqrt\s+([a-zA-Zα-ωΑ-Ω])\b'),
      (m) => '√${m.group(1)}',
    );
    s = s.replaceAllMapped(
      RegExp(r'\bsqrt\s+\(([^()]*)\)'),
      (m) => '√(${m.group(1)})',
    );
    s = s.replaceAllMapped(
      RegExp(r'\bcbrt\s+(-?\d+(?:\.\d+)?)\b'),
      (m) => '∛${m.group(1)}',
    );
    s = s.replaceAllMapped(
      RegExp(r'\bcbrt\s+([a-zA-Z])\b'),
      (m) => '∛${m.group(1)}',
    );
    return s;
  }

  static String _joinImplicitMultiplication(String input) {
    var s = input;
    s = s.replaceAllMapped(RegExp(r'(\d)\s+([a-zA-Zα-ωΑ-Ω])'), (m) => '${m.group(1)}${m.group(2)}');
    s = s.replaceAllMapped(RegExp(r'([a-zA-Zα-ωΑ-Ω])\s+(\d)'), (m) => '${m.group(1)}${m.group(2)}');
    return s;
  }

  static String _pretty(String input) {
    var s = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    s = s.replaceAll(' * ', ' × ');
    s = s.replaceAll(' / ', ' ÷ ');
    s = s.replaceAll(' <= ', ' ≤ ');
    s = s.replaceAll(' >= ', ' ≥ ');
    s = s.replaceAll(' + ', ' + ');
    s = s.replaceAll(' - ', ' − ');
    s = s.replaceAll(' ^2', '²');
    s = s.replaceAll(' ^3', '³');
    return s;
  }
}
