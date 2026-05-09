import 'package:flutter/widgets.dart';

import '../interfaces/driver_interface.dart';
import '../../utils/network/api_client.dart';
import '../../core/config/app_config.dart';

class CloudflareDriver implements DriverInterface {
  static const String _providerId = 'cloudflare';
  static const String _providerName = 'Cloudflare';
  static const String _providerIcon = 'cloud';

  static final Map<String, String> _errorCodeMap = {
    '1000': '认证失败，请检查 API Token 是否正确',
    '1001': '资源不存在',
    '1002': '请求参数验证失败',
    '1003': '操作失败，请稍后重试',
    '1004': '请求频率超限，请稍后重试',
    '1005': '资源已存在',
    '7000': '区域不存在',
    '7001': '区域已存在',
    '7003': '区域不可用',
    '9100': '权限不足，缺少必要权限',
    '9101': '权限不足，无法访问此资源',
    '9109': '未授权访问请求的资源',
    '10200': '账户问题导致操作被阻止',
  };

  ApiClient? _client;

  @override
  String get providerId => _providerId;

  @override
  String get providerName => _providerName;

  @override
  String get providerIcon => _providerIcon;

  Map<String, dynamic> _parseError(dynamic responseData) {
    if (responseData == null) {
      return {'error': '未知错误', 'errorCode': 'UNKNOWN', 'success': false};
    }
    
    final data = responseData is Map ? responseData : {};
    final errors = data['errors'] as List?;
    
    if (errors != null && errors.isNotEmpty) {
      final error = errors[0] as Map?;
      final code = error?['code']?.toString() ?? 'UNKNOWN';
      final message = _errorCodeMap[code] ?? error?['message'] ?? '操作失败';
      return {
        'error': message,
        'errorCode': code,
        'success': false,
      };
    }
    
    return {'error': '未知错误', 'errorCode': 'UNKNOWN', 'success': false};
  }

  @override
  Future<bool> validateCredential(Map<String, String> credentials) async {
    final apiToken = credentials['apiToken'];
    if (apiToken == null || apiToken.isEmpty) {
      return false;
    }

    try {
      _client = ApiClient(
        baseUrl: AppConfig.cloudflareBaseUrl,
        headers: {
          'Authorization': 'Bearer $apiToken',
        },
      );

      final response = await _client!.get('/user/tokens/verify');
      if (response.data['success'] == true) {
        return true;
      }
      
      final errorResult = _parseError(response.data);
      return false;
    } catch (e) {
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
      return {'domains': [], 'pagination': {}, 'error': 'Not authenticated', 'errorCode': 'AUTH_REQUIRED'};
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
        return {'domains': domains, 'pagination': pagination, 'success': true, 'statusCode': 'OK'};
      }
      
      return _parseError(response.data);
    } catch (e) {
      return {'domains': [], 'pagination': {}, 'error': e.toString(), 'errorCode': 'NETWORK_ERROR'};
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
      return {'records': [], 'pagination': {}, 'error': 'Not authenticated', 'errorCode': 'AUTH_REQUIRED'};
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
        return {'records': records, 'pagination': pagination, 'success': true, 'statusCode': 'OK'};
      }
      
      return _parseError(response.data);
    } catch (e) {
      return {'records': [], 'pagination': {}, 'error': e.toString(), 'errorCode': 'NETWORK_ERROR'};
    }
  }

  @override
  Future<Map<String, dynamic>> createDnsRecord(
    String domainId,
    Map<String, dynamic> recordData,
  ) async {
    if (_client == null) return {'error': 'Not authenticated', 'errorCode': 'AUTH_REQUIRED'};

    try {
      final response = await _client!.post('/zones/$domainId/dns_records', data: recordData);
      if (response.data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'data': response.data['result']};
      }
      return _parseError(response.data);
    } catch (e) {
      return {'error': e.toString(), 'errorCode': 'NETWORK_ERROR'};
    }
  }

  @override
  Future<Map<String, dynamic>> updateDnsRecord(
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
  ) async {
    if (_client == null) return {'error': 'Not authenticated', 'errorCode': 'AUTH_REQUIRED'};

    try {
      final response = await _client!.put('/zones/$domainId/dns_records/$recordId', data: recordData);
      if (response.data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'data': response.data['result']};
      }
      return _parseError(response.data);
    } catch (e) {
      return {'error': e.toString(), 'errorCode': 'NETWORK_ERROR'};
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
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData) async {
    if (_client == null) return {'error': 'Not authenticated', 'errorCode': 'AUTH_REQUIRED'};

    try {
      final response = await _client!.post('/zones', data: domainData);
      if (response.data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'data': response.data['result']};
      }
      return _parseError(response.data);
    } catch (e) {
      return {'error': e.toString(), 'errorCode': 'NETWORK_ERROR'};
    }
  }

  @override
  Future<void> deleteDomain(String domainId) async {
    if (_client == null) return;

    try {
      await _client!.delete('/zones/$domainId');
    } catch (e) {
      // ignore
    }
  }

  @override
  Future<Map<String, dynamic>> renewDomain(String domainId) async {
    return {'error': 'Cloudflare domains are managed via account subscription, not API renewal', 'errorCode': 'NOT_SUPPORTED'};
  }

  @override
  bool get supportsAddDomain => true;

  @override
  bool get supportsDeleteDomain => true;

  @override
  bool get supportsRenewDomain => false;

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