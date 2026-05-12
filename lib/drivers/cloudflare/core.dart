import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';

class CloudflareCore {
  static const String providerId = 'cloudflare';
  static const String providerName = 'Cloudflare';
  static const String providerIcon = 'assets/icons/cloudflare.svg';
  static const String baseUrl = 'https://api.cloudflare.com/client/v4';

  static Dio createClient(String apiToken) {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: DriverConstants.connectionTimeout),
      receiveTimeout: const Duration(milliseconds: DriverConstants.receiveTimeout),
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
      },
    ));
  }

  static bool isInitialized(Dio? client) => client != null;

  static String? getErrorCode(dynamic data) {
    if (data is! Map) return null;
    final errors = data['errors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      final error = errors[0] as Map?;
      return error?['code']?.toString();
    }
    return null;
  }

  static String? getErrorMessage(dynamic data) {
    if (data is! Map) return null;
    final errors = data['errors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      final error = errors[0] as Map?;
      return error?['message']?.toString();
    }
    final messages = data['messages'] as List?;
    if (messages != null && messages.isNotEmpty) {
      return (messages[0] as Map?)?['message']?.toString();
    }
    return null;
  }
}