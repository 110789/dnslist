import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';

class DnsheParser {
  static Map<String, dynamic> parseResponse(dynamic data) {
    if (data == null) return DriverResponseParser.parseEmpty();
    if (data is! Map) return DriverResponseParser.parseInvalid();

    if (data['success'] == true) return {'success': true};

    final errorCode = data['error_code']?.toString() ?? data['errorCode']?.toString() ?? 'UNKNOWN';
    final errorMessage = data['message']?.toString() ?? data['error']?.toString() ?? 'Unknown error';

    return DriverResponseParser.parseError(errorMessage, errorCode);
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