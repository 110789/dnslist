import 'sqlite_service.dart';

class BaseRepository {
  final SQLiteService _service = SQLiteService();

  Future<int> count(String table, {String? where, List<dynamic>? whereArgs}) async {
    return await _service.count(table, where: where, whereArgs: whereArgs);
  }

  Future<bool> exists(String table, {String? where, List<dynamic>? whereArgs}) async {
    return await _service.exists(table, where: where, whereArgs: whereArgs);
  }
}