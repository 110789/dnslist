import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';

class CloudnsCore {
  static const String providerId = 'cloudns';
  static const String providerName = 'ClouDNS';
  static const String providerIcon = 'assets/icons/cloudns.jpg';
  static const String baseUrl = 'https://api.cloudns.net';

  static Dio createClient() {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: DriverConstants.connectionTimeout),
      receiveTimeout: const Duration(milliseconds: DriverConstants.receiveTimeout),
    ));
  }

  static Dio createAuthenticatedClient(int authId, String authPassword) {
    final client = createClient();
    client.options.queryParameters = {
      'auth-id': authId,
      'auth-password': authPassword,
    };
    return client;
  }
}