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

  ApiClient? _client;
  String? _apiToken;

  static const Map<int, String> _errorCodeMap = {
    10000: 'API Token 无效或已过期，请检查凭证后重试',
    10001: '缺少必要权限，请在 Cloudflare 控制台为 Token 添加对应权限',
    1000: '服务器未知错误，请稍后重试',
    1001: '请求格式无效，请检查输入参数',
    1002: '请求被禁止，无法访问此资源',
    1003: '账户不存在或无权访问',
    1004: '请求频率超限，请稍后重试',
    1005: '资源已存在，无需重复创建',
    1016: 'DNS 记录指向的源站 IP 无效',
    1020: '访问被拒绝，请稍后重试',
    7000: '域名/区域不存在，请检查域名是否正确',
    7001: '域名已存在，无需重复添加',
    7003: '域名不可用，可能正在初始化或已被暂停',
    9000: '账户已被暂停，请联系 Cloudflare 客服',
    9001: '账户已停用，请检查账户状态',
    9003: 'Token 已过期，请重新创建 API Token',
    9004: 'Token 未生效，请检查生效时间设置',
    9109: 'Unauthorized to access requested resource',
    9100: '权限不足，请在 Cloudflare 控制台为 Token 添加对应权限',
    9101: '权限不足，无法访问此资源',
    9200: '账户被暂停，请联系 Cloudflare 客服',
    9201: '账户被锁定，请联系 Cloudflare 客服',
    9400: '请求内容无效，请检查输入格式',
    9401: '缺少必需参数',
    9500: '服务器内部错误，请稍后重试',
    9600: '资源配额已达上限',
    9601: '请求被限制，请稍后重试',
  };

  static const Map<String, String> _errorMessageKeywords = {
    'authentication error': 'API Token 无效或已过期，请检查凭证后重试',
    'authorization error': '权限不足，请在 Cloudflare 控制台为 Token 添加对应权限',
    'forbidden': '权限不足，无法访问此资源',
    'unauthorized': 'Unauthorized to access requested resource',
    'not found': '请求的资源不存在',
    'zone not found': '域名/区域不存在，请检查域名是否正确',
    'dns_record not found': 'DNS 记录不存在',
    'rate limit': '请求频率超限，请稍后重试',
    'invalid': '请求参数无效，请检查输入格式',
    'missing': '缺少必需参数',
    'expired': 'Token 已过期，请重新创建 API Token',
    'suspended': '账户已被暂停，请联系 Cloudflare 客服',
    'duplicate': '资源已存在，无需重复创建',
    'already exists': '资源已存在，无需重复创建',
    'quota': '资源配额已达上限',
  };

  @override
  String get providerId => _providerId;

  @override
  String get providerName => _providerName;

  @override
  String get providerIcon => _providerIcon;

  @override
  String mapErrorCode(String code) {
    final intCode = int.tryParse(code);
    if (intCode != null && _errorCodeMap.containsKey(intCode)) {
      return _errorCodeMap[intCode]!;
    }
    final result = _getGenericErrorMessage(code);
    return result['error'] as String;
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

  Map<String, dynamic> _getGenericErrorMessage(String code) {
    if (code.isNotEmpty && code != '0') {
      return {
        'error': '操作失败，请稍后重试',
        'errorCode': code,
        'success': false
      };
    }
    return {
      'error': '未知错误，请稍后重试',
      'errorCode': 'UNKNOWN',
      'success': false
    };
  }

  Map<String, dynamic> _parseError(dynamic responseData) {
    if (responseData == null) {
      return {
        'error': '服务器无响应，请稍后重试',
        'errorCode': 'UNKNOWN',
        'success': false
      };
    }

    final data = responseData is Map ? responseData : <String, dynamic>{};
    final errors = data['errors'] as List?;

    if (errors != null && errors.isNotEmpty) {
      final error = errors[0] as Map?;
      if (error != null) {
        final code = error['code'];
        final message = error['message']?.toString() ?? '';
        final intCode = code is int ? code : int.tryParse(code?.toString() ?? '');

        String errorText;
        if (intCode != null && _errorCodeMap.containsKey(intCode)) {
          errorText = _errorCodeMap[intCode]!;
        } else if (message.isNotEmpty) {
          errorText = _mapMessageToHint(message);
        } else {
          errorText = '操作失败，请稍后重试';
        }

        return {
          'error': errorText,
          'errorCode': code?.toString() ?? 'UNKNOWN',
          'success': false,
          'rawMessage': message,
        };
      }
    }

    final messages = data['messages'] as List?;
    if (messages != null && messages.isNotEmpty) {
      final msg = (messages[0] as Map?)?['message']?.toString() ?? '';
      return {
        'error': msg.isNotEmpty ? _mapMessageToHint(msg) : '操作失败，请稍后重试',
        'errorCode': 'API_MESSAGE',
        'success': false,
        'rawMessage': msg,
      };
    }

    return {
      'error': '操作失败，请稍后重试',
      'errorCode': 'UNKNOWN',
      'success': false
    };
  }

  Map<String, dynamic> _parseDioException(Object e) {
    if (e is! DioException) {
      return {
        'error': '操作失败，请稍后重试',
        'errorCode': 'UNKNOWN',
        'success': false
      };
    }

    final response = e.response;
    if (response?.data != null) {
      final bodyResult = _parseError(response!.data);
      if (bodyResult['error'] != null) {
        return bodyResult;
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return {
          'error': '连接超时，请检查网络后重试',
          'errorCode': 'NETWORK_ERROR',
          'success': false
        };
      case DioExceptionType.receiveTimeout:
        return {
          'error': '服务器响应超时，请稍后重试',
          'errorCode': 'NETWORK_ERROR',
          'success': false
        };
      case DioExceptionType.connectionError:
        return {
          'error': '网络连接失败，请检查网络设置',
          'errorCode': 'NETWORK_ERROR',
          'success': false
        };
      case DioExceptionType.cancel:
        return {
          'error': '请求被取消',
          'errorCode': 'CANCELLED',
          'success': false
        };
      default:
        final statusCode = response?.statusCode;
        if (statusCode == 401) {
          return {
            'error': 'API Token 无效，请检查凭证',
            'errorCode': 'UNAUTHORIZED',
            'success': false
          };
        }
        if (statusCode == 403) {
          return {
            'error': '权限不足，无法访问此资源',
            'errorCode': 'FORBIDDEN',
            'success': false
          };
        }
        if (statusCode == 404) {
          return {
            'error': '请求的资源不存在',
            'errorCode': 'NOT_FOUND',
            'success': false
          };
        }
        if (statusCode == 429) {
          return {
            'error': '请求频率超限，请稍后重试',
            'errorCode': 'RATE_LIMIT',
            'success': false
          };
        }
        if (statusCode != null && statusCode >= 500) {
          return {
            'error': 'Cloudflare 服务器异常，请稍后重试',
            'errorCode': 'SERVER_ERROR',
            'success': false
          };
        }
        return {
          'error': '网络请求失败，请稍后重试',
          'errorCode': 'NETWORK_ERROR',
          'success': false
        };
    }
  }

  String _mapMessageToHint(String message) {
    if (message.isEmpty) return message;
    final lowerMsg = message.toLowerCase();
    for (final entry in _errorMessageKeywords.entries) {
      if (lowerMsg.contains(entry.key)) {
        return entry.value;
      }
    }
    const maxLen = 100;
    return message.length > maxLen ? message.substring(0, maxLen) : message;
  }

  ApiClient _getClient() {
    if (_client != null) return _client!;
    if (_apiToken == null) {
      throw StateError('Driver not initialized. Call validateCredential first.');
    }
    _client = ApiClient(
      baseUrl: AppConfig.cloudflareBaseUrl,
      headers: {
        'Authorization': 'Bearer $_apiToken',
        'Content-Type': 'application/json'
      },
      connectTimeout: AppConfig.connectionTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
    );
    return _client!;
  }

  @override
  Future<Map<String, dynamic>> validateCredential(Map<String, String> credentials) async {
    final apiToken = credentials['apiToken'];
    if (apiToken == null || apiToken.isEmpty) {
      return {'success': false, 'error': 'API Token 不能为空', 'errorCode': 'INVALID_CREDENTIAL'};
    }
    try {
      _apiToken = apiToken;
      _client = ApiClient(
        baseUrl: AppConfig.cloudflareBaseUrl,
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Content-Type': 'application/json'
        },
        connectTimeout: AppConfig.connectionTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
      );
      final response = await _client!.get('/user/tokens/verify');
      if (response.data == null) {
        _apiToken = null;
        _client = null;
        return {'success': false, 'error': '服务器无响应', 'errorCode': 'UNKNOWN'};
      }
      final data = response.data is Map ? response.data : <String, dynamic>{};
      if (data['success'] == true) return {'success': true};
      return _parseError(data);
    } catch (e) {
      final result = _parseDioException(e);
      _apiToken = null;
      _client = null;
      return result;
    }
  }

  @override
  Future<Map<String, dynamic>> getDomains({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    if (_apiToken == null) {
      return {
        'domains': [],
        'pagination': {},
        'error': '凭证未初始化，请重新添加账户',
        'errorCode': 'AUTH_REQUIRED',
        'success': false
      };
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
      if (response.data == null) {
        return {
          'domains': [],
          'pagination': {},
          'error': '服务器无响应',
          'errorCode': 'UNKNOWN',
          'success': false
        };
      }
      final data = response.data is Map ? response.data : <String, dynamic>{};
      if (data['success'] == true) {
        final result = data['result'] as List? ?? [];
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
        final pagination = data['result_info'] ?? <String, dynamic>{};
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
      return _parseError(data);
    } catch (e) {
      return _parseDioException(e);
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
        'error': '凭证未初始化，请重新添加账户',
        'errorCode': 'AUTH_REQUIRED',
        'success': false
      };
    }
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': pageSize,
      };
      if (filters != null) {
        queryParams.addAll(filters);
      }
      final response = await _getClient().get(
        '/zones/$domainId/dns_records',
        queryParameters: queryParams,
      );
      if (response.data == null) {
        return {
          'records': [],
          'pagination': {},
          'error': '服务器无响应',
          'errorCode': 'UNKNOWN',
          'success': false
        };
      }
      final data = response.data is Map ? response.data : <String, dynamic>{};
      if (data['success'] == true) {
        final result = data['result'] as List? ?? [];
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
        final pagination = data['result_info'] ?? <String, dynamic>{};
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
      return _parseError(data);
    } catch (e) {
      return {
        'records': [],
        'pagination': {},
        ..._parseDioException(e),
      };
    }
  }

  @override
  Future<Map<String, dynamic>> createDnsRecord(
    String domainId,
    Map<String, dynamic> recordData,
  ) async {
    if (_client == null) {
      return {
        'error': '凭证未初始化，请重新添加账户',
        'errorCode': 'AUTH_REQUIRED',
        'success': false
      };
    }
    try {
      final preparedData = _prepareDnsRecordData(recordData);
      final response = await _getClient().post(
        '/zones/$domainId/dns_records',
        data: preparedData,
      );
      if (response.data == null) {
        return {
          'error': '服务器无响应',
          'errorCode': 'UNKNOWN',
          'success': false
        };
      }
      final data = response.data is Map ? response.data : <String, dynamic>{};
      if (data['success'] == true) {
        return {
          'success': true,
          'statusCode': 'OK',
          'data': data['result']
        };
      }
      return _parseError(data);
    } catch (e) {
      return _parseDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateDnsRecord(
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
  ) async {
    if (_client == null) {
      return {
        'error': '凭证未初始化，请重新添加账户',
        'errorCode': 'AUTH_REQUIRED',
        'success': false
      };
    }
    try {
      final preparedData = _prepareDnsRecordData(recordData);
      final response = await _getClient().put(
        '/zones/$domainId/dns_records/$recordId',
        data: preparedData,
      );
      if (response.data == null) {
        return {
          'error': '服务器无响应',
          'errorCode': 'UNKNOWN',
          'success': false
        };
      }
      final data = response.data is Map ? response.data : <String, dynamic>{};
      if (data['success'] == true) {
        return {
          'success': true,
          'statusCode': 'OK',
          'data': data['result']
        };
      }
      return _parseError(data);
    } catch (e) {
      return _parseDioException(e);
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
      return {
        'success': false,
        'error': '凭证未初始化，请重新添加账户',
        'errorCode': 'AUTH_REQUIRED'
      };
    }
    try {
      final response = await _getClient().delete('/zones/$domainId/dns_records/$recordId');
      if (response.data == null) {
        return {
          'success': false,
          'error': '服务器无响应',
          'errorCode': 'UNKNOWN'
        };
      }
      final data = response.data is Map ? response.data : <String, dynamic>{};
      if (data['success'] == true) {
        return {'success': true, 'statusCode': 'OK'};
      }
      return _parseError(data);
    } catch (e) {
      return _parseDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData) async {
    if (_client == null) {
      return {
        'error': '凭证未初始化，请重新添加账户',
        'errorCode': 'AUTH_REQUIRED',
        'success': false
      };
    }
    try {
      final preparedData = {
        'name': domainData['name']?.toString() ?? '',
        'type': domainData['type']?.toString() ?? 'full',
      };
      if (domainData.containsKey('account') && domainData['account'] != null) {
        preparedData['account'] = domainData['account'];
      }
      final response = await _getClient().post('/zones', data: preparedData);
      if (response.data == null) {
        return {
          'error': '服务器无响应',
          'errorCode': 'UNKNOWN',
          'success': false
        };
      }
      final data = response.data is Map ? response.data : <String, dynamic>{};
      if (data['success'] == true) {
        final result = data['result'];
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
      return _parseError(data);
    } catch (e) {
      return _parseDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> deleteDomain(String domainId) async {
    if (_client == null) {
      return {
        'error': '凭证未初始化，请重新添加账户',
        'errorCode': 'AUTH_REQUIRED',
        'success': false
      };
    }
    if (domainId.isEmpty) {
      return {
        'error': '域名标识无效',
        'errorCode': 'INVALID_DOMAIN_ID',
        'success': false
      };
    }
    try {
      final response = await _getClient().delete('/zones/$domainId');
      if (response.data == null) {
        return {
          'error': '服务器无响应',
          'errorCode': 'UNKNOWN',
          'success': false
        };
      }
      final data = response.data is Map ? response.data : <String, dynamic>{};
      if (data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'message': '域名已删除'};
      }
      return _parseError(data);
    } catch (e) {
      return _parseDioException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> renewDomain(String domainId) async {
    return {
      'error': 'Cloudflare 不支持域名续期操作',
      'errorCode': 'NOT_SUPPORTED',
      'success': false
    };
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
  Widget buildDomainListItem(
    Map<String, dynamic> domainData, {
    required VoidCallback onTap,
    required VoidCallback onDelete,
    required VoidCallback onRenew,
    required bool supportsDelete,
    required bool supportsRenew,
  }) {
    return const SizedBox.shrink();
  }

  @override
  void showDomainListItemMenu(
    BuildContext context,
    Map<String, dynamic> domainData, {
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
            width: 44,
            height: 44,
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
      child: Text(
        _label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey),
      ),
    );
  }
}