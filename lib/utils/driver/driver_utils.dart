import 'package:dio/dio.dart';

class DriverConstants {
  static const int maxMessageLen = 200;
}

class DioErrorParser {
  static Map<String, dynamic> parse(Object e) {
    if (e is! DioException) return {'error': 'Request failed', 'errorCode': 'UNKNOWN'};

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return {'error': 'Connection timeout', 'errorCode': 'TIMEOUT'};
      case DioExceptionType.receiveTimeout:
        return {'error': 'Response timeout', 'errorCode': 'TIMEOUT'};
      case DioExceptionType.connectionError:
        return {'error': 'Connection failed', 'errorCode': 'NETWORK'};
      case DioExceptionType.cancel:
        return {'error': 'Request cancelled', 'errorCode': 'CANCELLED'};
      default:
        return {'error': 'Request failed', 'errorCode': 'UNKNOWN'};
    }
  }

  static String truncateMessage(String message, {int maxLen = DriverConstants.maxMessageLen}) {
    if (message.length <= maxLen) return message;
    return message.substring(0, maxLen);
  }
}
