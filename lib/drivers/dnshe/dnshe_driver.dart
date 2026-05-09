import 'package:flutter/widgets.dart';

import '../interfaces/driver_interface.dart';
import '../../utils/network/api_client.dart';
import '../../core/config/app_config.dart';

class DnsheDriver implements DriverInterface {
  static const String _providerId = 'dnshe';
  static const String _providerName = 'DNSHE';
  static const String _providerIcon = 'dns';

  String? _apiKey;
  String? _apiSecret;
  ApiClient? _client;

  @override
  String get providerId => _providerId;

  @override
  String get providerName => _providerName;

  @override
  String get providerIcon => _providerIcon;

  @override
  Future<bool> validateCredential(Map<String, String> credentials) async {
    final apiKey = credentials['apiKey'];
    final apiSecret = credentials['apiSecret'];
    if (apiKey == null || apiKey.isEmpty || apiSecret == null || apiSecret.isEmpty) {
      return false;
    }

    try {
      _apiKey = apiKey;
      _apiSecret = apiSecret;
      _client = ApiClient(
        baseUrl: AppConfig.dnsheBaseUrl,
        headers: {
          'X-API-Key': apiKey,
          'X-API-Secret': apiSecret,
        },
      );

      final response = await _client!.get('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'quota',
      });

      return response.data['success'] == true;
    } catch (e) {
      _apiKey = null;
      _apiSecret = null;
      _client = null;
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getDomains({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    if (_client == null) {
      return {'subdomains': [], 'pagination': {}};
    }

    try {
      final response = await _client!.get('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'subdomains',
        'action': 'list',
        'page': page,
        'per_page': pageSize,
        if (filters != null) ...filters,
      });

      if (response.data['success'] == true) {
        final subdomains = (response.data['subdomains'] as List).map((sub) => {
          'id': sub['id'].toString(),
          'name': sub['full_domain'],
          'subdomain': sub['subdomain'],
          'rootdomain': sub['rootdomain'],
          'status': sub['status'],
          'created_at': sub['created_at'],
          'updated_at': sub['updated_at'],
        }).toList();

        final pagination = response.data['pagination'] ?? {};
        return {'subdomains': subdomains, 'pagination': pagination, 'domains': subdomains};
      }
      return {'subdomains': [], 'pagination': {}};
    } catch (e) {
      return {'subdomains': [], 'pagination': {}, 'error': e.toString()};
    }
  }

  @override
  Future<Map<String, dynamic>> getDnsRecords(
    String domainId, {
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    if (_client == null) {
      return {'records': [], 'pagination': {}};
    }

    try {
      final response = await _client!.get('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'list',
        'subdomain_id': domainId,
      });

      if (response.data['success'] == true) {
        final records = (response.data['records'] as List).map((record) => {
          'id': record['id'].toString(),
          'record_id': record['record_id'],
          'name': record['name'],
          'type': record['type'],
          'content': record['content'],
          'ttl': record['ttl'],
          'priority': record['priority'],
          'proxied': record['proxied'],
          'status': record['status'],
          'created_at': record['created_at'],
          'updated_at': record['updated_at'],
        }).toList();

        return {'records': records, 'pagination': {}};
      }
      return {'records': [], 'pagination': {}};
    } catch (e) {
      return {'records': [], 'pagination': {}, 'error': e.toString()};
    }
  }

  @override
  Future<Map<String, dynamic>> createDnsRecord(
    String domainId,
    Map<String, dynamic> recordData,
  ) async {
    if (_client == null) return {};

    try {
      final response = await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'create',
      }, data: {
        'subdomain_id': int.tryParse(domainId) ?? domainId,
        ...recordData,
      });

      if (response.data['success'] == true) {
        return response.data;
      }
      return {};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  @override
  Future<Map<String, dynamic>> updateDnsRecord(
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
  ) async {
    if (_client == null) return {};

    try {
      final response = await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'update',
      }, data: {
        'id': int.tryParse(recordId) ?? recordId,
        ...recordData,
      });

      if (response.data['success'] == true) {
        return response.data;
      }
      return {};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  @override
  Future<void> deleteDnsRecord(String domainId, String recordId) async {
    if (_client == null) return;

    try {
      await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'delete',
      }, data: {
        'id': int.tryParse(recordId) ?? recordId,
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData) async {
    if (_client == null) return {'error': 'Not authenticated'};

    try {
      final response = await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'subdomains',
        'action': 'register',
      }, data: domainData);

      if (response.data['success'] == true) {
        return response.data;
      }
      return {'error': response.data['message'] ?? 'Failed to create domain'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  @override
  Future<void> deleteDomain(String domainId) async {
    if (_client == null) return;

    try {
      await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'subdomains',
        'action': 'delete',
      }, data: {
        'subdomain_id': int.tryParse(domainId) ?? domainId,
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  Future<Map<String, dynamic>> renewDomain(String domainId) async {
    if (_client == null) return {'error': 'Not authenticated'};

    try {
      final response = await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'subdomains',
        'action': 'renew',
      }, data: {
        'subdomain_id': int.tryParse(domainId) ?? domainId,
      });

      if (response.data['success'] == true) {
        return response.data;
      }
      return {'error': response.data['message'] ?? 'Failed to renew domain'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  @override
  bool get supportsAddDomain => true;

  @override
  bool get supportsDeleteDomain => true;

  @override
  bool get supportsRenewDomain => true;

  @override
  Widget buildDomainListItem(Map<String, dynamic> domainData) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildDnsRecordListItem(Map<String, dynamic> recordData) {
    return const SizedBox.shrink();
  }

  @override
  Map<String, String> getCredentialFields() {
    return {
      'apiKey': 'API Key',
      'apiSecret': 'API Secret',
    };
  }

  @override
  List<String> getSupportedRecordTypes() {
    return ['A', 'AAAA', 'CNAME', 'MX', 'TXT'];
  }
}