import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../interfaces/driver_interface.dart';
import '../../utils/network/api_client.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/design_system.dart';

class ClouDNSDriver implements DriverInterface {
  static const String _providerId = 'cloudns';
  static const String _providerName = 'ClouDNS';
  static const String _providerIcon = 'assets/icons/cloudns.svg';

  static const Map<String, String> _errorCodeMap = {
    'Invalid authentication, incorrect auth-id or auth-password.': 'API ID 或密码错误，请检查凭证是否正确',
    'Invalid authentication, incorrect sub-auth-id, sub-auth-user or auth-password.': '子用户凭证错误，请检查用户名和密码',
    'Wrong or missing required parameter \'auth-id\'.': '缺少 auth-id 参数，请提供正确的 API ID',
    'Missing domain-name': '缺少域名参数',
    'Missing required parameter \'page\'.': '缺少分页参数',
    'Wrong or missing required parameter \'rows-per-page\'.': '每页条数参数无效',
    'Missing required parameter \'id\'.': '缺少记录 ID 参数',
    'Wrong or missing required parameter \'password\'.': '密码参数无效',
    'Invalid TTL. Choose from the list of the values we support.': 'TTL 值无效，请使用支持的 TTL 值',
    'This record type is not supported.': '不支持的记录类型',
    'Invalid record-id param.': '记录 ID 无效',
    'This is not a domain name.': '记录值不是有效的域名',
    'This is not a valid IP address.': '记录值不是有效的 IP 地址',
    'The domain must be pointed to an URL as shown in the example.': 'URL 转发格式不正确',
    'There is no such zone.': '域名不存在',
    'There is no such record.': '记录不存在',
    'This domain is already taken.': '域名已存在，无需重复添加',
    'Zone is already deleted.': '域名已删除',
    'You can\'t add records in this type of zone.': '当前域名类型不支持添加记录',
    'This feature is not available for your plan.': '当前套餐不支持此功能',
    'You don\'t have access to this zone.': '无操作此域名的权限',
    'You don\'t have access to this record.': '无操作此记录的权限',
    'This is not a master zone.': '当前域名类型不支持此操作',
    'You can\'t delete this record.': '无法删除此记录',
    'You have reached the zones limit for this sub-user.': '已达到子用户域名数量上限',
    'You have reached the records limit for this sub-user.': '已达到子用户记录数量上限',
    'Wrong or missing parameter.': '请求参数错误',
    'Request limit exceeded.': '请求频率超限，请稍后重试',
    'Service is temporarily unavailable.': '服务暂时不可用，请稍后重试',
  };

  int? _authId;
  String? _authPassword;
  ApiClient? _client;

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
    final lowerCode = code.toLowerCase();
    if (lowerCode.contains('authentication') || lowerCode.contains('auth')) {
      return '认证失败，请检查 API ID 和密码是否正确';
    }
    if (lowerCode.contains('zone') && lowerCode.contains('not') || lowerCode.contains('no such zone')) {
      return '域名不存在';
    }
    if (lowerCode.contains('record') && lowerCode.contains('not') || lowerCode.contains('no such record')) {
      return '记录不存在';
    }
    if (lowerCode.contains('limit') || lowerCode.contains('quota')) {
      return '超出限制配额，请清理无用资源';
    }
    if (lowerCode.contains('permission') || lowerCode.contains('access')) {
      return '权限不足，无法执行此操作';
    }
    if (lowerCode.contains('invalid') || lowerCode.contains('wrong')) {
      return '请求参数错误，请检查输入内容';
    }
    return '操作失败，请稍后重试';
  }

  @override
  String getAddDomainTitle() => '添加域名';

  @override
  List<AddDomainField> getAddDomainFields() {
    return [
      const AddDomainField(
        key: 'domain',
        label: '域名',
        hintText: '例如: example.com',
        description: '输入要添加的域名',
      ),
    ];
  }

  @override
  Map<String, dynamic> prepareDomainData(Map<String, dynamic> input) {
    return {
      'domain': input['domain'] ?? input['name'] ?? '',
    };
  }

  Map<String, dynamic> _parseError(dynamic responseData) {
    if (responseData == null) {
      return {'error': '服务器无响应，请稍后重试', 'errorCode': 'UNKNOWN', 'success': false};
    }
    final data = responseData is Map ? responseData : {};
    final status = data['status']?.toString();
    if (status == 'Failed') {
      final message = data['statusDescription']?.toString() ?? '操作失败';
      final mappedMessage = _errorCodeMap[message] ?? _getGenericErrorMessage(message);
      return {'error': mappedMessage, 'errorCode': message, 'success': false, 'rawMessage': message};
    }
    return {'error': '操作失败，请稍后重试', 'errorCode': 'UNKNOWN', 'success': false};
  }

  Future<Map<String, dynamic>> _callApi(String action, Map<String, dynamic> params) async {
    if (_authId == null || _authPassword == null) {
      return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    try {
      final queryParams = <String, dynamic>{
        'auth-id': _authId,
        'auth-password': _authPassword,
        ...params,
      };
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.cloudnsBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
      final response = await dio.get('/$action', queryParameters: queryParams);
      if (response.data == null) {
        return {'error': '服务器无响应', 'errorCode': 'UNKNOWN', 'success': false};
      }
      var respData = response.data;
      if (respData is String) {
        try {
          respData = jsonDecode(respData);
        } catch (_) {
          return {'error': '响应解析失败', 'errorCode': 'PARSE_ERROR', 'success': false};
        }
      }
      if (respData is! Map) {
        return {'error': '响应数据格式异常', 'errorCode': 'PARSE_ERROR', 'success': false};
      }
      final data = respData as Map;
      final status = data['status']?.toString();
      if (status == 'Success') {
        return {'success': true, 'data': data, 'statusCode': 'OK'};
      }
      return _parseError(data);
    } on DioException catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    } catch (e) {
      return {'error': '操作失败，请稍后重试', 'errorCode': 'UNKNOWN', 'success': false};
    }
  }

  dynamic _parseJsonString(String jsonStr) {
    try {
      return jsonDecode(jsonStr);
    } catch (_) {
      return null;
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
  Future<bool> validateCredential(Map<String, String> credentials) async {
    final authId = credentials['authId'];
    final authPassword = credentials['authPassword'];
    if (authId == null || authId.isEmpty || authPassword == null || authPassword.isEmpty) {
      return false;
    }
    final authIdInt = int.tryParse(authId);
    if (authIdInt == null) return false;
    try {
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.cloudnsBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));
      final response = await dio.get(
        '/login/login.json',
        queryParameters: {
          'auth-id': authIdInt,
          'auth-password': authPassword,
        },
      );
      if (response.data == null) {
        return false;
      }
      var data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          return false;
        }
      }
      if (data is Map) {
        final status = data['status']?.toString();
        if (status == 'Success') {
          _authId = authIdInt;
          _authPassword = authPassword;
          _client = ApiClient(
            baseUrl: AppConfig.cloudnsBaseUrl,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getDomains({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    if (_authId == null || _authPassword == null) {
      return {'domains': [], 'pagination': {}, 'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    try {
      final params = <String, dynamic>{
        'page': page,
        'rows-per-page': pageSize,
      };
      if (filters != null && filters.containsKey('search')) {
        params['search'] = filters['search'];
      }
      final result = await _callApi('dns/list-zones.json', params);
      if (result['success'] == true) {
        final data = result['data'] as Map;
        final zonesList = data['zones'] as List? ?? [];
        final pageCount = int.tryParse(data['pages_count']?.toString() ?? '1') ?? 1;
        final domains = zonesList.map((zone) {
          return {
            'id': zone['id']?.toString() ?? '',
            'domain_id': zone['id'],
            'name': zone['name']?.toString() ?? '',
            'domain': zone['name']?.toString() ?? '',
            'type': zone['type']?.toString() ?? 'master',
            'status': zone['status']?.toString() ?? 'active',
            'created_at': zone['created_at'],
          };
        }).toList();
        return {
          'domains': domains,
          'pagination': {
            'total': domains.length,
            'page': page,
            'per_page': pageSize,
            'pages_count': pageCount,
          },
          'success': true,
          'statusCode': 'OK',
          'total': domains.length,
          'page': page,
          'pageSize': pageSize,
        };
      }
      return _parseError(result['data']);
    } catch (e) {
      return {
        'domains': [],
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
    int pageSize = 50,
    Map<String, String>? filters,
  }) async {
    if (_authId == null || _authPassword == null) {
      return {'records': [], 'pagination': {}, 'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    if (domainId.isEmpty) {
      return {'records': [], 'pagination': {}, 'error': '域名标识无效', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};
    }
    try {
      final domainsResult = await getDomains();
      if (domainsResult['success'] != true) {
        return {'records': [], 'pagination': {}, 'error': '获取域名信息失败', 'errorCode': 'GET_DOMAIN_FAILED', 'success': false};
      }
      final domains = domainsResult['domains'] as List;
      final domain = domains.firstWhere(
        (d) => d['id'].toString() == domainId || d['domain'].toString() == domainId,
        orElse: () => <String, dynamic>{},
      );
      if (domain.isEmpty) {
        return {'records': [], 'pagination': {}, 'error': '域名不存在', 'errorCode': 'DOMAIN_NOT_FOUND', 'success': false};
      }
      final domainName = domain['domain'].toString();
      final params = <String, dynamic>{
        'domain-name': domainName,
        'rows-per-page': pageSize,
        'page': page,
      };
      if (filters != null) {
        if (filters.containsKey('host')) {
          params['host'] = filters['host'];
        }
        if (filters.containsKey('type')) {
          params['type'] = filters['type'];
        }
      }
      final result = await _callApi('dns/records.json', params);
      if (result['success'] == true) {
        final data = result['data'] as Map;
        final recordsList = data['records'] as List? ?? [];
        final records = recordsList.map((record) {
          return {
            'id': record['id']?.toString() ?? '',
            'record_id': record['id'],
            'name': record['host']?.toString() ?? '',
            'host': record['host']?.toString() ?? '',
            'type': record['type']?.toString() ?? 'A',
            'record_type': record['type']?.toString() ?? 'A',
            'content': record['record']?.toString() ?? '',
            'value': record['record']?.toString() ?? '',
            'ttl': int.tryParse(record['ttl']?.toString() ?? '3600') ?? 3600,
            'priority': int.tryParse(record['priority']?.toString() ?? '0') ?? 0,
            'mx': int.tryParse(record['priority']?.toString() ?? '0') ?? 0,
            'status': record['status']?.toString() ?? 'active',
            'enabled': record['status']?.toString() == 'active',
          };
        }).toList();
        return {
          'records': records,
          'pagination': {'total': recordsList.length, 'page': page, 'per_page': pageSize},
          'success': true,
          'statusCode': 'OK',
          'total': recordsList.length,
          'page': page,
          'pageSize': pageSize,
        };
      }
      return _parseError(result['data']);
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
    if (_authId == null || _authPassword == null) {
      return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    try {
      final domainsResult = await getDomains();
      if (domainsResult['success'] != true) {
        return {'error': '获取域名信息失败', 'errorCode': 'GET_DOMAIN_FAILED', 'success': false};
      }
      final domains = domainsResult['domains'] as List;
      final domain = domains.firstWhere(
        (d) => d['id'].toString() == domainId || d['domain'].toString() == domainId,
        orElse: () => <String, dynamic>{},
      );
      if (domain.isEmpty) {
        return {'error': '域名不存在', 'errorCode': 'DOMAIN_NOT_FOUND', 'success': false};
      }
      final domainName = domain['domain'].toString();
      final params = <String, dynamic>{
        'domain-name': domainName,
      };
      final host = recordData['name']?.toString() ?? recordData['host']?.toString() ?? '@';
      if (host.isNotEmpty && host != '@') {
        params['host'] = host;
      }
      final recordType = recordData['type']?.toString() ?? recordData['record_type']?.toString() ?? 'A';
      params['type'] = recordType;
      final value = recordData['content']?.toString() ?? recordData['value']?.toString() ?? '';
      if (value.isNotEmpty) params['record'] = value;
      final ttl = recordData['ttl'];
      if (ttl != null && ttl > 0) params['ttl'] = ttl;
      if ((recordType == 'MX' || recordType == 'SRV') && recordData.containsKey('priority')) {
        final priority = recordData['priority'] ?? recordData['mx'];
        if (priority != null && priority > 0) params['priority'] = priority;
      }
      final result = await _callApi('dns/add-record.json', params);
      if (result['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'message': 'DNS 记录创建成功'};
      }
      return _parseError(result['data']);
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
    if (_authId == null || _authPassword == null) {
      return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    if (recordId.isEmpty) {
      return {'error': '记录标识无效', 'errorCode': 'INVALID_RECORD_ID', 'success': false};
    }
    try {
      final domainsResult = await getDomains();
      if (domainsResult['success'] != true) {
        return {'error': '获取域名信息失败', 'errorCode': 'GET_DOMAIN_FAILED', 'success': false};
      }
      final domains = domainsResult['domains'] as List;
      final domain = domains.firstWhere(
        (d) => d['id'].toString() == domainId || d['domain'].toString() == domainId,
        orElse: () => <String, dynamic>{},
      );
      if (domain.isEmpty) {
        return {'error': '域名不存在', 'errorCode': 'DOMAIN_NOT_FOUND', 'success': false};
      }
      final domainName = domain['domain'].toString();
      final params = <String, dynamic>{
        'domain-name': domainName,
        'id': int.tryParse(recordId) ?? recordId,
      };
      if (recordData.containsKey('host')) {
        params['host'] = recordData['host']?.toString();
      }
      if (recordData.containsKey('type')) {
        params['type'] = recordData['type']?.toString();
      }
      if (recordData.containsKey('record') || recordData.containsKey('content')) {
        params['record'] = recordData['record']?.toString() ?? recordData['content']?.toString();
      }
      if (recordData.containsKey('ttl')) {
        final ttl = recordData['ttl'];
        if (ttl != null && ttl > 0) params['ttl'] = ttl;
      }
      if (recordData.containsKey('priority') || recordData.containsKey('mx')) {
        final priority = recordData['priority'] ?? recordData['mx'];
        if (priority != null && priority > 0) params['priority'] = priority;
      }
      final result = await _callApi('dns/update-record.json', params);
      if (result['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'message': 'DNS 记录更新成功'};
      }
      return _parseError(result['data']);
    } catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<void> deleteDnsRecord(String domainId, String recordId) async {
    if (_authId == null || _authPassword == null) return;
    if (domainId.isEmpty || recordId.isEmpty) return;
    try {
      final domainsResult = await getDomains();
      if (domainsResult['success'] != true) return;
      final domains = domainsResult['domains'] as List;
      final domain = domains.firstWhere(
        (d) => d['id'].toString() == domainId || d['domain'].toString() == domainId,
        orElse: () => {},
      );
      if (domain.isEmpty) return;
      final domainName = domain['domain'].toString();
      final params = <String, dynamic>{
        'domain-name': domainName,
        'id': int.tryParse(recordId) ?? recordId,
      };
      await _callApi('dns/delete-record.json', params);
    } catch (e) {}
  }

  @override
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData) async {
    if (_authId == null || _authPassword == null) {
      return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    final domain = domainData['domain']?.toString() ?? domainData['name']?.toString() ?? '';
    if (domain.isEmpty) {
      return {'error': '域名不能为空', 'errorCode': 'INVALID_DOMAIN', 'success': false};
    }
    try {
      final params = <String, dynamic>{'domain-name': domain};
      final result = await _callApi('dns/register.json', params);
      if (result['success'] == true) {
        final data = result['data'] as Map;
        return {
          'success': true,
          'statusCode': 'OK',
          'data': {
            'id': data['id']?.toString() ?? '',
            'domain_id': data['id'],
            'name': domain,
            'domain': domain,
          },
          'message': '域名添加成功'
        };
      }
      return _parseError(result['data']);
    } catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> deleteDomain(String domainId) async {
    if (_authId == null || _authPassword == null) {
      return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    if (domainId.isEmpty) {
      return {'error': '域名标识无效', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};
    }
    try {
      final domainsResult = await getDomains();
      if (domainsResult['success'] != true) {
        return _parseError(domainsResult['data']);
      }
      final domains = domainsResult['domains'] as List;
      final domain = domains.firstWhere(
        (d) => d['id'].toString() == domainId || d['domain'].toString() == domainId,
        orElse: () => <String, dynamic>{},
      );
      if (domain.isEmpty) {
        return {'error': '域名不存在', 'errorCode': 'DOMAIN_NOT_FOUND', 'success': false};
      }
      final domainName = domain['domain'].toString();
      final params = <String, dynamic>{'domain-name': domainName};
      final result = await _callApi('dns/delete.json', params);
      if (result['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'message': '域名已删除'};
      }
      return _parseError(result['data']);
    } catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> renewDomain(String domainId) async {
    return {'error': 'ClouDNS 不支持 API 续期域名', 'errorCode': 'NOT_SUPPORTED', 'success': false};
  }

  @override
  bool get supportsAddDomain => true;

  @override
  bool get supportsDeleteDomain => true;

  @override
  bool get supportsRenewDomain => false;

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
      position: RelativeRect.fromLTRB(
        offset.dx + renderBox.size.width / 2,
        offset.dy + renderBox.size.height / 2,
        offset.dx + renderBox.size.width,
        offset.dy + renderBox.size.height,
      ),
      items: [
        if (supportsDelete) PopupMenuItem(value: 'delete', child: const Text('删除', style: TextStyle(color: Color(0xFFEF4444)))),
      ],
    ).then((value) {
      if (value == 'delete') onDelete();
    });
  }

  @override
  Widget buildDnsRecordListItem(Map<String, dynamic> recordData) {
    final name = recordData['host']?.toString() ?? recordData['name']?.toString() ?? '';
    final type = recordData['type']?.toString() ?? recordData['record_type']?.toString() ?? 'A';
    final content = recordData['content']?.toString() ?? recordData['value']?.toString() ?? '';
    final ttl = recordData['ttl'] as int? ?? 3600;
    final priority = recordData['priority'] ?? recordData['mx'];
    final enabled = recordData['enabled'] == true || recordData['status']?.toString() == 'active';

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
                    Flexible(child: Text(name.isEmpty ? '@' : name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (priority != null && priority > 0) ...[
                      const SizedBox(width: 4),
                      Text('P$priority', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DnsDesignTokens.dnsTypeMX)),
                    ],
                    if (!enabled) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text('暂停', style: TextStyle(fontSize: 9, color: Colors.orange)),
                      ),
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
        ],
      ),
    );
  }

  @override
  Map<String, String> getCredentialFields() {
    return {'authId': 'Auth ID', 'authPassword': 'Auth Password'};
  }

  @override
  List<String> getSupportedRecordTypes() {
    return ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SRV', 'CAA', 'URL', 'FRAME'];
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