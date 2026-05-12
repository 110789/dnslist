import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';

class RainyunParser {
  static dynamic parseResponseData(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return null;
      }
    }
    return data;
  }

  static Map<String, dynamic> parseResponse(dynamic data) {
    final parsed = parseResponseData(data);
    if (parsed == null) return DriverResponseParser.parseEmpty();
    if (parsed is! Map) return DriverResponseParser.parseInvalid();

    final code = parsed['code'];
    if (code == 200 || code == '200') return {'success': true};

    final errorCode = parsed['error_code']?.toString() ?? code?.toString() ?? 'UNKNOWN';
    final errorMessage = parsed['message']?.toString() ?? parsed['msg']?.toString() ?? '';

    if (errorMessage.isNotEmpty) {
      return DriverResponseParser.parseError(errorMessage, errorCode);
    }

    return DriverResponseParser.parseInvalid();
  }

  static Map<String, dynamic> parseException(Object e, DioException? dioException) {
    final result = DriverResponseParser.parseException(e);
    if (result['errorCode'] != 'UNKNOWN') return result;

    if (dioException != null) {
      final responseData = dioException.response?.data;
      if (responseData != null) {
        final parsed = parseResponse(responseData);
        if (parsed['errorCode'] != 'UNKNOWN') return parsed;
      }
    }
    return result;
  }

  static Map<String, dynamic> parseSuccess({Map<String, dynamic>? data, String? message}) {
    final result = <String, dynamic>{'success': true, 'statusCode': 'OK'};
    if (data != null) result['data'] = data;
    if (message != null) result['message'] = message;
    return result;
  }
}