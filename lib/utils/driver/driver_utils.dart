import 'dart:convert';
import 'package:dio/dio.dart';

class DriverConstants {
  static const int maxMessageLen = 200;
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
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

class DriverResponseParser {
  static Map<String, dynamic> parseEmpty() => {'error': 'Empty response', 'errorCode': 'EMPTY'};
  static Map<String, dynamic> parseInvalid() => {'error': 'Invalid response', 'errorCode': 'INVALID'};

  static Map<String, dynamic> parseError(String message, String errorCode) {
    final truncated = message.length > DriverConstants.maxMessageLen
        ? message.substring(0, DriverConstants.maxMessageLen)
        : message;
    return {'error': truncated, 'errorCode': errorCode};
  }

  static Map<String, dynamic> parseException(Object e) {
    final result = DioErrorParser.parse(e);
    if (result['errorCode'] != 'UNKNOWN') return result;

    if (e is! DioException) return result;
    final responseData = e.response?.data;
    if (responseData != null) {
      if (responseData is Map) {
        final message = _extractMessage(responseData);
        if (message.isNotEmpty) {
          return {'error': message, 'errorCode': 'RESPONSE_ERROR'};
        }
      } else if (responseData is String) {
        return {'error': responseData, 'errorCode': 'RESPONSE_ERROR'};
      }
    }
    return result;
  }

  static String _extractMessage(Map data) {
    if (data.containsKey('message')) return data['message']?.toString() ?? '';
    if (data.containsKey('error')) return data['error']?.toString() ?? '';
    if (data.containsKey('msg')) return data['msg']?.toString() ?? '';
    if (data.containsKey('statusDescription')) return data['statusDescription']?.toString() ?? '';
    return '';
  }
}

dynamic parseJson(String jsonStr) {
  try {
    return jsonDecode(jsonStr);
  } catch (_) {
    return null;
  }
}