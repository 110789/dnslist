import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../interfaces/driver_interface.dart';
import '../driver_colors.dart';
import '../../utils/network/api_client.dart';
import '../../core/config/app_config.dart';

class DnsheDriver implements DriverInterface {
  static const String _providerId = 'dnshe';
  static const String _providerName = 'DNSHE';
  static const String _providerIcon = 'assets/icons/dnshe.jpg';

  ApiClient? _client;
  String? _apiToken;

  static const Map<String, String> _errorCodeMap = {
    'auth_invalid_credentials': 'API 密钥或密钥 Secret 错误，请检查凭证是否正确',
    'auth_ip_not_allowed': 'IP 地址未授权，请在 DNSHE 后台添加本机 IP',
    'api_access_disabled': 'API 访问已被禁用，请联系 DNSHE 客服',
    'not_found': '资源不存在',
    'subdomain_not_found': '子域名不存在，可能已被删除',
    'dns_record_not_found': 'DNS 记录不存在，可能已被删除',
    'quota_exceeded': '配额已超出限制，请清理无用域名或联系升级',
    'rate_limit_exceeded': '请求频率超限，请稍后重试',
    'provider_operation_failed': '服务商操作失败，请稍后重试',
    'internal_error': '服务器内部错误，请稍后重试',
    'no_renew_config': '续期未配置，请在 DNSHE 后台设置自动续期',
    'not_in_renew_window': '不在续期窗口期内，域名即将过期时才能续期',
    'redemption_manual': '域名已过期，需要人工处理，请联系客服',
    'renew_grace_expired': '宽限期已过期，域名已进入暂停状态',
    'redemption_balance_insufficient': '账户余额不足，无法完成续期',
    'bad_request': '请求参数无效，请检查输入格式',
    'subdomain_already_exists': '子域名已存在，请换一个名称重试',
    'invalid_subdomain_format': '子域名格式不正确，只能包含字母、数字和连字符',
    'root_domain_not_found': '根域名不存在',
    'subdomain_limit_reached': '子域名数量已达上限',
    'dns_record_limit_reached': 'DNS 记录数量已达上限',
    'duplicate_dns_record': 'DNS 记录已存在，不能重复添加',
    'invalid_record_type': '不支持的记录类型',
    'invalid_ttl_value': 'TTL 值超出允许范围（60-86400）',
    'invalid_priority_value': '优先级值无效（仅 MX/SRV 记录需要）',
    'record_type_conflict': '记录类型冲突，同一名称不能同时存在 A 和 CNAME 记录',
    'content_too_long': '记录内容过长，请缩短',
    'invalid_ip_format': 'IP 地址格式不正确',
    'invalid_domain_format': '域名格式不正确',
    'invalid_cname_content': 'CNAME 记录内容必须是有效域名',
    'mx_record_requires_priority': 'MX 记录必须设置优先级',
    'cname_cannot_have_other_records': 'CNAME 记录不能与其他记录共存于同一名称',
    'zone_not_active': '域名未激活，请先激活后再操作',
    'zone_suspended': '域名已被暂停，请联系客服恢复',
    'zone_expired': '域名已过期，请先续期后再操作',
    'operation_not_allowed': '当前操作不被允许',
    'permission_denied': '权限不足，无法执行此操作',
    'maintenance_mode': '服务商系统维护中，请稍后再试',
    'service_unavailable': '服务暂时不可用，请稍后重试',
  };

  String? _apiKey;
  String? _apiSecret;

  @override
  String get providerId => _providerId;

  @override
  String get providerName => _providerName;

  @override
  String get providerIcon => _providerIcon;

  @override
  String mapErrorCode(String code) {
    return _errorCodeMap[code] ?? _getGenericErrorMessage(code);
  }

  String _getGenericErrorMessage(String code) {
    final lowerCode = code.toString().toLowerCase();
    if (lowerCode.contains('auth') || lowerCode.contains('credential')) {
      return '认证失败，请检查 API Key 和 API Secret 是否正确';
    }
    if (lowerCode.contains('not_found') || lowerCode.contains('不存在')) {
      return '请求的资源不存在';
    }
    if (lowerCode.contains('quota') || lowerCode.contains('limit')) {
      return '超出限制配额，请升级或清理无用资源';
    }
    if (lowerCode.contains('rate') || lowerCode.contains('频率')) {
      return '请求过于频繁，请稍后再试';
    }
    if (lowerCode.contains('timeout')) {
      return '请求超时，请检查网络后重试';
    }
    if (lowerCode.contains('invalid') || lowerCode.contains('格式')) {
      return '请求参数格式错误，请检查输入内容';
    }
    if (lowerCode.contains('expired') || lowerCode.contains('过期')) {
      return '资源已过期，请先续期';
    }
    if (lowerCode.contains('suspended') || lowerCode.contains('暂停')) {
      return '资源已被暂停，请联系客服恢复';
    }
    if (lowerCode.contains('permission') || lowerCode.contains('权限')) {
      return '权限不足，无法执行此操作';
    }
    return '操作失败，请稍后重试';
  }

  @override
  String getAddDomainTitle() => '添加子域名';

  @override
  List<AddDomainField> getAddDomainFields() {
    return [
      const AddDomainField(
        key: 'subdomain',
        label: '子域名前缀',
        hintText: '例如: myapp',
      ),
      const AddDomainField(
        key: 'rootdomain',
        label: '根域名',
        hintText: '例如: example.com',
        description: '将创建: {子域名}.{根域名}',
      ),
    ];
  }

  @override
  Map<String, dynamic> prepareDomainData(Map<String, dynamic> input) {
    return {
      'subdomain': input['subdomain'] ?? '',
      'rootdomain': input['rootdomain'] ?? '',
    };
  }

  Map<String, dynamic> _parseError(dynamic responseData) {
    if (responseData == null) {
      return {'error': '服务器无响应，请稍后重试', 'errorCode': 'UNKNOWN', 'success': false};
    }
    final data = responseData is Map ? responseData : {};
    final errorCode = data['error_code']?.toString() ?? data['errorCode']?.toString() ?? 'UNKNOWN';
    final message = data['message']?.toString() ?? data['error']?.toString() ?? '';
    final mappedMessage = _errorCodeMap[errorCode];
    if (mappedMessage != null) {
      return {'error': mappedMessage, 'errorCode': errorCode, 'success': false, 'rawMessage': message};
    }
    return {'error': message.isNotEmpty ? message : '操作失败，请稍后重试', 'errorCode': errorCode, 'success': false, 'rawMessage': message};
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
      return {
        'subdomains': [],
        'pagination': {},
        'error': '未初始化认证，请先添加账户',
        'errorCode': 'AUTH_REQUIRED',
        'success': false
      };
    }
    try {
      final queryParams = <String, dynamic>{
        'm': 'domain_hub',
        'endpoint': 'subdomains',
        'action': 'list',
        'page': page,
        'per_page': pageSize,
        'include_total': false,
      };
      if (filters != null) {
        if (filters.containsKey('name')) {
          queryParams['search'] = filters['name'];
        }
        if (filters.containsKey('rootdomain')) {
          queryParams['rootdomain'] = filters['rootdomain'];
        }
        if (filters.containsKey('status')) {
          queryParams['status'] = filters['status'];
        }
      }
      final response = await _client!.get('', queryParameters: queryParams);
      if (response.data['success'] == true) {
        final subdomainsList = response.data['subdomains'] as List? ?? [];
        final subdomains = subdomainsList.map((sub) {
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
        }).toList();
        final pagination = response.data['pagination'] ?? {
          'page': page,
          'per_page': pageSize,
          'total': subdomainsList.length,
        };
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
      }
      return _parseError(response.data);
    } catch (e) {
      return {
        'subdomains': [],
        'pagination': {},
        'error': _handleException(e),
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
      return {
        'records': [],
        'pagination': {},
        'error': '未初始化认证，请先添加账户',
        'errorCode': 'AUTH_REQUIRED',
        'success': false
      };
    }
    if (domainId.isEmpty) {
      return {
        'records': [],
        'pagination': {},
        'error': '子域名标识无效',
        'errorCode': 'INVALID_DOMAIN_ID',
        'success': false
      };
    }
    try {
      final queryParams = <String, dynamic>{
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'list',
        'subdomain_id': int.tryParse(domainId) ?? domainId,
      };
      final response = await _client!.get('', queryParameters: queryParams);
      if (response.data['success'] == true) {
        final recordsList = response.data['records'] as List? ?? [];
        final records = recordsList.map((record) {
          return {
            'id': record['id']?.toString() ?? '',
            'record_id': record['record_id']?.toString() ?? '',
            'name': record['name']?.toString() ?? '',
            'type': record['type']?.toString() ?? 'A',
            'content': record['content']?.toString() ?? '',
            'ttl': record['ttl'] ?? 600,
            'priority': record['priority'],
            'line': record['line'],
            'proxied': record['proxied'] ?? false,
            'status': record['status']?.toString() ?? 'active',
            'created_at': record['created_at'],
            'updated_at': record['updated_at'],
          };
        }).toList();
        return {
          'records': records,
          'pagination': {'total': recordsList.length, 'page': 1, 'per_page': pageSize},
          'success': true,
          'statusCode': 'OK',
          'total': recordsList.length,
          'page': 1,
          'pageSize': pageSize,
        };
      }
      return _parseError(response.data);
    } catch (e) {
      return {
        'records': [],
        'pagination': {},
        'error': _handleException(e),
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
    if (_client == null) return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    try {
      final subdomainId = int.tryParse(domainId) ?? 0;
      if (subdomainId <= 0) {
        return {'error': '子域名标识无效', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};
      }
      final bodyData = <String, dynamic>{
        'subdomain_id': subdomainId,
      };
      if (recordData.containsKey('type')) bodyData['type'] = recordData['type'];
      if (recordData.containsKey('name')) bodyData['name'] = recordData['name'];
      if (recordData.containsKey('content')) bodyData['content'] = recordData['content'];
      if (recordData.containsKey('ttl')) {
        final ttl = recordData['ttl'];
        if (ttl != null && ttl > 0) bodyData['ttl'] = ttl;
      }
      if (recordData.containsKey('priority')) {
        final priority = recordData['priority'];
        if (priority != null && priority > 0) bodyData['priority'] = priority;
      }
      if (recordData.containsKey('line')) bodyData['line'] = recordData['line'];
      if (recordData.containsKey('proxied')) bodyData['proxied'] = recordData['proxied'] ?? false;
      final response = await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'create',
      }, data: bodyData);
      if (response.data['success'] == true) {
        return {
          'success': true,
          'statusCode': 'OK',
          'data': {
            'id': response.data['id']?.toString() ?? '',
            'record_id': response.data['record_id']?.toString() ?? '',
            'message': response.data['message'] ?? 'DNS 记录创建成功',
          }
        };
      }
      return _parseError(response.data);
    } catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> updateDnsRecord(
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
  ) async {
    if (_client == null) return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    try {
      final recordIdInt = int.tryParse(recordId);
      if (recordIdInt == null || recordIdInt <= 0) {
        return {'error': '记录标识无效', 'errorCode': 'INVALID_RECORD_ID', 'success': false};
      }
      final bodyData = <String, dynamic>{'id': recordIdInt};
      if (recordData.containsKey('type')) bodyData['type'] = recordData['type'];
      if (recordData.containsKey('name')) bodyData['name'] = recordData['name'];
      if (recordData.containsKey('content')) bodyData['content'] = recordData['content'];
      if (recordData.containsKey('ttl')) {
        final ttl = recordData['ttl'];
        if (ttl != null && ttl > 0) bodyData['ttl'] = ttl;
      }
      if (recordData.containsKey('priority')) {
        final priority = recordData['priority'];
        if (priority != null && priority > 0) bodyData['priority'] = priority;
      }
      if (recordData.containsKey('proxied')) bodyData['proxied'] = recordData['proxied'];
      final response = await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'update',
      }, data: bodyData);
      if (response.data['success'] == true) {
        return {
          'success': true,
          'statusCode': 'OK',
          'data': {
            'id': response.data['id']?.toString() ?? recordId,
            'record_id': response.data['record_id']?.toString() ?? '',
            'message': response.data['message'] ?? 'DNS 记录更新成功',
          }
        };
      }
      return _parseError(response.data);
    } catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> deleteDnsRecord(String domainId, String recordId) async {
    if (_client == null) {
      return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    try {
      final recordIdInt = int.tryParse(recordId);
      if (recordIdInt == null || recordIdInt <= 0) {
        return {'error': '记录标识无效', 'errorCode': 'INVALID_RECORD_ID', 'success': false};
      }
      final response = await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'delete',
      }, data: {'id': recordIdInt});
      if (response.data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'message': 'DNS 记录已删除'};
      }
      return _parseError(response.data);
    } catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  String _handleException(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          return '连接超时，请检查网络后重试';
        case DioExceptionType.receiveTimeout:
          return '服务器响应超时，请稍后重试';
        case DioExceptionType.sendTimeout:
          return '请求发送超时，请稍后重试';
        case DioExceptionType.connectionError:
          return '网络连接失败，请检查网络设置';
        default:
          return '网络请求失败，请稍后重试';
      }
    }
    return '操作失败，请稍后重试';
  }

  @override
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData) async {
    if (_client == null) return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    try {
      final subdomain = domainData['subdomain']?.toString().trim() ?? '';
      final rootdomain = domainData['rootdomain']?.toString().trim() ?? '';
      if (subdomain.isEmpty) {
        return {'error': '子域名前缀不能为空', 'errorCode': 'INVALID_SUBDOMAIN', 'success': false};
      }
      if (rootdomain.isEmpty) {
        return {'error': '根域名不能为空', 'errorCode': 'INVALID_ROOTDOMAIN', 'success': false};
      }
      if (!RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$').hasMatch(subdomain)) {
        return {'error': '子域名格式不正确，只能包含字母、数字和连字符', 'errorCode': 'INVALID_SUBDOMAIN_FORMAT', 'success': false};
      }
      final response = await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'subdomains',
        'action': 'register',
      }, data: {
        'subdomain': subdomain,
        'rootdomain': rootdomain,
      });
      if (response.data['success'] == true) {
        return {
          'success': true,
          'statusCode': 'OK',
          'data': {
            'id': response.data['subdomain_id']?.toString() ?? '',
            'name': response.data['full_domain']?.toString() ?? '$subdomain.$rootdomain',
            'subdomain': subdomain,
            'rootdomain': rootdomain,
          },
          'message': response.data['message'] ?? '子域名注册成功'
        };
      }
      return _parseError(response.data);
    } catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> deleteDomain(String domainId) async {
    if (_client == null) {
      return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    if (domainId.isEmpty) {
      return {'error': '子域名标识无效', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};
    }
    try {
      final subdomainId = int.tryParse(domainId);
      if (subdomainId == null || subdomainId <= 0) {
        return {'error': '子域名标识无效', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};
      }
      final response = await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'subdomains',
        'action': 'delete',
      }, data: {'subdomain_id': subdomainId});
      if (response.data['success'] == true) {
        return {
          'success': true,
          'statusCode': 'OK',
          'message': response.data['message'] ?? '子域名已删除',
          'dns_records_deleted': response.data['dns_records_deleted'] ?? 0,
        };
      }
      return _parseError(response.data);
    } catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> renewDomain(String domainId) async {
    if (_client == null) return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    if (domainId.isEmpty) {
      return {'error': '子域名标识无效', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};
    }
    try {
      final subdomainId = int.tryParse(domainId);
      if (subdomainId == null || subdomainId <= 0) {
        return {'error': '子域名标识无效', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};
      }
      final response = await _client!.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'subdomains',
        'action': 'renew',
      }, data: {'subdomain_id': subdomainId});
      if (response.data['success'] == true) {
        return {
          'success': true,
          'statusCode': 'OK',
          'data': {
            'subdomain_id': response.data['subdomain_id'],
            'remaining_days': response.data['remaining_days'] ?? 365,
            'new_expires_at': response.data['new_expires_at'],
            'charged_amount': response.data['charged_amount'] ?? 0,
          },
          'message': response.data['message'] ?? '域名续期成功',
        };
      }
      return _parseError(response.data);
    } catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  bool get supportsAddDomain => true;

  @override
  bool get supportsDeleteDomain => true;

  @override
  bool get supportsRenewDomain => true;

  @override
  bool get supportsShowNameServers => false;

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
        if (supportsRenew) const PopupMenuItem(value: 'renew', child: Text('续期')),
        if (supportsDelete) const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Color(0xFFEF4444)))),
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
    final priority = recordData['priority'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: DriverColorUtils.getDnsTypeColor(type),
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
                      Text('P$priority', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DriverColorUtils.dnsTypeMX)),
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
            const Icon(Icons.cloud, size: 16, color: DriverColorUtils.dnsTypeA),
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