import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../interfaces/driver_interface.dart';
import '../driver_colors.dart';
import '../../utils/network/api_client.dart';
import '../../core/services/service_registry.dart';

class RainyunDriver implements DriverInterface {
  static const String _providerId = 'rainyun';
  static const String _providerName = '雨云';
  static const String _providerIcon = 'assets/icons/rainyun.svg';

  static const Map<String, String> _errorCodeMap = {
    'auth_invalid_credentials': 'API 密钥无效，请检查密钥是否正确',
    'auth_ip_not_allowed': 'IP 未授权，请在雨云控制台添加IP白名单',
    'api_access_disabled': 'API 访问被禁用，请联系客服启用',
    'bad_request': '请求参数无效，请检查输入内容',
    'domain_not_found': '域名不存在',
    'dns_record_not_found': 'DNS 记录不存在',
    'not_found': '资源不存在',
    'rate_limit_exceeded': '请求频率超限，请稍后重试',
    'quota_exceeded': '配额超出，请升级套餐或清理资源',
    'internal_error': '服务器内部错误，请稍后重试',
    'provider_operation_failed': '服务商操作失败，请稍后重试',
    'invalid_line': '无效的解析线路',
    'invalid_ttl': 'TTL 值无效，最小为 600 秒',
    'missing_default_line': '至少需要一条默认线路记录',
    'record_exists': 'DNS 记录已存在',
    'template_not_found': '域名模板不存在',
    'permission_denied': '无权限执行此操作',
  };

  String? _savedApiKey;
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
    if (lowerCode.contains('auth') || lowerCode.contains('invalid_credentials')) {
      return '认证失败，请检查 API 密钥是否正确';
    }
    if (lowerCode.contains('domain') && lowerCode.contains('not')) {
      return '域名不存在';
    }
    if (lowerCode.contains('record') && lowerCode.contains('not')) {
      return '记录不存在';
    }
    if (lowerCode.contains('limit') || lowerCode.contains('quota')) {
      return '超出限制配额，请清理无用资源';
    }
    if (lowerCode.contains('permission') || lowerCode.contains('access')) {
      return '权限不足，无法执行此操作';
    }
    if (lowerCode.contains('invalid') || lowerCode.contains('bad')) {
      return '请求参数错误，请检查输入内容';
    }
    if (lowerCode.contains('rate') || lowerCode.contains('frequency')) {
      return '请求频率超限，请稍后重试';
    }
    if (lowerCode.contains('server') || lowerCode.contains('internal')) {
      return '服务器内部错误，请稍后重试';
    }
    return code;
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
    final code = data['code'];
    if (code != 200 && code != '200') {
      final errorCode = data['error_code']?.toString() ?? code?.toString() ?? '';
      final message = data['message']?.toString() ?? data['msg']?.toString() ?? '';
      final mappedMessage = _errorCodeMap[errorCode];
      if (mappedMessage != null) {
        return {'error': mappedMessage, 'errorCode': errorCode, 'success': false, 'rawMessage': message};
      }
      if (message.isNotEmpty) {
        return {'error': message, 'errorCode': errorCode, 'success': false, 'rawMessage': message};
      }
    }
    return {'error': '操作失败，请稍后重试', 'errorCode': 'UNKNOWN', 'success': false};
  }

  String _handleException(dynamic e) {
    if (e is DioException) {
      final response = e.response;
      if (response != null) {
        developer.log(
          'Rainyun API Error: status=${response.statusCode}, data=${response.data}',
          name: 'RainyunDriver',
        );
      }
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
          if (response != null) {
            final statusCode = response.statusCode;
            if (statusCode == 401) return 'API 密钥无效，请检查密钥是否正确';
            if (statusCode == 403) return '无访问权限，请检查域名是否属于您的账户';
            if (statusCode == 404) return '域名不存在';
            if (statusCode == 429) return '请求频率超限，请稍后重试';
          }
          return '网络请求失败，请稍后重试';
      }
    }
    developer.log(
      'Rainyun Driver Exception: $e',
      name: 'RainyunDriver',
    );
    return '操作失败，请稍后重试';
  }

  Dio _createDioClient(String apiKey) {
    final dio = Dio(BaseOptions(
      baseUrl: ServiceRegistry.instance.getProviderBaseUrl('rainyun'),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'X-Api-Key': apiKey,
        'Content-Type': 'application/json',
      },
      validateStatus: (status) => true,
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (o) => developer.log(o.toString(), name: 'RainyunDriver'),
    ));

    return dio;
  }

  @override
  Future<bool> validateCredential(Map<String, String> credentials) async {
    final apiKey = credentials['apiKey'];
    if (apiKey == null || apiKey.isEmpty) return false;

    developer.log(
      'Rainyun validateCredential: starting validation',
      name: 'RainyunDriver',
    );

    try {
      final dio = _createDioClient(apiKey);

      developer.log(
        'Rainyun: sending GET /product/ request',
        name: 'RainyunDriver',
      );

      final response = await dio.get('/product/');

      developer.log(
        'Rainyun response: statusCode=${response.statusCode}, data=${response.data}',
        name: 'RainyunDriver',
      );

      if (response.data == null) {
        developer.log('Rainyun: response data is null', name: 'RainyunDriver');
        return false;
      }

      var data = response.data;
      if (data is String) {
        developer.log('Rainyun: parsing string response', name: 'RainyunDriver');
        try {
          data = jsonDecode(data);
        } catch (e) {
          developer.log('Rainyun: JSON parse failed: $e', name: 'RainyunDriver');
          return false;
        }
      }

      if (data is Map) {
        final code = data['code'];
        developer.log(
          'Rainyun: code field = $code (type: ${code.runtimeType})',
          name: 'RainyunDriver',
        );

        if (code == 200 || code == '200') {
          developer.log('Rainyun: authentication successful', name: 'RainyunDriver');
          _savedApiKey = apiKey;
          _client = ApiClient(
            baseUrl: ServiceRegistry.instance.getProviderBaseUrl('rainyun'),
            headers: {
              'X-Api-Key': apiKey,
              'Content-Type': 'application/json',
            },
          );
          return true;
        }

        final errorCode = data['error_code']?.toString() ?? '';
        final errorMessage = data['message']?.toString() ?? '';
        developer.log(
          'Rainyun: auth failed - code=$code, error_code=$errorCode, message=$errorMessage',
          name: 'RainyunDriver',
        );
      }

      return false;
    } on DioException catch (e) {
      developer.log(
        'Rainyun DioException: type=${e.type}, message=${e.message}, response=${e.response?.data}',
        name: 'RainyunDriver',
      );
      return false;
    } catch (e) {
      developer.log(
        'Rainyun Exception: $e',
        name: 'RainyunDriver',
      );
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
      return {'domains': [], 'pagination': {}, 'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }

    try {
      final Map<String, dynamic> options = {
        'page': page,
        'page_size': pageSize,
      };

      if (filters != null && filters.containsKey('keyword')) {
        options['keyword'] = filters['keyword'];
      }

      final response = await _client!.get(
        '/product/domain/',
        queryParameters: {'options': '{}'},
      );

      if (response.data == null) {
        return {'domains': [], 'pagination': {}, 'error': '服务器无响应', 'errorCode': 'UNKNOWN', 'success': false};
      }

      var data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          return {'domains': [], 'pagination': {}, 'error': '响应解析失败', 'errorCode': 'PARSE_ERROR', 'success': false};
        }
      }

      if (data is Map) {
        final code = data['code'];
        if (code == 200 || code == '200') {
          final dataObj = data['data'] as Map? ?? {};
          final domainList = dataObj['Records'] as List? ?? [];
          final totalRecords = dataObj['TotalRecords'] as int? ?? 0;
          final domains = domainList.map((zone) {
            return {
              'id': zone['ID']?.toString() ?? zone['id']?.toString() ?? '',
              'name': zone['Domain']?.toString() ?? zone['domain']?.toString() ?? zone['Name']?.toString() ?? '',
              'domain': zone['Domain']?.toString() ?? zone['domain']?.toString() ?? zone['Name']?.toString() ?? '',
              'status': zone['Status']?.toString() ?? zone['status']?.toString() ?? 'active',
              'create_date': zone['CreateDate'] ?? zone['create_date'],
              'exp_date': zone['ExpDate'] ?? zone['exp_date'],
              'auto_renew': zone['AutoRenew'] ?? zone['auto_renew'] ?? false,
              'product': zone['Product']?.toString() ?? zone['product']?.toString() ?? 'domain',
            };
          }).toList();

          return {
            'domains': domains,
            'pagination': {
              'total': totalRecords,
              'page': page,
              'pageSize': pageSize,
            },
            'success': true,
            'statusCode': 'OK',
            'total': domains.length,
            'page': page,
            'pageSize': pageSize,
          };
        }

        return _parseError(data);
      }

      return {'domains': [], 'pagination': {}, 'error': '响应数据格式异常', 'errorCode': 'PARSE_ERROR', 'success': false};
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
    if (_client == null) {
      return {'records': [], 'pagination': {}, 'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }

    if (domainId.isEmpty) {
      return {'records': [], 'pagination': {}, 'error': '域名标识无效', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};
    }

    try {
      final Map<String, dynamic> options = {
        'page': page,
        'page_size': pageSize,
      };

      if (filters != null) {
        if (filters.containsKey('type')) {
          options['type'] = filters['type'];
        }
        if (filters.containsKey('line')) {
          options['line'] = filters['line'];
        }
        if (filters.containsKey('keyword')) {
          options['keyword'] = filters['keyword'];
        }
      }

      final response = await _client!.get(
        '/product/domain/$domainId/dns',
        queryParameters: {'options': jsonEncode(options)},
      );

      if (response.data == null) {
        return {'records': [], 'pagination': {}, 'error': '服务器无响应', 'errorCode': 'UNKNOWN', 'success': false};
      }

      var data = response.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          return {'records': [], 'pagination': {}, 'error': '响应解析失败', 'errorCode': 'PARSE_ERROR', 'success': false};
        }
      }

      if (data is Map) {
        final code = data['code'];
        if (code == 200 || code == '200') {
          final recordList = data['data'] as List? ?? [];
          final records = recordList.map((record) {
            return {
              'id': record['record_id']?.toString() ?? '',
              'record_id': record['record_id'],
              'name': record['host']?.toString() ?? '',
              'host': record['host']?.toString() ?? '',
              'type': record['type']?.toString() ?? 'A',
              'record_type': record['type']?.toString() ?? 'A',
              'content': record['value']?.toString() ?? '',
              'value': record['value']?.toString() ?? '',
              'ttl': record['ttl'] ?? 600,
              'level': record['level'] ?? 1,
              'priority': record['level'] ?? 1,
              'line': record['line']?.toString() ?? 'DEFAULT',
              'status': record['status']?.toString() ?? 'enabled',
              'enabled': record['status']?.toString() == 'enabled',
            };
          }).toList();

          final pagination = data['pagination'] as Map? ?? {};
          return {
            'records': records,
            'pagination': pagination,
            'success': true,
            'statusCode': 'OK',
            'total': recordList.length,
            'page': page,
            'pageSize': pageSize,
          };
        }

        return _parseError(data);
      }

      return {'records': [], 'pagination': {}, 'error': '响应数据格式异常', 'errorCode': 'PARSE_ERROR', 'success': false};
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
    if (_client == null) {
      return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }

    try {
      final data = _prepareDnsRecordData(recordData);

      final response = await _client!.post(
        '/product/domain/$domainId/dns',
        data: data,
      );

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

      if (respData is Map) {
        final code = respData['code'];
        if (code == 200 || code == '200') {
          return {'success': true, 'statusCode': 'OK', 'message': 'DNS 记录创建成功', 'data': respData['data']};
        }
        return _parseError(respData);
      }

      return {'error': '响应数据格式异常', 'errorCode': 'PARSE_ERROR', 'success': false};
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
    if (_client == null) {
      return {'error': '未初始化认证，请先添加账户', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }

    if (recordId.isEmpty) {
      return {'error': '记录标识无效', 'errorCode': 'INVALID_RECORD_ID', 'success': false};
    }

    try {
      final data = Map<String, dynamic>.from(recordData);
      data['record_id'] = int.tryParse(recordId) ?? recordId;

      final response = await _client!.patch(
        '/product/domain/$domainId/dns',
        data: data,
      );

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

      if (respData is Map) {
        final code = respData['code'];
        if (code == 200 || code == '200') {
          return {'success': true, 'statusCode': 'OK', 'message': 'DNS 记录更新成功', 'data': respData['data']};
        }
        return _parseError(respData);
      }

      return {'error': '响应数据格式异常', 'errorCode': 'PARSE_ERROR', 'success': false};
    } catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> deleteDnsRecord(String domainId, String recordId) async {
    if (_client == null) {
      return {'success': false, 'error': '未初始化认证', 'errorCode': 'AUTH_REQUIRED'};
    }
    if (domainId.isEmpty || recordId.isEmpty) {
      return {'success': false, 'error': '域名或记录标识无效', 'errorCode': 'INVALID_ID'};
    }

    try {
      final recordIdValue = int.tryParse(recordId) ?? recordId;
      final response = await _client!.dio.request(
        '/product/domain/$domainId/dns',
        data: {'record_id': recordIdValue},
        options: Options(method: 'DELETE'),
      );

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

      if (respData is Map) {
        final code = respData['code'];
        if (code == 200 || code == '200') {
          return {'success': true, 'statusCode': 'OK'};
        }
        return _parseError(respData);
      }

      return {'error': '响应数据格式异常', 'errorCode': 'PARSE_ERROR', 'success': false};
    } catch (e) {
      return {'error': _handleException(e), 'errorCode': 'NETWORK_ERROR', 'success': false};
    }
  }

  Map<String, dynamic> _prepareDnsRecordData(Map<String, dynamic> recordData) {
    final data = Map<String, dynamic>.from(recordData);

    if (data.containsKey('name')) {
      data['host'] = data['name'];
      data.remove('name');
    }

    if (data.containsKey('record_type')) {
      data['type'] = data['record_type'];
      data.remove('record_type');
    }

    if (data.containsKey('priority') && (data['priority'] == null || data['priority'] == 0)) {
      data.remove('priority');
    }

    if (data.containsKey('ttl') && (data['ttl'] == null || data['ttl'] == 0)) {
      data['ttl'] = 600;
    }

    if (data.containsKey('line') && (data['line'] == null || data['line'].toString().isEmpty)) {
      data['line'] = 'DEFAULT';
    }

    return data;
  }

  @override
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData) async {
    return {'error': '雨云暂不支持通过 API 添加域名', 'errorCode': 'NOT_SUPPORTED', 'success': false};
  }

  @override
  Future<Map<String, dynamic>> deleteDomain(String domainId) async {
    return {'error': '雨云暂不支持通过 API 删除域名', 'errorCode': 'NOT_SUPPORTED', 'success': false};
  }

  @override
  Future<Map<String, dynamic>> renewDomain(String domainId) async {
    return {'error': '雨云暂不支持通过 API 续期域名', 'errorCode': 'NOT_SUPPORTED', 'success': false};
  }

  @override
  bool get supportsAddDomain => false;

  @override
  bool get supportsDeleteDomain => false;

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
  }

  @override
  Widget buildDnsRecordListItem(Map<String, dynamic> recordData) {
    final name = recordData['host']?.toString() ?? recordData['name']?.toString() ?? '';
    final type = recordData['type']?.toString() ?? recordData['record_type']?.toString() ?? 'A';
    final content = recordData['value']?.toString() ?? recordData['content']?.toString() ?? '';
    final ttl = recordData['ttl'] as int? ?? 600;
    final level = recordData['level'] as int? ?? recordData['priority'] as int? ?? 1;
    final line = recordData['line']?.toString() ?? 'DEFAULT';
    final enabled = recordData['enabled'] == true || recordData['status']?.toString() == 'enabled';

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
                    Flexible(
                      child: Text(
                        name.isEmpty ? '@' : name,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (type == 'MX' || type == 'SRV') ...[
                      const SizedBox(width: 4),
                      Text(
                        'P$level',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DriverColorUtils.dnsTypeMX),
                      ),
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
                Text(
                  content,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RainyunTtlTag(ttl: ttl),
          if (line != 'DEFAULT') ...[
            const SizedBox(width: 4),
            _LineTag(line: line),
          ],
        ],
      ),
    );
  }

  @override
  Map<String, String> getCredentialFields() {
    return {'apiKey': 'API Key'};
  }

  @override
  List<String> getSupportedRecordTypes() {
    return ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'SRV'];
  }
}

class _RainyunTtlTag extends StatelessWidget {
  final int ttl;
  const _RainyunTtlTag({required this.ttl});

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

class _LineTag extends StatelessWidget {
  final String line;
  const _LineTag({required this.line});

  String get _label {
    switch (line) {
      case 'LTEL':
        return '电信';
      case 'LCNC':
        return '联通';
      case 'LMOB':
        return '移动';
      case 'LEDU':
        return '教育';
      case 'LSEO':
        return '搜索';
      case 'LFOR':
        return '国外';
      default:
        return line;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(_label, style: const TextStyle(fontSize: 9, color: Colors.blue)),
    );
  }
}