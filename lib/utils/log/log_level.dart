enum LogLevel {
  debug(0, 'D', '\x1B[36m'),
  info(1, 'I', '\x1B[32m'),
  warn(2, 'W', '\x1B[33m'),
  error(3, 'E', '\x1B[31m'),
  fatal(4, 'F', '\x1B[35m');

  final int priority;
  final String tag;
  final String colorCode;

  const LogLevel(this.priority, this.tag, this.colorCode);

  static const String _reset = '\x1B[0m';

  String coloredTag() => '$colorCode$tag$_reset';

  bool get isDebug => this == LogLevel.debug;
  bool get isInfo => this == LogLevel.info;
  bool get isWarn => this == LogLevel.warn;
  bool get isError => this == LogLevel.error;
  bool get isFatal => this == LogLevel.fatal;

  bool get shouldPersist => this != LogLevel.debug;
}