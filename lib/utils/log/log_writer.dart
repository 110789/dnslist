import 'dart:convert';
import '../../database/sqlite_service.dart';
import 'log_entry.dart';
import 'log_level.dart';
import 'log_config.dart';

abstract class LogWriter {
  Future<void> write(LogEntry entry);
  Future<void> flush();
  Future<List<LogEntry>> getLogs({LogLevel? level, String? module});
  Future<void> clear();
}

class SQLiteLogWriter extends LogWriter {
  static const String _tableName = 'app_logs';
  final SQLiteService _db;
  final LogConfig _config;

  final List<LogEntry> _buffer = [];
  static const int _flushThreshold = 10;

  SQLiteLogWriter(this._db, this._config);

  @override
  Future<void> write(LogEntry entry) async {
    _buffer.add(entry);
    if (_buffer.length >= _flushThreshold) {
      await flush();
    }
  }

  @override
  Future<void> flush() async {
    if (_buffer.isEmpty) return;

    final batch = List<LogEntry>.from(_buffer);
    _buffer.clear();

    try {
      final values = batch.map((e) => {
        'timestamp': e.timestampIso,
        'level': e.level.tag,
        'module': e.module,
        'class_name': e.className,
        'method_name': e.methodName,
        'action': e.action,
        'data': jsonEncode(e.data),
        'duration_ms': e.durationMs,
        'status': e.status,
        'error_message': e.errorMessage,
        'stack_trace': e.stackTrace,
      }).toList();

      await _db.insertBatch(_tableName, values);
      await _cleanupOldLogs();
    } catch (_) {}
  }

  Future<void> _cleanupOldLogs() async {
    try {
      final count = await _db.count(_tableName);
      if (count > _config.maxLocalLogs) {
        final deleteCount = count - _config.maxLocalLogs;
        await _db.rawExecute(
          'DELETE FROM $_tableName WHERE id IN (SELECT id FROM $_tableName ORDER BY timestamp ASC LIMIT ?)',
          [deleteCount],
        );
      }
    } catch (_) {}
  }

  @override
  Future<List<LogEntry>> getLogs({LogLevel? level, String? module}) async {
    try {
      String? where;
      List<dynamic>? whereArgs;

      if (level != null && module != null) {
        where = 'level = ? AND module = ?';
        whereArgs = [level.tag, module];
      } else if (level != null) {
        where = 'level = ?';
        whereArgs = [level.tag];
      } else if (module != null) {
        where = 'module = ?';
        whereArgs = [module];
      }

      final results = await _db.query(
        _tableName,
        where: where,
        whereArgs: whereArgs,
        orderBy: 'timestamp DESC',
        limit: 200,
      );

      return results.map((row) => LogEntry(
        timestamp: DateTime.parse(row['timestamp'] as String),
        level: LogLevel.values.firstWhere((e) => e.tag == row['level']),
        module: row['module'] as String,
        className: row['class_name'] as String,
        methodName: row['method_name'] as String,
        action: row['action'] as String,
        data: row['data'] != null ? jsonDecode(row['data'] as String) : null,
        durationMs: row['duration_ms'] as int?,
        status: row['status'] as String?,
        errorMessage: row['error_message'] as String?,
        stackTrace: row['stack_trace'] as String?,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _db.delete(_tableName);
    } catch (_) {}
  }
}

class MemoryLogWriter extends LogWriter {
  final List<LogEntry> _logs = [];
  final int _maxLogs;

  MemoryLogWriter({int maxLogs = 500}) : _maxLogs = maxLogs;

  @override
  Future<void> write(LogEntry entry) async {
    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
  }

  @override
  Future<void> flush() async {}

  @override
  Future<List<LogEntry>> getLogs({LogLevel? level, String? module}) async {
    var filtered = _logs;
    if (level != null) {
      filtered = filtered.where((e) => e.level == level).toList();
    }
    if (module != null) {
      filtered = filtered.where((e) => e.module == module).toList();
    }
    return filtered.reversed.toList();
  }

  @override
  Future<void> clear() async {
    _logs.clear();
  }
}