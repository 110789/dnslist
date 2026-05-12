import '../sqlite_service.dart';
import '../database_helper.dart';

class UserPreferencesRepository {
  final SQLiteService _service = SQLiteService();

  Future<String?> getString(String key) async {
    final result = await _service.queryFirst(
      TableNames.userPreferences,
      where: 'pref_key = ?',
      whereArgs: [key],
    );
    return result?['pref_value'] as String?;
  }

  Future<void> setString(String key, String value) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _service.insert(TableNames.userPreferences, {
      'pref_key': key,
      'pref_value': value,
      'updated_at': now,
    });
  }

  Future<bool?> getBool(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    if (value == 'true') return true;
    if (value == 'false') return false;
    return null;
  }

  Future<void> setBool(String key, bool value) async {
    await setString(key, value ? 'true' : 'false');
  }

  Future<int?> getInt(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    return int.tryParse(value);
  }

  Future<void> setInt(String key, int value) async {
    await setString(key, value.toString());
  }

  Future<void> remove(String key) async {
    await _service.delete(
      TableNames.userPreferences,
      where: 'pref_key = ?',
      whereArgs: [key],
    );
  }

  Future<Map<String, String>> getAll() async {
    final results = await _service.query(TableNames.userPreferences);
    return Map.fromEntries(
      results.map((r) => MapEntry(r['pref_key'] as String, r['pref_value'] as String)),
    );
  }
}