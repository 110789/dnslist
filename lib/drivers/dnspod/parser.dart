import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dp/utils/driver/driver_utils.dart';
import 'core.dart';

class DnspodParser {
  static Map<String, dynamic> parseResponse(dynamic data) {
    if (data == null) return DriverResponseParser.parseEmpty();
    
    Map<String, dynamic>? dataMap;
    if (data is Map) {
      dataMap = Map<String, dynamic>.from(data);
    } else if (data is String) {
      try {
        final parsed = jsonDecode(data);
        if (parsed is Map) {
          dataMap = Map<String, dynamic>.from(parsed);
        } else {
          return DriverResponseParser.parseInvalid();
        }
      } catch (_) {
        return DriverResponseParser.parseInvalid();
      }
    } else {
      return DriverResponseParser.parseInvalid();
    }

    final errorInfo = DnspodCore.extractError(dataMap!);
    if (errorInfo != null) {
      final code = errorInfo['code'] as String;
      final message = errorInfo['message'] as String;
      return DriverResponseParser.parseError(message, code);
    }

    if (DnspodCore.isSuccessResponse(dataMap)) {
      return {'success': true, 'data': DnspodCore.extractData(dataMap), 'statusCode': 'OK'};
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
        if (parsed['success'] == true || (parsed['errorCode'] != 'UNKNOWN' && parsed['error'] != 'Unknown error')) {
          return parsed;
        }
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