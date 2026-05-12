import '../sqlite_service.dart';
import '../database_helper.dart';

class AppSettingsRepository {
  final SQLiteService _service = SQLiteService();

  Future<String?> getString(String key) async {
    final result = await _service.queryFirst(
      TableNames.appSettings,
      where: 'setting_key = ?',
      whereArgs: [key],
    );
    return result?['setting_value'] as String?;
  }

  Future<void> setString(String key, String value) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _service.insert(TableNames.appSettings, {
      'setting_key': key,
      'setting_value': value,
      'setting_type': 'string',
      'updated_at': now,
    });
  }

  Future<int?> getInt(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    return int.tryParse(value);
  }

  Future<void> setInt(String key, int value) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _service.insert(TableNames.appSettings, {
      'setting_key': key,
      'setting_value': value.toString(),
      'setting_type': 'int',
      'updated_at': now,
    });
  }

  Future<bool?> getBool(String key) async {
    final value = await getString(key);
    if (value == null) return null;
    return value == 'true';
  }

  Future<void> setBool(String key, bool value) async {
    await setString(key, value ? 'true' : 'false');
  }

  Future<void> remove(String key) async {
    await _service.delete(
      TableNames.appSettings,
      where: 'setting_key = ?',
      whereArgs: [key],
    );
  }
}