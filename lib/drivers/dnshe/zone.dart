import 'package:dio/dio.dart';
import 'core.dart';
import 'parser.dart';

class DnsheZone {
  final Dio _client;

  DnsheZone(this._client);

  Future<Map<String, dynamic>> getList({
    int page = 1,
    int pageSize = 100,
    Map<String, String>? filters,
  }) async {
    try {
      final queryParams = DnsheCore.buildSubdomainListParams(
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
      final result = DnsheParser.parseResponse(data);

      if (result['success'] != true) {
        return _errorResult(result);
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
        'count': subdomainsList.length,
      };
    } on DioException catch (e) {
      final result = DnsheParser.parseException(e);
      return _errorResult(result);
    } catch (e) {
      return _errorResult(DnsheParser.parseUnknown(e.toString()));
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> domainData) async {
    final subdomain = domainData['subdomain']?.toString().trim() ?? '';
    final rootdomain = domainData['rootdomain']?.toString().trim() ?? '';

    if (subdomain.isEmpty) {
      return _errorResult(DnsheParser.parseError('Subdomain cannot be empty', 'INVALID_SUBDOMAIN'));
    }
    if (rootdomain.isEmpty) {
      return _errorResult(DnsheParser.parseError('Root domain cannot be empty', 'INVALID_ROOTDOMAIN'));
    }

    try {
      final body = DnsheCore.buildSubdomainCreateBody(
        subdomain: subdomain,
        rootdomain: rootdomain,
      );

      final response = await _client.post(
        '',
        queryParameters: {
          'm': 'domain_hub',
          'endpoint': 'subdomains',
          'action': 'register',
        },
        data: body,
      );

      if (response.data == null) {
        return _errorResult(DnsheParser.parseEmpty());
      }

      final data = response.data as Map;
      final result = DnsheParser.parseResponse(data);

      if (result['success'] != true) {
        return _errorResult(result);
      }

      return {
        'success': true,
        'statusCode': 'OK',
        'data': {
          'id': data['subdomain_id']?.toString() ?? '',
          'name': data['full_domain']?.toString() ?? '$subdomain.$rootdomain',
          'subdomain': subdomain,
          'rootdomain': rootdomain,
        },
        'message': data['message'] ?? 'Subdomain registered successfully',
      };
    } on DioException catch (e) {
      final result = DnsheParser.parseException(e);
      return _errorResult(result);
    } catch (e) {
      return _errorResult(DnsheParser.parseUnknown(e.toString()));
    }
  }

  Future<Map<String, dynamic>> delete(String domainId) async {
    if (domainId.isEmpty) {
      return _errorResult(DnsheParser.parseError('Invalid subdomain ID', 'INVALID_DOMAIN_ID'));
    }

    final subdomainId = int.tryParse(domainId);
    if (subdomainId == null || subdomainId <= 0) {
      return _errorResult(DnsheParser.parseError('Invalid subdomain ID', 'INVALID_DOMAIN_ID'));
    }

    try {
      final body = DnsheCore.buildSubdomainDeleteBody(subdomainId);

      final response = await _client.post(
        '',
        queryParameters: {
          'm': 'domain_hub',
          'endpoint': 'subdomains',
          'action': 'delete',
        },
        data: body,
      );

      if (response.data == null) {
        return _errorResult(DnsheParser.parseEmpty());
      }

      final data = response.data as Map;
      final result = DnsheParser.parseResponse(data);

      if (result['success'] != true) {
        return _errorResult(result);
      }

      return {
        'success': true,
        'statusCode': 'OK',
        'message': data['message'] ?? 'Subdomain deleted successfully',
        'dns_records_deleted': data['dns_records_deleted'] ?? 0,
      };
    } on DioException catch (e) {
      final result = DnsheParser.parseException(e);
      return _errorResult(result);
    } catch (e) {
      return _errorResult(DnsheParser.parseUnknown(e.toString()));
    }
  }

  Future<Map<String, dynamic>> renew(String domainId) async {
    if (domainId.isEmpty) {
      return _errorResult(DnsheParser.parseError('Invalid subdomain ID', 'INVALID_DOMAIN_ID'));
    }

    final subdomainId = int.tryParse(domainId);
    if (subdomainId == null || subdomainId <= 0) {
      return _errorResult(DnsheParser.parseError('Invalid subdomain ID', 'INVALID_DOMAIN_ID'));
    }

    try {
      final body = DnsheCore.buildSubdomainRenewBody(subdomainId);

      final response = await _client.post(
        '',
        queryParameters: {
          'm': 'domain_hub',
          'endpoint': 'subdomains',
          'action': 'renew',
        },
        data: body,
      );

      if (response.data == null) {
        return _errorResult(DnsheParser.parseEmpty());
      }

      final data = response.data as Map;
      final result = DnsheParser.parseResponse(data);

      if (result['success'] != true) {
        return _errorResult(result);
      }

      return {
        'success': true,
        'statusCode': 'OK',
        'data': {
          'subdomain_id': data['subdomain_id'],
          'remaining_days': data['remaining_days'] ?? 365,
          'new_expires_at': data['new_expires_at'],
          'charged_amount': data['charged_amount'] ?? 0,
        },
        'message': data['message'] ?? 'Subdomain renewed successfully',
      };
    } on DioException catch (e) {
      final result = DnsheParser.parseException(e);
      return _errorResult(result);
    } catch (e) {
      return _errorResult(DnsheParser.parseUnknown(e.toString()));
    }
  }

  Map<String, dynamic> _parseSubdomain(dynamic sub) {
    return {
      'id': sub['id']?.toString() ?? '',
      'name': sub['full_domain']?.toString() ?? sub['subdomain']?.toString() ?? '',
      'subdomain': sub['subdomain']?.toString() ?? '',
      'rootdomain': sub['rootdomain']?.toString() ?? '',
      'status': sub['status']?.toString() ?? 'active',
      'created_at': sub['created_at'],
      'updated_at': sub['updated_at'],
      'expires_at': sub['expires_at'],
    };
  }

  Map<String, dynamic> _emptyResult(int page, int pageSize) {
    return {
      'subdomains': <Map<String, dynamic>>[],
      'domains': <Map<String, dynamic>>[],
      'pagination': <String, dynamic>{},
      'error': 'Empty response',
      'errorCode': 'EMPTY_RESPONSE',
      'success': false,
    };
  }

  Map<String, dynamic> _errorResult(Map<String, dynamic> error) {
    return {
      'subdomains': <Map<String, dynamic>>[],
      'domains': <Map<String, dynamic>>[],
      'pagination': <String, dynamic>{},
      'error': error['error'] ?? 'Unknown error',
      'errorCode': error['errorCode'] ?? 'UNKNOWN',
      'success': false,
    };
  }
}