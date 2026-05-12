import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';

class DnsheCore {
  static const String providerId = 'dnshe';
  static const String providerName = 'DNSHE';
  static const String providerIcon = 'assets/icons/dnshe.jpg';
  static const String baseUrl = 'https://api005.dnshe.com/index.php';

  static Dio createClient(String apiKey, String apiSecret) {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: DriverConstants.connectionTimeout),
      receiveTimeout: const Duration(milliseconds: DriverConstants.receiveTimeout),
      headers: {
        'X-API-Key': apiKey,
        'X-API-Secret': apiSecret,
        'Content-Type': 'application/json',
      },
    ));
  }

  static Map<String, dynamic> buildQueryParams({
    required String module,
    required String endpoint,
    String? action,
    int? page,
    int? perPage,
    Map<String, String>? filters,
  }) {
    final params = <String, dynamic>{'m': module, 'endpoint': endpoint};
    if (action != null) params['action'] = action;
    if (page != null) params['page'] = page;
    if (perPage != null) params['per_page'] = perPage;
    if (filters != null) {
      if (filters.containsKey('name')) params['search'] = filters['name'];
      if (filters.containsKey('rootdomain')) params['rootdomain'] = filters['rootdomain'];
      if (filters.containsKey('status')) params['status'] = filters['status'];
    }
    return params;
  }

  static Map<String, dynamic> buildSubdomainParams(String subdomain, String rootdomain) => {
    'm': 'domain_hub',
    'endpoint': 'subdomains',
    'action': 'register',
  };
}