class MathText {
  static String normalize(String input) {
    var s = input.trim();

    const replacements = <String, String>{
      '−': '-',
      '–': '-',
      '—': '-',
      '×': '*',
      '·': '*',
      '⋅': '*',
      '÷': '/',
      '＝': '=',
      '≤': '<=',
      '≥': '>=',
      'π': 'pi',
      '∞': 'infinity',
      '²': '^2',
      '³': '^3',
      '⁴': '^4',
      '⁵': '^5',
      '⁶': '^6',
      '⁷': '^7',
      '⁸': '^8',
      '⁹': '^9',
    };

    replacements.forEach((from, to) => s = s.replaceAll(from, to));

    s = s.replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll(RegExp(r'\s*\^\s*'), '^');
    s = s.replaceAll(RegExp(r'\s*\+\s*'), ' + ');
    s = s.replaceAll(RegExp(r'\s*-\s*'), ' - ');
    s = s.replaceAll(RegExp(r'\s*=\s*'), ' = ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    return s;
  }

  static String cleanVoice(String input) {
    var s = input.toLowerCase();

    const replacements = <String, String>{
      'multiplied by': '*',
      'divided by': '/',
      'to the power of': '^',
      'power of': '^',
      'plus': '+',
      'minus': '-',
      'times': '*',
      'equals': '=',
      'equal to': '=',
      'greater than or equal to': '>=',
      'less than or equal to': '<=',
      'greater than': '>',
      'less than': '<',
    };

    replacements.forEach((from, to) => s = s.replaceAll(from, to));
    return normalize(s);
  }
}
