import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';

class DnspodCore {
  static const String providerId = 'dnspod';
  static const String providerName = 'DNSPod';
  static const String providerIcon = 'assets/icons/dnspod.svg';
  static const String baseUrl = 'https://dnspod.tencentcloudapi.com';

  static Dio createClient() {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: DriverConstants.connectionTimeout),
      receiveTimeout: const Duration(milliseconds: DriverConstants.receiveTimeout),
      contentType: 'application/json; charset=utf-8',
      responseType: ResponseType.plain,
    ));
  }

  static bool isSuccessResponse(Map<String, dynamic> data) {
    return data.containsKey('Response') && !(data['Response'] as Map).containsKey('Error');
  }

  static Map<String, dynamic>? extractError(Map<String, dynamic> data) {
    final response = data['Response'] as Map?;
    if (response == null) return null;
    final error = response['Error'] as Map?;
    if (error == null) return null;
    return {
      'code': error['Code']?.toString() ?? 'UNKNOWN',
      'message': error['Message']?.toString() ?? '',
    };
  }

  static Map<String, dynamic>? extractData(Map<String, dynamic> data) {
    final response = data['Response'] as Map?;
    if (response == null) return null;
    return Map<String, dynamic>.from(response);
  }
}