import 'dart:convert';
import 'log_entry.dart';
import 'log_config.dart';
import 'log_level.dart';

class LogPrinter {
  final LogConfig _config;

  LogPrinter(this._config);

  String format(LogEntry entry) {
    final buffer = StringBuffer();

    buffer.write(_formatTimestamp(entry.timestamp));
    buffer.write(' ');
    buffer.write(_formatLevel(entry.level));
    buffer.write(' ');
    buffer.write(_formatModule(entry.module));
    buffer.write(' ');
    buffer.write(_formatClassMethod(entry.classMethod));
    buffer.write(' ');
    buffer.write(_formatAction(entry.action));

    if (entry.data != null && entry.data!.isNotEmpty) {
      buffer.write(' ');
      buffer.write(_formatData(entry.data!));
    }

    if (entry.durationMs != null) {
      buffer.write(' ');
      buffer.write(_formatDuration(entry.durationMs!));
    }

    if (entry.status != null) {
      buffer.write(' ');
      buffer.write(_formatStatus(entry.status!));
    }

    if (entry.errorMessage != null) {
      buffer.write(' ');
      buffer.write(_formatError(entry.errorMessage!));
    }

    if (entry.stackTrace != null && (entry.level == LogLevel.error || entry.level == LogLevel.fatal)) {
      buffer.write('\n');
      buffer.write(entry.stackTrace);
    }

    return buffer.toString();
  }

  String _formatTimestamp(DateTime dt) {
    final iso = dt.toIso8601String();
    final dotIndex = iso.lastIndexOf('.');
    if (dotIndex > 0) {
      final ms = iso.substring(dotIndex + 1, dotIndex + 4);
      return '${iso.substring(0, dotIndex)}.${ms}Z';
    }
    return iso.replaceAll('Z', 'Z');
  }

  String _formatLevel(LogLevel level) {
    return level.coloredTag();
  }

  String _formatModule(String module) {
    return '[${module.toUpperCase().padRight(12)}]';
  }

  String _formatClassMethod(String classMethod) {
    return classMethod.padRight(35);
  }

  String _formatAction(String action) {
    return action;
  }

  String _formatData(Map<String, dynamic> data) {
    try {
      final jsonStr = jsonEncode(data);
      if (jsonStr.length > 100) {
        return jsonStr.substring(0, 97) + '...';
      }
      return jsonStr;
    } catch (_) {
      return '{}';
    }
  }

  String _formatDuration(int ms) {
    if (ms < 1000) {
      return '${ms}ms';
    }
    return '${(ms / 1000).toStringAsFixed(2)}s';
  }

  String _formatStatus(String status) {
    final colorCode = switch (status) {
      'success' => '\x1B[32m',
      'fail' || 'error' => '\x1B[31m',
      'pending' => '\x1B[33m',
      _ => '\x1B[0m',
    };
    return '$colorCode[$status]\x1B[0m';
  }

  String _formatError(String error) {
    return '\x1B[31mERROR: $error\x1B[0m';
  }

  String formatPlain(LogEntry entry) {
    final buffer = StringBuffer();
    buffer.write('${entry.timestampIso} ');
    buffer.write('${entry.level.tag} ');
    buffer.write('[${entry.module.toUpperCase()}] ');
    buffer.write('${entry.classMethod} ');
    buffer.write(entry.action);

    if (entry.data != null && entry.data!.isNotEmpty) {
      buffer.write(' ${jsonEncode(entry.data)}');
    }

    if (entry.durationMs != null) {
      buffer.write(' ${entry.durationMs}ms');
    }

    if (entry.status != null) {
      buffer.write(' ${entry.status}');
    }

    if (entry.errorMessage != null) {
      buffer.write(' ${entry.errorMessage}');
    }

    return buffer.toString();
  }
}