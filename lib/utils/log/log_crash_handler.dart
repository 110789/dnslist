import 'dart:async';
import 'package:flutter/foundation.dart';
import 'log_service.dart';
import 'log_entry.dart';
import 'log_level.dart';

class LogCrashHandler {
  static LogCrashHandler? _instance;
  static LogCrashHandler get instance => _instance ??= LogCrashHandler._();

  LogCrashHandler._();

  void install() {
    FlutterError.onError = _handleFlutterError;
    PlatformDispatcher.instance.onError = _handlePlatformError;
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    LogService.instance.fatal(
      module: 'core',
      className: 'FlutterError',
      methodName: 'onError',
      action: 'Flutter 框架异常捕获',
      errorMessage: details.exceptionAsString(),
      stackTrace: details.stack?.toString(),
    );

    LogService.instance.flush();
  }

  bool _handlePlatformError(Object error, StackTrace stackTrace) {
    LogService.instance.fatal(
      module: 'core',
      className: 'PlatformDispatcher',
      methodName: 'onError',
      action: '平台异步异常捕获',
      errorMessage: error.toString(),
      stackTrace: stackTrace.toString(),
    );

    LogService.instance.flush();
    return true;
  }

  void recordError(Object error, StackTrace stackTrace, {String? reason}) {
    LogService.instance.error(
      module: 'core',
      className: 'LogCrashHandler',
      methodName: 'recordError',
      action: '手动记录异常',
      errorMessage: reason ?? error.toString(),
      stackTrace: stackTrace.toString(),
    );
  }

  void recordFatal(String message, {String? stackTrace}) {
    LogService.instance.fatal(
      module: 'core',
      className: 'LogCrashHandler',
      methodName: 'recordFatal',
      action: '致命错误记录',
      errorMessage: message,
      stackTrace: stackTrace,
    );
  }
}