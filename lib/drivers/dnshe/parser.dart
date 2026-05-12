import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';

class DnsheParser {
  static Map<String, dynamic> parseResponse(dynamic data) {
    if (data == null) return parseEmpty();
    if (data is! Map) return parseInvalid();

    if (data['success'] == true) return {'success': true};

    final errorCode = data['error_code']?.toString() ??
                       data['errorCode']?.toString() ??
                       'UNKNOWN';
    final errorMessage = data['message']?.toString() ??
                         data['error']?.toString() ??
                         'Unknown error';

    return parseError(errorMessage, errorCode);
  }

  static Map<String, dynamic> parseException(DioException e) {
    final responseData = e.response?.data;
    if (responseData != null) {
      final parsed = parseResponse(responseData);
      if (parsed['success'] == true || parsed['errorCode'] != 'UNKNOWN') {
        return parsed;
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return parseError('Connection timeout', 'TIMEOUT');
      case DioExceptionType.receiveTimeout:
        return parseError('Response timeout', 'TIMEOUT');
      case DioExceptionType.connectionError:
        return parseError('Connection failed', 'NETWORK_ERROR');
      case DioExceptionType.cancel:
        return parseError('Request cancelled', 'CANCELLED');
      case DioExceptionType.badResponse:
        return parseError(
          'Server error: ${e.response?.statusCode}',
          'HTTP_${e.response?.statusCode ?? 'UNKNOWN'}',
        );
      default:
        return parseError(e.message ?? 'Request failed', 'REQUEST_FAILED');
    }
  }

  static Map<String, dynamic> parseError(String message, String errorCode) {
    final truncated = message.length > DriverConstants.maxMessageLen
        ? message.substring(0, DriverConstants.maxMessageLen)
        : message;
    return {'error': truncated, 'errorCode': errorCode};
  }

  static Map<String, dynamic> parseEmpty() => parseError('Empty response', 'EMPTY_RESPONSE');

  static Map<String, dynamic> parseInvalid() => parseError('Invalid response', 'INVALID_RESPONSE');

  static Map<String, dynamic> parseUnknown(String details) => parseError(details, 'UNKNOWN');

  static Map<String, dynamic> parseSuccess({Map<String, dynamic>? data, String? message}) {
    final result = <String, dynamic>{'success': true, 'statusCode': 'OK'};
    if (data != null) result['data'] = data;
    if (message != null) result['message'] = message;
    return result;
  }
}