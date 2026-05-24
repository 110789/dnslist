import 'log_level.dart';

class LogConfig {
  final bool debugEnabled;
  final bool infoEnabled;
  final bool warnEnabled;
  final bool errorEnabled;
  final bool fatalEnabled;

  final bool enableLocalPersist;
  final int maxLocalLogs;
  final int maxLogAgeDays;

  final bool enableConsoleOutput;
  final bool enableCrashReport;

  final Map<String, bool> moduleEnabled;

  const LogConfig({
    this.debugEnabled = false,
    this.infoEnabled = true,
    this.warnEnabled = true,
    this.errorEnabled = true,
    this.fatalEnabled = true,
    this.enableLocalPersist = true,
    this.maxLocalLogs = 1000,
    this.maxLogAgeDays = 7,
    this.enableConsoleOutput = true,
    this.enableCrashReport = true,
    this.moduleEnabled = const {
      'architecture': true,
      'core': true,
      'drivers': true,
      'ux': true,
      'ui': true,
      'utils': true,
      'services': true,
    },
  });

  bool isLevelEnabled(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return debugEnabled;
      case LogLevel.info:
        return infoEnabled;
      case LogLevel.warn:
        return warnEnabled;
      case LogLevel.error:
        return errorEnabled;
      case LogLevel.fatal:
        return fatalEnabled;
    }
  }

  bool isModuleEnabled(String module) => moduleEnabled[module] ?? true;

  LogConfig copyWith({
    bool? debugEnabled,
    bool? infoEnabled,
    bool? warnEnabled,
    bool? errorEnabled,
    bool? fatalEnabled,
    bool? enableLocalPersist,
    int? maxLocalLogs,
    int? maxLogAgeDays,
    bool? enableConsoleOutput,
    bool? enableCrashReport,
    Map<String, bool>? moduleEnabled,
  }) => LogConfig(
    debugEnabled: debugEnabled ?? this.debugEnabled,
    infoEnabled: infoEnabled ?? this.infoEnabled,
    warnEnabled: warnEnabled ?? this.warnEnabled,
    errorEnabled: errorEnabled ?? this.errorEnabled,
    fatalEnabled: fatalEnabled ?? this.fatalEnabled,
    enableLocalPersist: enableLocalPersist ?? this.enableLocalPersist,
    maxLocalLogs: maxLocalLogs ?? this.maxLocalLogs,
    maxLogAgeDays: maxLogAgeDays ?? this.maxLogAgeDays,
    enableConsoleOutput: enableConsoleOutput ?? this.enableConsoleOutput,
    enableCrashReport: enableCrashReport ?? this.enableCrashReport,
    moduleEnabled: moduleEnabled ?? this.moduleEnabled,
  );
}