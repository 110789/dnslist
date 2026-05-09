import 'package:flutter/material.dart';
import '../interfaces/driver_interface.dart';
import '../../utils/network/api_client.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/design_system.dart';

class DnsheDriver implements DriverInterface {
  static const String _providerId = 'dnshe';
  static const String _providerName = 'DNSHE';
  static const String _providerIcon = 'assets/icons/dnshe.jpg';

  static const Map<String, String> _errorCodeMap = {
    'auth_invalid_credentials': 'API 密钥或密钥 Secret 错误',
    'auth_ip_not_allowed': 'IP 地址未授权',
    'api_access_disabled': 'API 访问已被禁用',
    'not_found': '资源不存在',
    'subdomain_not_found': '子域名不存在',
    'dns_record_not_found': 'DNS 记录不存在',
    'quota_exceeded': '配额已超出限制',
    'rate_limit_exceeded': '请求频率超限，请稍后重试',
    'provider_operation_failed': '服务商操作失败',
    'internal_error': '服务器内部错误',
    'no_renew_config': '续期未配置',
    'not_in_renew_window': '不在续期窗口期内',
    'redemption_manual': '需要人工处理',
    'renew_grace_expired': '宽限期已过期',
    'redemption_balance_insufficient': '余额不足',
    'bad_request': '请求参数无效',
  };

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
  String mapErrorCode(String code) {
    return _errorCodeMap[code] ?? 'DNSHE 错误: $code';
  }

  @override
  String getAddDomainTitle() => '添加子域名';

  @override
  Map<String, dynamic> prepareDomainData(Map<String, dynamic> input) {
    return {
      'subdomain': input['subdomain'] ?? '',
      'rootdomain': input['rootdomain'] ?? '',
    };
  }

  Map<String, dynamic> _parseError(dynamic responseData) {
    if (responseData == null) {
      return {'error': '未知错误', 'errorCode': 'UNKNOWN', 'success': false};
    }
    final data = responseData is Map ? responseData : {};
    final errorCode = data['error_code'] ?? data['error']?.toString() ?? 'UNKNOWN';
    final message = _errorCodeMap[errorCode] ?? data['message'] ?? data['error'] ?? '操作失败';
    return {'error': message, 'errorCode': errorCode, 'success': false};
  }

  @override
  Future<bool> validateCredential(Map<String, String> credentials) async {
    final apiKey = credentials['apiKey'];
    final apiSecret = credentials['apiSecret'];
    if (apiKey == null || apiKey.isEmpty || apiSecret == null || apiSecret.isEmpty) return false;
    try {
      _apiKey = apiKey;
      _apiSecret = apiSecret;
      _client = ApiClient(
        baseUrl: AppConfig.dnsheBaseUrl,
        headers: {'X-API-Key': apiKey, 'X-API-Secret': apiSecret},
      );
      final response = await _client!.get('', queryParameters: {'m': 'domain_hub', 'endpoint': 'quota'});
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
      return {'subdomains': [], 'pagination': {}, 'error': 'Not authenticated', 'errorCode': 'AUTH_REQUIRED'};
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
        return {'subdomains': subdomains, 'pagination': pagination, 'success': true, 'statusCode': 'OK', 'domains': subdomains};
      }
      return _parseError(response.data);
    } catch (e) {
      return {'subdomains': [], 'pagination': {}, 'error': e.toString(), 'errorCode': 'NETWORK_ERROR'};
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
        return {'records': records, 'pagination': {}, 'success': true, 'statusCode': 'OK'};
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
      final response = await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'create',
      }, data: {
        'subdomain_id': int.tryParse(domainId) ?? domainId,
        ...recordData,
      });
      if (response.data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'data': response.data};
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
      final response = await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'update',
      }, data: {
        'id': int.tryParse(recordId) ?? recordId,
        ...recordData,
      });
      if (response.data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'data': response.data};
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
      await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'delete',
      }, data: {'id': int.tryParse(recordId) ?? recordId});
    } catch (e) {}
  }

  @override
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData) async {
    if (_client == null) return {'error': 'Not authenticated', 'errorCode': 'AUTH_REQUIRED'};
    try {
      final response = await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'subdomains',
        'action': 'register',
      }, data: domainData);
      if (response.data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'data': response.data};
      }
      return _parseError(response.data);
    } catch (e) {
      return {'error': e.toString(), 'errorCode': 'NETWORK_ERROR'};
    }
  }

  @override
  Future<Map<String, dynamic>> deleteDomain(String domainId) async {
    if (_client == null) {
      return {'error': '未初始化认证', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    try {
      final response = await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'subdomains',
        'action': 'delete',
      }, data: {'subdomain_id': int.tryParse(domainId) ?? domainId});
      if (response.data['success'] == true) {
        return {'success': true, 'statusCode': 'OK'};
      }
      return _parseError(response.data);
    } catch (e) {
      return {'error': e.toString(), 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> renewDomain(String domainId) async {
    if (_client == null) return {'error': 'Not authenticated', 'errorCode': 'AUTH_REQUIRED'};
    try {
      final response = await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'subdomains',
        'action': 'renew',
      }, data: {'subdomain_id': int.tryParse(domainId) ?? domainId});
      if (response.data['success'] == true) {
        return {
          'success': true,
          'statusCode': 'OK',
          'data': response.data,
          'remaining_days': response.data['remaining_days'],
          'message': response.data['message'],
        };
      }
      return _parseError(response.data);
    } catch (e) {
      return {'error': e.toString(), 'errorCode': 'NETWORK_ERROR'};
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
    final name = domainData['name']?.toString() ?? '';
    final status = domainData['status']?.toString() ?? '';
    final createdAt = domainData['created_at'];
    final colorScheme = DnsDesignTokens.statusActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: colorScheme.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.language, color: DnsDesignTokens.dnsTypeCNAME, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(_formatDate(createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          _StatusBadge(status: _translateStatus(status)),
        ],
      ),
    );
  }

  @override
  Widget buildDnsRecordListItem(Map<String, dynamic> recordData) {
    final name = recordData['name']?.toString() ?? '';
    final type = recordData['type']?.toString() ?? 'A';
    final content = recordData['content']?.toString() ?? '';
    final ttl = recordData['ttl'] as int? ?? 3600;
    final proxied = recordData['proxied'] == true;
    final priority = recordData['priority'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: DnsDesignTokens.getDnsTypeColor(type),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: type.length <= 2 ? 14 : 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (priority != null) ...[
                      const SizedBox(width: 4),
                      Text('P$priority', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DnsDesignTokens.dnsTypeMX)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(content, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _TtlTag(ttl: ttl),
          if (proxied) ...[
            const SizedBox(width: 4),
            const Icon(Icons.cloud, size: 16, color: DnsDesignTokens.dnsTypeA),
          ],
        ],
      ),
    );
  }

  @override
  Map<String, String> getCredentialFields() {
    return {'apiKey': 'API Key', 'apiSecret': 'API Secret'};
  }

  @override
  List<String> getSupportedRecordTypes() {
    return ['A', 'AAAA', 'CNAME', 'MX', 'TXT'];
  }

  String _translateStatus(String status) {
    const map = {'active': '活跃', 'pending': '待处理', 'expired': '已过期', 'suspended': '已暂停', 'deleted': '已删除'};
    return map[status.toLowerCase()] ?? status;
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '';
    try {
      final s = dateVal is int ? dateVal.toString() : dateVal.toString();
      if (s.isEmpty) return '';
      if (dateVal is int && dateVal > 10000000000) {
        final dt = DateTime.fromMillisecondsSinceEpoch(dateVal, isUtc: true);
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
      final dt = DateTime.tryParse(s);
      if (dt != null) return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      return s;
    } catch (_) { return ''; }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = DnsDesignTokens.getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _TtlTag extends StatelessWidget {
  final int ttl;
  const _TtlTag({required this.ttl});
  String get _label {
    if (ttl <= 0) return 'TTL: $ttl';
    if (ttl < 60) return 'TTL: ${ttl}s';
    if (ttl < 3600) return 'TTL: ${(ttl / 60).round()}m';
    if (ttl < 86400) return 'TTL: ${(ttl / 3600).round()}h';
    return 'TTL: ${(ttl / 86400).round()}d';
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(_label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey)),
    );
  }
}