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

      final valid = await driver.validateCredential(credentials);

      if (valid) {
        return {
          'success': true,
          'statusCode': 'OK',
        };
      } else {
        return {
          'success': false,
          'error': driver.mapErrorCode('AUTH_FAILED'),
          'errorCode': 'AUTH_FAILED',
          'statusCode': 401,
        };
      }
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