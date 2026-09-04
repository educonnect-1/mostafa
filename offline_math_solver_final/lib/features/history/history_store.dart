import 'package:shared_preferences/shared_preferences.dart';

class HistoryStore {
  static const _key = 'mathsolve_history';
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<List<String>> load() async {
    return await _prefs.getStringList(_key) ?? <String>[];
  }

  Future<void> add(String problem) async {
    final old = await load();
    final updated = <String>[
      problem,
      ...old.where((item) => item != problem),
    ].take(50).toList();
    await _prefs.setStringList(_key, updated);
  }

  Future<void> remove(String problem) async {
    final old = await load();
    old.remove(problem);
    await _prefs.setStringList(_key, old);
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
  }

  Future<bool> loadStepsPreference() async {
    return await _prefs.getBool('show_steps') ?? true;
  }

  Future<void> saveStepsPreference(bool value) async {
    await _prefs.setBool('show_steps', value);
  }
}
