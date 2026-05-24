import 'log_level.dart';

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String module;
  final String className;
  final String methodName;
  final String action;
  final Map<String, dynamic>? data;
  final int? durationMs;
  final String? status;
  final String? stackTrace;
  final String? errorMessage;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.module,
    required this.className,
    required this.methodName,
    required this.action,
    this.data,
    this.durationMs,
    this.status,
    this.stackTrace,
    this.errorMessage,
  });

  String get timestampIso => timestamp.toUtc().toIso8601String().replaceAll('Z', 'Z');

  String get moduleTag => module.toUpperCase().padRight(10);

  String get classMethod => '$className.$methodName';

  Map<String, dynamic> toMap() => {
    'timestamp': timestampIso,
    'level': level.tag,
    'module': module,
    'className': className,
    'methodName': methodName,
    'action': action,
    'data': data,
    'durationMs': durationMs,
    'status': status,
    'stackTrace': stackTrace,
    'errorMessage': errorMessage,
  };

  factory LogEntry.fromMap(Map<String, dynamic> map) => LogEntry(
    timestamp: DateTime.parse(map['timestamp'] as String),
    level: LogLevel.values.firstWhere((e) => e.tag == map['level']),
    module: map['module'] as String,
    className: map['className'] as String,
    methodName: map['methodName'] as String,
    action: map['action'] as String,
    data: map['data'] as Map<String, dynamic>?,
    durationMs: map['durationMs'] as int?,
    status: map['status'] as String?,
    stackTrace: map['stackTrace'] as String?,
    errorMessage: map['errorMessage'] as String?,
  );

  LogEntry copyWith({
    DateTime? timestamp,
    LogLevel? level,
    String? module,
    String? className,
    String? methodName,
    String? action,
    Map<String, dynamic>? data,
    int? durationMs,
    String? status,
    String? stackTrace,
    String? errorMessage,
  }) => LogEntry(
    timestamp: timestamp ?? this.timestamp,
    level: level ?? this.level,
    module: module ?? this.module,
    className: className ?? this.className,
    methodName: methodName ?? this.methodName,
    action: action ?? this.action,
    data: data ?? this.data,
    durationMs: durationMs ?? this.durationMs,
    status: status ?? this.status,
    stackTrace: stackTrace ?? this.stackTrace,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}