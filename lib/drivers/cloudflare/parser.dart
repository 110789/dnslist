import 'package:dio/dio.dart';
import '../../utils/driver/driver_utils.dart';
import 'core.dart';

class CloudflareParser {
  static Map<String, dynamic> parseResponse(dynamic data) {
    if (data == null) return DriverResponseParser.parseEmpty();
    if (data is! Map) return DriverResponseParser.parseInvalid();

    if (data['success'] == true) return {'success': true};

    final errorCode = CloudflareCore.getErrorCode(data) ?? 'UNKNOWN';
    final errorMessage = CloudflareCore.getErrorMessage(data) ?? 'Unknown error';

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

  static Map<String, dynamic> parseSuccess({Map<String, dynamic>? data}) {
    final result = <String, dynamic>{'success': true, 'statusCode': 'OK'};
    if (data != null) result['data'] = data;
    return result;
  }
}