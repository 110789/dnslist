import 'package:flutter/widgets.dart';

import '../interfaces/driver_interface.dart';
import '../../utils/network/api_client.dart';
import '../../core/config/app_config.dart';

class CloudflareDriver implements DriverInterface {
  static const String _providerId = 'cloudflare';
  static const String _providerName = 'Cloudflare';
  static const String _providerIcon = 'cloud';

  String? _apiToken;
  ApiClient? _client;

  @override
  String get providerId => _providerId;

  @override
  String get providerName => _providerName;

  @override
  String get providerIcon => _providerIcon;

  @override
  Future<bool> validateCredential(Map<String, String> credentials) async {
    final apiToken = credentials['apiToken'];
    if (apiToken == null || apiToken.isEmpty) {
      return false;
    }

    try {
      _apiToken = apiToken;
      _client = ApiClient(
        baseUrl: AppConfig.cloudflareBaseUrl,
        headers: {'Authorization': 'Bearer $apiToken'},
      );

      final response = await _client!.get('/user');
      return response.data['success'] == true;
    } catch (e) {
      _apiToken = null;
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
      return {'domains': [], 'pagination': {}};
    }

    try {
      final response = await _client!.get('/zones', queryParameters: {
        'page': page,
        'per_page': pageSize,
        if (filters != null) ...filters,
      });

      if (response.data['success'] == true) {
        final domains = (response.data['result'] as List).map((zone) => {
          'id': zone['id'],
          'name': zone['name'],
          'status': zone['status'],
          'type': zone['type'],
          'paused': zone['paused'],
          'created_on': zone['created_on'],
          'modified_on': zone['modified_on'],
        }).toList();

        final pagination = response.data['result_info'] ?? {};
        return {'domains': domains, 'pagination': pagination};
      }
      return {'domains': [], 'pagination': {}};
    } catch (e) {
      return {'domains': [], 'pagination': {}, 'error': e.toString()};
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
      final response = await _client!.get('/zones/$domainId/dns_records', queryParameters: {
        'page': page,
        'per_page': pageSize,
        if (filters != null) ...filters,
      });

      if (response.data['success'] == true) {
        final records = (response.data['result'] as List).map((record) => {
          'id': record['id'],
          'name': record['name'],
          'type': record['type'],
          'content': record['content'],
          'ttl': record['ttl'],
          'proxied': record['proxied'],
          'created_on': record['created_on'],
          'modified_on': record['modified_on'],
        }).toList();

        final pagination = response.data['result_info'] ?? {};
        return {'records': records, 'pagination': pagination};
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
      final response = await _client!.post('/zones/$domainId/dns_records', data: recordData);
      if (response.data['success'] == true) {
        return response.data['result'];
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
      final response = await _client!.put('/zones/$domainId/dns_records/$recordId', data: recordData);
      if (response.data['success'] == true) {
        return response.data['result'];
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
      await _client!.delete('/zones/$domainId/dns_records/$recordId');
    } catch (e) {
      // ignore
    }
  }

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
      'apiToken': 'API Token',
    };
  }

  @override
  List<String> getSupportedRecordTypes() {
    return ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SRV', 'CAA'];
  }
}