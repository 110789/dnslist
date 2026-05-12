import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';

class DigitalplatCore {
  static const String providerId = 'digitalplat';
  static const String providerName = 'DigitalPlat';
  static const String providerIcon = 'assets/icons/digitalplat.jpg';
  static const String baseUrl = 'https://domain-api.digitalplat.org/api/v1';

  static Dio createClient(String apiToken) {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: DriverConstants.connectionTimeout),
      receiveTimeout: const Duration(milliseconds: DriverConstants.receiveTimeout),
      contentType: 'application/json',
      responseType: ResponseType.json,
      headers: {
        'Authorization': 'Bearer $apiToken',
      },
    ));
  }

  static bool isSuccessResponse(Map<String, dynamic> data) {
    return data['success'] == true;
  }

  static Map<String, dynamic>? extractError(Map<String, dynamic> data) {
    if (data['success'] == false) {
      return {
        'code': data['error']?.toString() ?? 'UNKNOWN',
        'message': data['error']?.toString() ?? 'Unknown error',
      };
    }
    return null;
  }

  static dynamic extractData(Map<String, dynamic> data) {
    if (data.containsKey('data')) {
      return data['data'];
    }
    return null;
  }
}