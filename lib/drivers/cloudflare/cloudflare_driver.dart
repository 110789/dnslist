import 'package:flutter/material.dart';
import '../interfaces/driver_interface.dart';
import '../../utils/network/api_client.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/design_system.dart';

class CloudflareDriver implements DriverInterface {
  static const String _providerId = 'cloudflare';
  static const String _providerName = 'Cloudflare';
  static const String _providerIcon = 'assets/icons/cloudflare.svg';

  static const Map<String, String> _errorCodeMap = {
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

  @override
  String mapErrorCode(String code) {
    return _errorCodeMap[code] ?? 'Cloudflare 错误: $code';
  }

  @override
  String getAddDomainTitle() => '添加域名';

  @override
  Map<String, dynamic> prepareDomainData(Map<String, dynamic> input) {
    return {
      'name': input['name'] ?? input['rootdomain'] ?? '',
      'type': 'full',
    };
  }

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
      return {'error': message, 'errorCode': code, 'success': false};
    }
    return {'error': '未知错误', 'errorCode': 'UNKNOWN', 'success': false};
  }

  @override
  Future<bool> validateCredential(Map<String, String> credentials) async {
    final apiToken = credentials['apiToken'];
    if (apiToken == null || apiToken.isEmpty) return false;
    try {
      _client = ApiClient(
        baseUrl: AppConfig.cloudflareBaseUrl,
        headers: {'Authorization': 'Bearer $apiToken'},
      );
      final response = await _client!.get('/user/tokens/verify');
      if (response.data['success'] == true) return true;
      _parseError(response.data);
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
    } catch (e) {}
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
  Future<Map<String, dynamic>> deleteDomain(String domainId) async {
    if (_client == null) {
      return {'error': '未初始化认证', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    try {
      final response = await _client!.delete('/zones/$domainId');
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
    return {'error': 'Cloudflare domains are managed via account subscription, not API renewal', 'errorCode': 'NOT_SUPPORTED'};
  }

  @override
  bool get supportsAddDomain => true;

  @override
  bool get supportsDeleteDomain => true;

  @override
  bool get supportsRenewDomain => false;

  @override
  Widget buildDomainListItem(Map<String, dynamic> domainData, {
    required VoidCallback onTap,
    required VoidCallback onDelete,
    required VoidCallback onRenew,
    required bool supportsDelete,
    required bool supportsRenew,
  }) {
    return const SizedBox.shrink();
  }

  @override
  void showDomainListItemMenu(BuildContext context, Map<String, dynamic> domainData, {
    required VoidCallback onDelete,
    required VoidCallback onRenew,
    required bool supportsDelete,
    required bool supportsRenew,
  }) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(offset.dx + renderBox.size.width / 2, offset.dy + renderBox.size.height / 2, offset.dx + renderBox.size.width, offset.dy + renderBox.size.height),
      items: [
        if (supportsRenew) const PopupMenuItem(value: 'renew', child: Text('续期')),
        if (supportsDelete) PopupMenuItem(value: 'delete', child: const Text('删除', style: TextStyle(color: Color(0xFFEF4444)))),
      ],
    ).then((value) {
      if (value == 'delete') onDelete();
      if (value == 'renew') onRenew();
    });
  }

  @override
  Widget buildDnsRecordListItem(Map<String, dynamic> recordData) {
    final name = recordData['name']?.toString() ?? '';
    final type = recordData['type']?.toString() ?? 'A';
    final content = recordData['content']?.toString() ?? '';
    final ttl = recordData['ttl'] as int? ?? 3600;
    final proxied = recordData['proxied'] == true;

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
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
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
    return {'apiToken': 'API Token'};
  }

  @override
  List<String> getSupportedRecordTypes() {
    return ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SRV', 'CAA'];
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