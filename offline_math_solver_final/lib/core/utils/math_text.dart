import '../../features/voice/math_voice_normalizer.dart';

class MathText {
  static String normalize(String input) {
    var s = input.trim();

    const replacements = <String, String>{
      '−': '-',
      '–': '-',
      '—': '-',
      '×': '*',
      '·': '*',
      '÷': '/',
      '≤': '<=',
      '≥': '>=',
      '⁰': '^0',
      '¹': '^1',
      '²': '^2',
      '³': '^3',
      '⁴': '^4',
      '⁵': '^5',
      '⁶': '^6',
      '⁷': '^7',
      '⁸': '^8',
      '⁹': '^9',
      'π': 'pi',
      '∞': 'infinity',
      '＝': '=',
    };

    replacements.forEach((from, to) => s = s.replaceAll(from, to));

    // Convert radical symbols into parser-friendly syntax.
    s = s.replaceAllMapped(RegExp(r'√\s*\(([^()]*)\)'), (m) => 'sqrt(${m.group(1)})');
    s = s.replaceAllMapped(RegExp(r'√\s*([a-zA-Z0-9.]+)'), (m) => 'sqrt(${m.group(1)})');
    s = s.replaceAllMapped(RegExp(r'∛\s*\(([^()]*)\)'), (m) => 'cbrt(${m.group(1)})');
    s = s.replaceAllMapped(RegExp(r'∛\s*([a-zA-Z0-9.]+)'), (m) => 'cbrt(${m.group(1)})');

    s = s.replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll(RegExp(r'(\d)\s+([a-zA-Z])'), r'$1$2');
    s = s.replaceAll(RegExp(r'([a-zA-Z])\s+(\d)'), r'$1$2');

    // Do not blindly turn O/I into numbers. That breaks variables such as I.
    return s.trim();
  }

  static String cleanVoice(String input) => MathVoiceNormalizer.normalize(input);
}
