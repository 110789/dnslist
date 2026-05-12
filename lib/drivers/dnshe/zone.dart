import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';
import 'core.dart';
import 'parser.dart';

class DnsheZone {
  final Dio _client;

  DnsheZone(this._client);

  Future<Map<String, dynamic>> getList({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    try {
      final queryParams = DnsheCore.buildQueryParams(
        module: 'domain_hub',
        endpoint: 'subdomains',
        action: 'list',
        page: page,
        perPage: pageSize,
        filters: filters,
      );

      final response = await _client.get('', queryParameters: queryParams);

      if (response.data == null) {
        return _emptyResult(page, pageSize);
      }

      final data = response.data as Map;
      if (data['success'] != true) {
        final result = DnsheParser.parseResponse(data);
        return _errorResult(result, page, pageSize);
      }

      final subdomainsList = data['subdomains'] as List? ?? [];
      final pagination = data['pagination'] ?? {'page': page, 'per_page': pageSize, 'total': subdomainsList.length};
      final subdomains = subdomainsList.map(_parseSubdomain).toList();

      return {
        'subdomains': subdomains,
        'domains': subdomains,
        'pagination': pagination,
        'success': true,
        'statusCode': 'OK',
        'total': subdomainsList.length,
        'page': page,
        'pageSize': pageSize,
      };
    } catch (e) {
      final result = DnsheParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, page, pageSize);
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> domainData) async {
    final subdomain = domainData['subdomain']?.toString().trim() ?? '';
    final rootdomain = domainData['rootdomain']?.toString().trim() ?? '';

    if (subdomain.isEmpty) {
      return _errorResult(DriverResponseParser.parseError('Subdomain cannot be empty', 'INVALID_SUBDOMAIN'), 1, 20);
    }
    if (rootdomain.isEmpty) {
      return _errorResult(DriverResponseParser.parseError('Root domain cannot be empty', 'INVALID_ROOTDOMAIN'), 1, 20);
    }

    try {
      final response = await _client.post('', queryParameters: DnsheCore.buildSubdomainParams(subdomain, rootdomain), data: {
        'subdomain': subdomain,
        'rootdomain': rootdomain,
      });

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return {
          'success': true,
          'statusCode': 'OK',
          'data': {
            'id': data['subdomain_id']?.toString() ?? '',
            'name': data['full_domain']?.toString() ?? '$subdomain.$rootdomain',
            'subdomain': subdomain,
            'rootdomain': rootdomain,
          },
          'message': data['message'] ?? 'Subdomain registered',
        };
      }

      final result = DnsheParser.parseResponse(data);
      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = DnsheParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Future<Map<String, dynamic>> delete(String domainId) async {
    if (domainId.isEmpty) {
      return _errorResult(DriverResponseParser.parseError('Invalid subdomain ID', 'INVALID_DOMAIN_ID'), 1, 20);
    }

    final subdomainId = int.tryParse(domainId);
    if (subdomainId == null || subdomainId <= 0) {
      return _errorResult(DriverResponseParser.parseError('Invalid subdomain ID', 'INVALID_DOMAIN_ID'), 1, 20);
    }

    try {
      final response = await _client.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'subdomains',
        'action': 'delete',
      }, data: {'subdomain_id': subdomainId});

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'message': data['message'] ?? 'Subdomain deleted', 'dns_records_deleted': data['dns_records_deleted'] ?? 0};
      }

      final result = DnsheParser.parseResponse(data);
      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = DnsheParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Future<Map<String, dynamic>> renew(String domainId) async {
    if (domainId.isEmpty) {
      return _errorResult(DriverResponseParser.parseError('Invalid subdomain ID', 'INVALID_DOMAIN_ID'), 1, 20);
    }

    final subdomainId = int.tryParse(domainId);
    if (subdomainId == null || subdomainId <= 0) {
      return _errorResult(DriverResponseParser.parseError('Invalid subdomain ID', 'INVALID_DOMAIN_ID'), 1, 20);
    }

    try {
      final response = await _client.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'subdomains',
        'action': 'renew',
      }, data: {'subdomain_id': subdomainId});

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return {
          'success': true,
          'statusCode': 'OK',
          'data': {
            'subdomain_id': data['subdomain_id'],
            'remaining_days': data['remaining_days'] ?? 365,
            'new_expires_at': data['new_expires_at'],
            'charged_amount': data['charged_amount'] ?? 0,
          },
          'message': data['message'] ?? 'Subdomain renewed',
        };
      }

      final result = DnsheParser.parseResponse(data);
      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = DnsheParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Map<String, dynamic> _parseSubdomain(dynamic sub) => {
    'id': sub['id']?.toString() ?? '',
    'name': sub['full_domain']?.toString() ?? sub['subdomain']?.toString() ?? '',
    'subdomain': sub['subdomain']?.toString() ?? '',
    'rootdomain': sub['rootdomain']?.toString() ?? '',
    'status': sub['status']?.toString() ?? 'active',
    'created_at': sub['created_at'],
    'updated_at': sub['updated_at'],
    'expires_at': sub['expires_at'],
  };

  Map<String, dynamic> _emptyResult(int page, int pageSize) => {
    'subdomains': [],
    'domains': [],
    'pagination': {},
    'error': '',
    'errorCode': 'EMPTY_RESPONSE',
    'success': false,
  };

  Map<String, dynamic> _errorResult(Map<String, dynamic> error, int page, int pageSize) => {
    'subdomains': [],
    'domains': [],
    'pagination': {},
    'error': error['error'],
    'errorCode': error['errorCode'],
    'success': false,
  };
}