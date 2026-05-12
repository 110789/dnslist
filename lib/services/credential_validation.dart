import '../drivers/driver_factory.dart';

class CredentialValidationService {
  static Future<Map<String, dynamic>> validateCredential(
    String providerId,
    Map<String, String> credentials,
  ) async {
    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        return {
          'success': false,
          'error': 'Provider not found: $providerId',
          'errorCode': 'PROVIDER_NOT_FOUND',
          'statusCode': 404,
        };
      }

      final result = await driver.validateCredential(credentials);
      return result;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'errorCode': 'EXCEPTION',
        'statusCode': 500,
      };
    }
  }
}