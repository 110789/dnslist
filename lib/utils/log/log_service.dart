import 'dart:developer' as developer;
import 'log_level.dart';
import 'log_entry.dart';
import 'log_config.dart';
import 'log_printer.dart';
import 'log_writer.dart';

abstract class ILogService {
  void init({LogConfig? config, LogWriter? writer});
  void debug({required String module, required String className, required String methodName, required String action, Map<String, dynamic>? data, int? durationMs, String? status});
  void info({required String module, required String className, required String methodName, required String action, Map<String, dynamic>? data, int? durationMs, String? status});
  void warn({required String module, required String className, required String methodName, required String action, Map<String, dynamic>? data, String? status, String? errorMessage});
  void error({required String module, required String className, required String methodName, required String action, Map<String, dynamic>? data, String? status, String? errorMessage, String? stackTrace});
  void fatal({required String module, required String className, required String methodName, required String action, Map<String, dynamic>? data, String? status, String? errorMessage, String? stackTrace});
  Future<void> flush();
  Future<List<LogEntry>> getLogs({LogLevel? level, String? module});
  Future<void> clearLogs();
}

class LogService implements ILogService {
  static LogService? _instance;
  static LogService get instance => _instance ??= LogService._();

  LogConfig _config = const LogConfig();
  late LogPrinter _printer;
  LogWriter? _writer;
  bool _isInitialized = false;

  LogService._();

  bool get isInitialized => _isInitialized;
  LogConfig get config => _config;

  @override
  void init({LogConfig? config, LogWriter? writer}) {
    _config = config ?? const LogConfig();
    _printer = LogPrinter(_config);
    _writer = writer;
    _isInitialized = true;
  }

  @override
  void updateConfig(LogConfig config) {
    _config = config;
    _printer = LogPrinter(config);
  }

  @override
  void setModuleEnabled(String module, bool enabled) {
    final newModuleEnabled = Map<String, bool>.from(_config.moduleEnabled);
    newModuleEnabled[module] = enabled;
    _config = _config.copyWith(moduleEnabled: newModuleEnabled);
  }

  @override
  void setLevelEnabled(LogLevel level, bool enabled) {
    switch (level) {
      case LogLevel.debug:
        _config = _config.copyWith(debugEnabled: enabled);
      case LogLevel.info:
        _config = _config.copyWith(infoEnabled: enabled);
      case LogLevel.warn:
        _config = _config.copyWith(warnEnabled: enabled);
      case LogLevel.error:
        _config = _config.copyWith(errorEnabled: enabled);
      case LogLevel.fatal:
        _config = _config.copyWith(fatalEnabled: enabled);
    }
  }

  @override
  void log(LogEntry entry) {
    if (!_isInitialized) return;
    if (!_config.isLevelEnabled(entry.level)) return;
    if (!_config.isModuleEnabled(entry.module)) return;

    if (_config.enableConsoleOutput) {
      final message = _printer.format(entry);
      developer.log(
        message,
        name: 'DNS',
        level: _mapLevelToDevLevel(entry.level),
      );
    }

    if (_config.enableLocalPersist && entry.level.shouldPersist && _writer != null) {
      _writer!.write(entry);
    }
  }

  int _mapLevelToDevLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warn:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.fatal:
        return 1200;
    }
  }

  @override
  Future<void> flush() async {
    await _writer?.flush();
  }

  @override
  Future<List<LogEntry>> getLogs({LogLevel? level, String? module}) async {
    return await _writer?.getLogs(level: level, module: module) ?? [];
  }

  @override
  Future<void> clearLogs() async {
    await _writer?.clear();
  }

  @override
  void debug({
    required String module,
    required String className,
    required String methodName,
    required String action,
    Map<String, dynamic>? data,
    int? durationMs,
    String? status,
  }) => log(LogEntry(
    timestamp: DateTime.now(),
    level: LogLevel.debug,
    module: module,
    className: className,
    methodName: methodName,
    action: action,
    data: data,
    durationMs: durationMs,
    status: status,
  ));

  @override
  void info({
    required String module,
    required String className,
    required String methodName,
    required String action,
    Map<String, dynamic>? data,
    int? durationMs,
    String? status,
  }) => log(LogEntry(
    timestamp: DateTime.now(),
    level: LogLevel.info,
    module: module,
    className: className,
    methodName: methodName,
    action: action,
    data: data,
    durationMs: durationMs,
    status: status,
  ));

  @override
  void warn({
    required String module,
    required String className,
    required String methodName,
    required String action,
    Map<String, dynamic>? data,
    String? status,
    String? errorMessage,
  }) => log(LogEntry(
    timestamp: DateTime.now(),
    level: LogLevel.warn,
    module: module,
    className: className,
    methodName: methodName,
    action: action,
    data: data,
    status: status,
    errorMessage: errorMessage,
  ));

  @override
  void error({
    required String module,
    required String className,
    required String methodName,
    required String action,
    Map<String, dynamic>? data,
    String? status,
    String? errorMessage,
    String? stackTrace,
  }) => log(LogEntry(
    timestamp: DateTime.now(),
    level: LogLevel.error,
    module: module,
    className: className,
    methodName: methodName,
    action: action,
    data: data,
    status: status,
    errorMessage: errorMessage,
    stackTrace: stackTrace,
  ));

  @override
  void fatal({
    required String module,
    required String className,
    required String methodName,
    required String action,
    Map<String, dynamic>? data,
    String? status,
    String? errorMessage,
    String? stackTrace,
  }) => log(LogEntry(
    timestamp: DateTime.now(),
    level: LogLevel.fatal,
    module: module,
    className: className,
    methodName: methodName,
    action: action,
    data: data,
    status: status,
    errorMessage: errorMessage,
    stackTrace: stackTrace,
  ));

  static void d({
    required String module,
    required String className,
    required String methodName,
    required String action,
    Map<String, dynamic>? data,
    int? durationMs,
    String? status,
  }) => instance.debug(
    module: module,
    className: className,
    methodName: methodName,
    action: action,
    data: data,
    durationMs: durationMs,
    status: status,
  );

  static void i({
    required String module,
    required String className,
    required String methodName,
    required String action,
    Map<String, dynamic>? data,
    int? durationMs,
    String? status,
  }) => instance.info(
    module: module,
    className: className,
    methodName: methodName,
    action: action,
    data: data,
    durationMs: durationMs,
    status: status,
  );

  static void w({
    required String module,
    required String className,
    required String methodName,
    required String action,
    Map<String, dynamic>? data,
    String? status,
    String? errorMessage,
  }) => instance.warn(
    module: module,
    className: className,
    methodName: methodName,
    action: action,
    data: data,
    status: status,
    errorMessage: errorMessage,
  );

  static void e({
    required String module,
    required String className,
    required String methodName,
    required String action,
    Map<String, dynamic>? data,
    String? status,
    String? errorMessage,
    String? stackTrace,
  }) => instance.error(
    module: module,
    className: className,
    methodName: methodName,
    action: action,
    data: data,
    status: status,
    errorMessage: errorMessage,
    stackTrace: stackTrace,
  );

  static void f({
    required String module,
    required String className,
    required String methodName,
    required String action,
    Map<String, dynamic>? data,
    String? status,
    String? errorMessage,
    String? stackTrace,
  }) => instance.fatal(
    module: module,
    className: className,
    methodName: methodName,
    action: action,
    data: data,
    status: status,
    errorMessage: errorMessage,
    stackTrace: stackTrace,
  );
}