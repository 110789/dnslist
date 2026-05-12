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

  static const Map<int, String> _officialErrorCodeMap = {
    0: 'Permission denied',
    1000: 'Unknown error has occurred',
    1001: 'Invalid request',
    1002: 'Forbidden',
    1003: 'Account/Zone not found',
    1004: 'Invalid credentials',
    1005: 'Missing required parameters',
    1007: 'Invalid parameter value',
    1009: 'Resource already exists',
    1010: 'Resource not found',
    1011: 'Operation not permitted',
    1012: 'Rate limit exceeded',
    1013: 'Service temporarily unavailable',
    1018: 'Invalid API token',
    7003: 'Could not route to the requested path, perhaps your object identifier is invalid',
    9000: 'DNS name is invalid',
    9002: 'DNS record type is invalid',
    10000: 'Authentication required',
    10001: 'Invalid API token',
    10002: 'Token expired',
    10003: 'Token revoked',
    10004: 'Insufficient permissions',
    10005: 'Account suspended',
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
    if (intCode != null && _officialErrorCodeMap.containsKey(intCode)) {
      return _officialErrorCodeMap[intCode]!;
    }
    return code;
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

  String _parseError(dynamic responseData) {
    if (responseData == null) return '';
    final data = responseData is Map ? responseData : <String, dynamic>{};
    final success = data['success'];
    if (success != true) {
      final errors = data['errors'] as List?;
      if (errors != null && errors.isNotEmpty) {
        final error = errors[0] as Map?;
        if (error != null) {
          final code = error['code'];
          final message = error['message']?.toString() ?? '';
          final intCode = code is int ? code : int.tryParse(code?.toString() ?? '');
          if (intCode != null && _officialErrorCodeMap.containsKey(intCode)) {
            return _officialErrorCodeMap[intCode]!;
          }
          if (message.isNotEmpty) {
            const maxLen = 200;
            return message.length > maxLen ? message.substring(0, maxLen) : message;
          }
        }
      }
      final messages = data['messages'] as List?;
      if (messages != null && messages.isNotEmpty) {
        final msg = (messages[0] as Map?)?['message']?.toString() ?? '';
        if (msg.isNotEmpty) {
          const maxLen = 200;
          return msg.length > maxLen ? msg.substring(0, maxLen) : msg;
        }
      }
    }
    return '';
  }

  String _parseDioException(Object e) {
    if (e is! DioException) return '';
    final response = e.response;
    if (response?.data != null) {
      final bodyResult = _parseError(response!.data);
      if (bodyResult.isNotEmpty) return bodyResult;
    }
    final statusCode = response?.statusCode;
    if (statusCode == null) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
          return 'Connection timeout';
        case DioExceptionType.receiveTimeout:
          return 'Response timeout';
        case DioExceptionType.connectionError:
          return 'Connection failed';
        case DioExceptionType.cancel:
          return 'Request cancelled';
        default:
          return 'Request failed';
      }
    }
    if (statusCode == 401) return 'Unauthorized';
    if (statusCode == 403) return 'Permission denied';
    if (statusCode == 404) return 'Resource not found';
    if (statusCode == 405) return 'Method not allowed';
    if (statusCode == 429) return 'Rate limit exceeded';
    if (statusCode >= 500) return 'Server error ($statusCode)';
    return 'Request failed ($statusCode)';
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
      return {'success': false, 'error': 'API Token cannot be empty', 'errorCode': 'EMPTY_TOKEN'};
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
        return {'success': false, 'error': '', 'errorCode': 'EMPTY_RESPONSE'};
      }
      final data = response.data is Map ? response.data : <String, dynamic>{};
      if (data['success'] == true) return {'success': true};
      final err = _parseError(data);
      if (err.isNotEmpty) {
        return {'success': false, 'error': err, 'errorCode': _extractErrorCode(data)};
      }
      return {'success': false, 'error': '', 'errorCode': 'UNKNOWN'};
    } catch (e) {
      final result = _parseDioException(e);
      _apiToken = null;
      _client = null;
      return {'success': false, 'error': result, 'errorCode': _extractErrorCodeFromException(e)};
    }
  }

  String _extractErrorCode(dynamic data) {
    if (data == null || data is! Map) return 'UNKNOWN';
    final errors = data['errors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      final code = errors[0]['code'];
      if (code != null) return code.toString();
    }
    return 'UNKNOWN';
  }

  String _extractErrorCodeFromException(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      if (code != null) return code.toString();
    }
    return 'UNKNOWN';
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
        'error': '',
        'errorCode': 'NOT_INITIALIZED'
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
          'error': '',
          'errorCode': 'EMPTY_RESPONSE'
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
      final err = _parseError(data);
      return {
        'domains': [],
        'pagination': {},
        'error': err,
        'errorCode': _extractErrorCode(data),
        'success': false
      };
    } catch (e) {
      return {
        'domains': [],
        'pagination': {},
        'error': _parseDioException(e),
        'errorCode': _extractErrorCodeFromException(e),
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
        'error': '',
        'errorCode': 'NOT_INITIALIZED',
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
          'error': '',
          'errorCode': 'EMPTY_RESPONSE',
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
      final err = _parseError(data);
      return {
        'records': [],
        'pagination': {},
        'error': err,
        'errorCode': _extractErrorCode(data),
        'success': false
      };
    } catch (e) {
      return {
        'records': [],
        'pagination': {},
        'error': _parseDioException(e),
        'errorCode': _extractErrorCodeFromException(e),
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
      return {
        'error': '',
        'errorCode': 'NOT_INITIALIZED',
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
          'error': '',
          'errorCode': 'EMPTY_RESPONSE',
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
      final err = _parseError(data);
      return {
        'error': err,
        'errorCode': _extractErrorCode(data),
        'success': false
      };
    } catch (e) {
      return {
        'error': _parseDioException(e),
        'errorCode': _extractErrorCodeFromException(e),
        'success': false
      };
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
        'error': '',
        'errorCode': 'NOT_INITIALIZED',
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
          'error': '',
          'errorCode': 'EMPTY_RESPONSE',
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
      final err = _parseError(data);
      return {
        'error': err,
        'errorCode': _extractErrorCode(data),
        'success': false
      };
    } catch (e) {
      return {
        'error': _parseDioException(e),
        'errorCode': _extractErrorCodeFromException(e),
        'success': false
      };
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
        'error': '',
        'errorCode': 'NOT_INITIALIZED'
      };
    }
    try {
      final response = await _getClient().delete('/zones/$domainId/dns_records/$recordId');
      if (response.data == null) {
        return {
          'success': false,
          'error': '',
          'errorCode': 'EMPTY_RESPONSE'
        };
      }
      final data = response.data is Map ? response.data : <String, dynamic>{};
      if (data['success'] == true) {
        return {'success': true, 'statusCode': 'OK'};
      }
      final err = _parseError(data);
      return {
        'success': false,
        'error': err,
        'errorCode': _extractErrorCode(data)
      };
    } catch (e) {
      return {
        'success': false,
        'error': _parseDioException(e),
        'errorCode': _extractErrorCodeFromException(e)
      };
    }
  }

  @override
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData) async {
    if (_client == null) {
      return {
        'error': '',
        'errorCode': 'NOT_INITIALIZED',
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
          'error': '',
          'errorCode': 'EMPTY_RESPONSE',
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
      final err = _parseError(data);
      return {
        'error': err,
        'errorCode': _extractErrorCode(data),
        'success': false
      };
    } catch (e) {
      return {
        'error': _parseDioException(e),
        'errorCode': _extractErrorCodeFromException(e),
        'success': false
      };
    }
  }

  @override
  Future<Map<String, dynamic>> deleteDomain(String domainId) async {
    if (_client == null) {
      return {
        'error': '',
        'errorCode': 'NOT_INITIALIZED',
        'success': false
      };
    }
    if (domainId.isEmpty) {
      return {
        'error': 'Invalid domain identifier',
        'errorCode': 'INVALID_ID',
        'success': false
      };
    }
    try {
      final response = await _getClient().delete('/zones/$domainId');
      if (response.data == null) {
        return {
          'error': '',
          'errorCode': 'EMPTY_RESPONSE',
          'success': false
        };
      }
      final data = response.data is Map ? response.data : <String, dynamic>{};
      if (data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'message': '域名已删除'};
      }
      final err = _parseError(data);
      return {
        'error': err,
        'errorCode': _extractErrorCode(data),
        'success': false
      };
    } catch (e) {
      return {
        'error': _parseDioException(e),
        'errorCode': _extractErrorCodeFromException(e),
        'success': false
      };
    }
  }

  @override
  Future<Map<String, dynamic>> renewDomain(String domainId) async {
    return {
      'error': 'Renewal not supported for Cloudflare zones',
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