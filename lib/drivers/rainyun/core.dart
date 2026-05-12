import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';

class RainyunCore {
  static const String providerId = 'rainyun';
  static const String providerName = '雨云';
  static const String providerIcon = 'assets/icons/rainyun.png';
  static const String baseUrl = 'https://api.v2.rainyun.com';

  static Dio createClient(String apiKey) {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: DriverConstants.connectionTimeout),
      receiveTimeout: const Duration(milliseconds: DriverConstants.receiveTimeout),
      headers: {'X-Api-Key': apiKey, 'Content-Type': 'application/json'},
    ));
  }

  static Dio createTestClient(String apiKey) {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: DriverConstants.connectionTimeout),
      receiveTimeout: const Duration(milliseconds: DriverConstants.receiveTimeout),
      headers: {'X-Api-Key': apiKey, 'Content-Type': 'application/json'},
      validateStatus: (status) => true,
    ));
  }
}