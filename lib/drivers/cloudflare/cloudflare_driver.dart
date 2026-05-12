import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../interfaces/driver_interface.dart';
import '../driver_colors.dart';
import '../../utils/network/api_client.dart';
import '../../core/config/app_config.dart';

class CloudflareDriver implements DriverInterface {
  static const String _providerId = 'cloudflare';
  static const String _providerName = 'Cloudflare';
  static const String _providerIcon = 'assets/icons/cloudflare.svg';
  static const String _genericErrorMessage = '操作失败请稍后尝试';

  ApiClient? _client;
  String? _apiToken;

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
    '7004': '区域正在删除中',
    '7005': '无法删除区域，域名可能仍在使用中',
    '7006': '域名已暂停，请先恢复后再试',
    '9100': '权限不足，缺少必要权限',
    '9101': '权限不足，无法访问此资源',
    '9109': '未授权访问请求的资源',
    '9200': '账户被暂停',
    '9203': '账户余额不足',
    '9204': '账户存在未完成订单',
    '9206': '账户已被冻结',
    '10000': 'DNS 记录已存在',
    '10001': 'DNS 记录不存在',
    '10002': 'DNS 记录类型不匹配',
    '10003': 'CNAME 记录冲突，A/AAAA 记录无法与 CNAME 共存',
    '10004': 'NS 记录不能与其他记录类型共存',
    '10005': '记录名称格式不正确',
    '10006': '记录内容格式不正确',
    '10200': '账户问题导致操作被阻止',
    '10201': '此操作需要付费升级后才能使用',
    '10202': '域名已被其他账户认领',
    '20000': '分页参数超出范围',
    '20001': '每页数量超出限制',
  };

  @override
  String get providerId => _providerId;

  @override
  String get providerName => _providerName;

  @override
  String get providerIcon => _providerIcon;

  @override
  String mapErrorCode(String code) {
    return _errorCodeMap[code] ?? _genericErrorMessage;
  }

  String _truncateMessage(String message, {int maxLength = 50}) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength)}...';
  }

  @override
  String getAddDomainTitle() => '添加域名';

  @override
  List<AddDomainField> getAddDomainFields() {
    return [
      const AddDomainField(
        key: 'name',
        label: '域名',
        hintText: '例如: example.com',
      ),
    ];
  }

  @override
  Map<String, dynamic> prepareDomainData(Map<String, dynamic> input) {
    return {
      'name': input['name'] ?? input['rootdomain'] ?? '',
      'type': 'full',
    };
  }

  Map<String, dynamic> _parseError(dynamic responseData, {String? fallbackMessage}) {
    if (responseData == null) {
      return {'error': fallbackMessage ?? _genericErrorMessage, 'errorCode': 'UNKNOWN', 'success': false};
    }
    final data = responseData is Map ? responseData : {};
    final errors = data['errors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      final error = errors[0] as Map?;
      final code = error?['code']?.toString();
      final rawMessage = error?['message']?.toString() ?? '';
      if (code != null && _errorCodeMap.containsKey(code)) {
        return {'error': _errorCodeMap[code], 'errorCode': code, 'success': false};
      }
      return {
        'error': rawMessage.isNotEmpty ? _truncateMessage(rawMessage) : (fallbackMessage ?? _genericErrorMessage),
        'errorCode': code ?? 'UNKNOWN',
        'success': false
      };
    }
    final messages = data['messages'] as List?;
    if (messages != null && messages.isNotEmpty) {
      final message = (messages[0] as Map?)?['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return {'error': _truncateMessage(message), 'errorCode': 'API_MESSAGE', 'success': false};
      }
    }
    return {'error': fallbackMessage ?? _genericErrorMessage, 'errorCode': 'UNKNOWN', 'success': false};
  }

  String _handleException(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.connectionError:
          return _genericErrorMessage;
        default:
          return _genericErrorMessage;
      }
    }
    return _genericErrorMessage;
  }

  ApiClient _getClient() {
    if (_client != null) return _client!;
    if (_apiToken == null) {
      throw StateError('Driver not initialized. Call validateCredential first.');
    }
    _client = ApiClient(
      baseUrl: AppConfig.cloudflareBaseUrl,
      headers: {'Authorization': 'Bearer $_apiToken', 'Content-Type': 'application/json'},
      connectTimeout: AppConfig.connectionTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
    );
    return _client!;
  }

  @override
  Future<bool> validateCredential(Map<String, String> credentials) async {
    final apiToken = credentials['apiToken'];
    if (apiToken == null || apiToken.isEmpty) return false;
    try {
      _apiToken = apiToken;
      _client = ApiClient(
        baseUrl: AppConfig.cloudflareBaseUrl,
        headers: {'Authorization': 'Bearer $apiToken', 'Content-Type': 'application/json'},
        connectTimeout: AppConfig.connectionTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
      );
      final response = await _client!.get('/user/tokens/verify');
      if (response.data['success'] == true) return true;
      return false;
    } catch (e) {
      _apiToken = null;
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getDomains({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    if (_apiToken == null) {
      return {'domains': [], 'pagination': {}, 'error': _genericErrorMessage, 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': pageSize,
      };
      if (filters != null) {
        queryParams.addAll(filters);
      }
      final response = await _getClient().get('/zones', queryParameters: queryParams);
      if (response.data['success'] == true) {
        final result = response.data['result'] as List? ?? [];
        final domains = result.map((zone) {
          String? registrar;
          final owner = zone['owner'];
          if (owner != null) {
            final ownerType = owner['type']?.toString();
            if (ownerType != null && ownerType.isNotEmpty) {
              registrar = _parseRegistrarType(ownerType);
            }
          }
          return {
            'id': zone['id']?.toString() ?? '',
            'name': zone['name']?.toString() ?? '',
            'status': zone['status']?.toString() ?? 'unknown',
            'type': zone['type']?.toString() ?? 'full',
            'paused': zone['paused'] ?? false,
            'created_on': zone['created_on'],
            'modified_on': zone['modified_on'],
            'name_servers': zone['name_servers'] as List? ?? [],
            'owner': zone['owner'],
            'plan': zone['plan'],
            'registrar': registrar,
          };
        }).toList();
        final pagination = response.data['result_info'] ?? {};
        return {
          'domains': domains,
          'pagination': pagination,
          'success': true,
          'statusCode': 'OK',
          'total': pagination['total_count'] ?? result.length,
          'page': page,
          'pageSize': pageSize,
        };
      }
      return _parseError(response.data);
    } catch (e) {
      return {
        'domains': [],
        'pagination': {},
        'error': _genericErrorMessage,
        'errorCode': 'NETWORK_ERROR',
        'success': false
      };
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
      return {'records': [], 'pagination': {}, 'error': _genericErrorMessage, 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': pageSize,
      };
      if (filters != null) {
        queryParams.addAll(filters);
      }
      final response = await _getClient().get('/zones/$domainId/dns_records', queryParameters: queryParams);
      if (response.data['success'] == true) {
        final result = response.data['result'] as List? ?? [];
        final records = result.map((record) {
          return {
            'id': record['id']?.toString() ?? '',
            'name': record['name']?.toString() ?? '',
            'type': record['type']?.toString() ?? 'A',
            'content': record['content']?.toString() ?? '',
            'ttl': record['ttl'] ?? 1,
            'proxied': record['proxied'] ?? false,
            'proxiable': record['proxiable'] ?? false,
            'created_on': record['created_on'],
            'modified_on': record['modified_on'],
            'comment': record['comment'],
            'tags': record['tags'] as List? ?? [],
          };
        }).toList();
        final pagination = response.data['result_info'] ?? {};
        return {
          'records': records,
          'pagination': pagination,
          'success': true,
          'statusCode': 'OK',
          'total': pagination['total_count'] ?? result.length,
          'page': page,
          'pageSize': pageSize,
        };
      }
      return _parseError(response.data);
    } catch (e) {
      return {
        'records': [],
        'pagination': {},
        'error': _genericErrorMessage,
        'errorCode': 'NETWORK_ERROR',
        'success': false
      };
    }
  }

  @override
  Future<Map<String, dynamic>> createDnsRecord(
    String domainId,
    Map<String, dynamic> recordData,
  ) async {
    if (_client == null) return {'error': _genericErrorMessage, 'errorCode': 'AUTH_REQUIRED', 'success': false};
    try {
      final preparedData = _prepareDnsRecordData(recordData);
      final response = await _getClient().post('/zones/$domainId/dns_records', data: preparedData);
      if (response.data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'data': response.data['result']};
      }
      return _parseError(response.data);
    } catch (e) {
      return {'error': _genericErrorMessage, 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> updateDnsRecord(
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
  ) async {
    if (_client == null) return {'error': _genericErrorMessage, 'errorCode': 'AUTH_REQUIRED', 'success': false};
    try {
      final preparedData = _prepareDnsRecordData(recordData);
      final response = await _getClient().put('/zones/$domainId/dns_records/$recordId', data: preparedData);
      if (response.data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'data': response.data['result']};
      }
      return _parseError(response.data);
    } catch (e) {
      return {'error': _genericErrorMessage, 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  Map<String, dynamic> _prepareDnsRecordData(Map<String, dynamic> recordData) {
    final data = Map<String, dynamic>.from(recordData);
    if (data.containsKey('priority') && (data['priority'] == null || data['priority'] == 0)) {
      data.remove('priority');
    }
    if (data.containsKey('proxied') && data['proxied'] == null) {
      data.remove('proxied');
    }
    if (data.containsKey('ttl') && (data['ttl'] == null || data['ttl'] == 0)) {
      data.remove('ttl');
    } else if (data['ttl'] == 1) {
      data['ttl'] = 1;
    }
    return data;
  }

  @override
  Future<Map<String, dynamic>> deleteDnsRecord(String domainId, String recordId) async {
    if (_client == null) {
      return {'success': false, 'error': _genericErrorMessage, 'errorCode': 'AUTH_REQUIRED'};
    }
    try {
      final response = await _getClient().delete('/zones/$domainId/dns_records/$recordId');
      if (response.data['success'] == true) {
        return {'success': true, 'statusCode': 'OK'};
      }
      return _parseError(response.data);
    } catch (e) {
      return {'error': _genericErrorMessage, 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData) async {
    if (_client == null) return {'error': _genericErrorMessage, 'errorCode': 'AUTH_REQUIRED', 'success': false};
    try {
      final preparedData = {
        'name': domainData['name']?.toString() ?? '',
        'type': domainData['type']?.toString() ?? 'full',
      };
      if (domainData.containsKey('account') && domainData['account'] != null) {
        preparedData['account'] = domainData['account'];
      }
      final response = await _getClient().post('/zones', data: preparedData);
      if (response.data['success'] == true) {
        final result = response.data['result'];
        return {
          'success': true,
          'statusCode': 'OK',
          'data': {
            'id': result['id']?.toString() ?? '',
            'name': result['name']?.toString() ?? '',
            'status': result['status']?.toString() ?? 'initializing',
            'type': result['type']?.toString() ?? 'full',
            'name_servers': result['name_servers'] as List? ?? [],
          },
          'message': '域名添加成功'
        };
      }
      return _parseError(response.data);
    } catch (e) {
      return {'error': _genericErrorMessage, 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> deleteDomain(String domainId) async {
    if (_client == null) {
      return {'error': _genericErrorMessage, 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    if (domainId.isEmpty) {
      return {'error': _genericErrorMessage, 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};
    }
    try {
      final response = await _getClient().delete('/zones/$domainId');
      if (response.data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'message': '域名已删除'};
      }
      return _parseError(response.data);
    } catch (e) {
      return {'error': _genericErrorMessage, 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> renewDomain(String domainId) async {
    return {'error': _genericErrorMessage, 'errorCode': 'NOT_SUPPORTED', 'success': false};
  }

  @override
  bool get supportsAddDomain => true;

  @override
  bool get supportsDeleteDomain => true;

  @override
  bool get supportsRenewDomain => false;

  @override
  bool get supportsShowNameServers => true;

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
    required VoidCallback onShowNameServers,
    required bool supportsDelete,
    required bool supportsRenew,
    required bool supportsShowNameServers,
  }) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(offset.dx + renderBox.size.width / 2, offset.dy + renderBox.size.height / 2, offset.dx + renderBox.size.width, offset.dy + renderBox.size.height),
      items: [
        if (supportsShowNameServers) const PopupMenuItem(value: 'nameservers', child: Text('NS节点')),
        if (supportsRenew) const PopupMenuItem(value: 'renew', child: Text('续期')),
        if (supportsDelete) PopupMenuItem(value: 'delete', child: const Text('删除', style: TextStyle(color: Color(0xFFEF4444)))),
      ],
    ).then((value) {
      if (value == 'delete') onDelete();
      if (value == 'renew') onRenew();
      if (value == 'nameservers') {
        onShowNameServers();
        _showNameServersDialog(context, domainData);
      }
    });
  }

  void _showNameServersDialog(BuildContext context, Map<String, dynamic> domainData) {
    final nameServers = domainData['name_servers'] as List? ?? [];
    final domainName = domainData['name']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(domainName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NS节点', style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (nameServers.isEmpty)
                Text('无', style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant))
              else
                ...nameServers.map((ns) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(ns.toString(), style: Theme.of(ctx).textTheme.bodyMedium),
                )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
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
    final typeColor = DriverColorUtils.getDnsTypeColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: typeColor,
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
            Icon(Icons.cloud, size: 16, color: const Color(0xFF3B82F6)),
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

  String _parseRegistrarType(String ownerType) {
    switch (ownerType.toLowerCase()) {
      case 'cloudflare':
        return 'Cloudflare Registrar';
      case 'apex':
        return 'Apex (Root)';
      case 'full':
        return 'Full DNS';
      case 'partial':
        return 'Partial DNS';
      case 'secondary':
        return 'Secondary DNS';
      default:
        return ownerType;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = DriverColorUtils.getStatusColor(status);
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