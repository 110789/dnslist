import 'package:sqflite/sqflite.dart';
import 'database.dart';

class SQLiteService {
  Future<Database> get _db => AppDatabase.instance.database;

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await _db;
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertBatch(String table, List<Map<String, dynamic>> dataList) async {
    final db = await _db;
    final count = await db.transaction((txn) async {
      var inserted = 0;
      for (final data in dataList) {
        await txn.insert(
          table,
          data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        inserted++;
      }
      return inserted;
    });
    return count;
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await _db;
    return await db.update(
      table,
      data,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await _db;
    return await db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await _db;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> queryFirst(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
  }) async {
    final results = await query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await _db;
    return await db.rawQuery(sql, arguments);
  }

  Future<int> rawExecute(String sql, [List<dynamic>? arguments]) async {
    final db = await _db;
    return await db.rawUpdate(sql, arguments);
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await _db;
    return await db.transaction(action);
  }

  Future<int> count(String table, {String? where, List<dynamic>? whereArgs}) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table${where != null ? ' WHERE $where' : ''}',
      whereArgs,
    );
    return result.first['count'] as int;
  }

  Future<bool> exists(String table, {String? where, List<dynamic>? whereArgs}) async {
    final count = await this.count(table, where: where, whereArgs: whereArgs);
    return count > 0;
  }
}