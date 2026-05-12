import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';
import 'core.dart';

class CloudnsParser {
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

    final status = parsed['status']?.toString();
    if (status == 'Success') return {'success': true};

    final message = parsed['statusDescription']?.toString() ?? '';
    if (message.isNotEmpty) {
      return DriverResponseParser.parseError(message, message);
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

  static Map<String, dynamic> parseSuccess({Map<String, dynamic>? data}) {
    final result = <String, dynamic>{'success': true, 'statusCode': 'OK'};
    if (data != null) result['data'] = data;
    return result;
  }
}