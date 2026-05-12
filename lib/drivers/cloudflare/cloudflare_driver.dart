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
  static const String _baseUrl = AppConfig.cloudflareBaseUrl;
  static const int _maxMessageLen = 200;

  ApiClient? _client;
  String? _apiToken;

  @override
  String get providerId => _providerId;

  @override
  String get providerName => _providerName;

  @override
  String get providerIcon => _providerIcon;

  @override
  String mapErrorCode(String code) => '';

  @override
  String getAddDomainTitle() => '添加域名';

  @override
  List<AddDomainField> getAddDomainFields() => [
    const AddDomainField(key: 'name', label: '域名', hintText: '例如: example.com'),
  ];

  @override
  Map<String, dynamic> prepareDomainData(Map<String, dynamic> input) => {
    'name': input['name'] ?? input['rootdomain'] ?? '',
    'type': 'full',
  };

  ApiClient _getClient() {
    if (_client != null) return _client!;
    if (_apiToken == null) {
      throw StateError('Driver not initialized');
    }
    _client = _createClient();
    return _client!;
  }

  ApiClient _createClient() {
    return ApiClient(
      baseUrl: _baseUrl,
      headers: {
        'Authorization': 'Bearer $_apiToken',
        'Content-Type': 'application/json',
      },
      connectTimeout: AppConfig.connectionTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
    );
  }

  Map<String, dynamic> _parseResponse(dynamic data) {
    if (data == null) return {'error': 'Empty response', 'errorCode': 'EMPTY'};
    if (data is! Map) return {'error': 'Invalid response', 'errorCode': 'INVALID'};

    if (data['success'] == true) return {'success': true};

    final errors = data['errors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      final error = errors[0] as Map?;
      if (error != null) {
        final code = error['code']?.toString() ?? 'UNKNOWN';
        final message = error['message']?.toString() ?? '';
        final truncated = message.length > _maxMessageLen
            ? message.substring(0, _maxMessageLen)
            : message;
        return {'error': truncated, 'errorCode': code};
      }
    }

    final messages = data['messages'] as List?;
    if (messages != null && messages.isNotEmpty) {
      final msg = (messages[0] as Map?)?['message']?.toString() ?? '';
      if (msg.isNotEmpty) {
        final truncated = msg.length > _maxMessageLen
            ? msg.substring(0, _maxMessageLen)
            : msg;
        return {'error': truncated, 'errorCode': 'UNKNOWN'};
      }
    }

    return {'error': 'Unknown error', 'errorCode': 'UNKNOWN'};
  }

  Map<String, dynamic> _parseException(Object e) {
    if (e is! DioException) return {'error': 'Request failed', 'errorCode': 'UNKNOWN'};

    final responseData = e.response?.data;
    if (responseData != null) {
      final result = _parseResponse(responseData);
      if (result['error'] != 'Unknown error') return result;
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return {'error': 'Connection timeout', 'errorCode': 'TIMEOUT'};
      case DioExceptionType.receiveTimeout:
        return {'error': 'Response timeout', 'errorCode': 'TIMEOUT'};
      case DioExceptionType.connectionError:
        return {'error': 'Connection failed', 'errorCode': 'NETWORK'};
      case DioExceptionType.cancel:
        return {'error': 'Request cancelled', 'errorCode': 'CANCELLED'};
      default:
        return {'error': 'Request failed', 'errorCode': 'UNKNOWN'};
    }
  }

  @override
  Future<Map<String, dynamic>> validateCredential(Map<String, String> credentials) async {
    final apiToken = credentials['apiToken'];
    if (apiToken == null || apiToken.isEmpty) {
      return {'success': false, 'error': 'API Token cannot be empty', 'errorCode': 'EMPTY_TOKEN'};
    }

    try {
      _apiToken = apiToken;
      _client = _createClient();
      final response = await _client!.get('/user/tokens/verify');

      if (response.data == null) {
        _resetClient();
        return {'success': false, 'error': 'Empty response from server', 'errorCode': 'EMPTY_RESPONSE'};
      }

      final result = _parseResponse(response.data);
      if (result['success'] == true) return {'success': true};

      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    } catch (e) {
      final result = _parseException(e);
      _resetClient();
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    }
  }

  void _resetClient() {
    _apiToken = null;
    _client = null;
  }

  @override
  Future<Map<String, dynamic>> getDomains({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    if (_apiToken == null) {
      return {'domains': [], 'pagination': {}, 'error': '', 'errorCode': 'NOT_INITIALIZED'};
    }

    try {
      final queryParams = <String, dynamic>{'page': page, 'per_page': pageSize};
      if (filters != null) queryParams.addAll(filters);

      final response = await _getClient().get('/zones', queryParameters: queryParams);

      if (response.data == null) {
        return {'domains': [], 'pagination': {}, 'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE'};
      }

      final data = response.data as Map;
      if (data['success'] != true) {
        final result = _parseResponse(data);
        return {'domains': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
      }

      final result = data['result'] as List? ?? [];
      final domains = result.map(_parseZone).toList();
      final pagination = data['result_info'] ?? {};

      return {
        'domains': domains,
        'pagination': pagination,
        'success': true,
        'statusCode': 'OK',
        'total': pagination['total_count'] ?? result.length,
        'page': page,
        'pageSize': pageSize,
      };
    } catch (e) {
      final result = _parseException(e);
      return {'domains': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  Map<String, dynamic> _parseZone(dynamic zone) {
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
  }

  @override
  Future<Map<String, dynamic>> getDnsRecords(String domainId, {int page = 1, int pageSize = 20, Map<String, String>? filters}) async {
    if (_client == null) {
      return {'records': [], 'pagination': {}, 'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }

    try {
      final queryParams = <String, dynamic>{'page': page, 'per_page': pageSize};
      if (filters != null) queryParams.addAll(filters);

      final response = await _getClient().get('/zones/$domainId/dns_records', queryParameters: queryParams);

      if (response.data == null) {
        return {'records': [], 'pagination': {}, 'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE', 'success': false};
      }

      final data = response.data as Map;
      if (data['success'] != true) {
        final result = _parseResponse(data);
        return {'records': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
      }

      final result = data['result'] as List? ?? [];
      final records = result.map(_parseRecord).toList();
      final pagination = data['result_info'] ?? {};

      return {
        'records': records,
        'pagination': pagination,
        'success': true,
        'statusCode': 'OK',
        'total': pagination['total_count'] ?? result.length,
        'page': page,
        'pageSize': pageSize,
      };
    } catch (e) {
      final result = _parseException(e);
      return {'records': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  Map<String, dynamic> _parseRecord(dynamic record) => {
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

  @override
  Future<Map<String, dynamic>> createDnsRecord(String domainId, Map<String, dynamic> recordData) async {
    if (_client == null) {
      return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }

    try {
      final preparedData = _prepareDnsRecordData(recordData);
      final response = await _getClient().post('/zones/$domainId/dns_records', data: preparedData);

      if (response.data == null) {
        return {'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE', 'success': false};
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'data': data['result']};
      }

      final result = _parseResponse(data);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    } catch (e) {
      final result = _parseException(e);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> updateDnsRecord(String domainId, String recordId, Map<String, dynamic> recordData) async {
    if (_client == null) {
      return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }

    try {
      final preparedData = _prepareDnsRecordData(recordData);
      final response = await _getClient().put('/zones/$domainId/dns_records/$recordId', data: preparedData);

      if (response.data == null) {
        return {'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE', 'success': false};
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'data': data['result']};
      }

      final result = _parseResponse(data);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    } catch (e) {
      final result = _parseException(e);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  Map<String, dynamic> _prepareDnsRecordData(Map<String, dynamic> recordData) {
    final data = Map<String, dynamic>.from(recordData);
    final removeIfNull = (String key) {
      if (data.containsKey(key) && data[key] == null) data.remove(key);
    };
    removeIfNull('priority');
    removeIfNull('proxied');
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
      return {'success': false, 'error': '', 'errorCode': 'NOT_INITIALIZED'};
    }

    try {
      final response = await _getClient().delete('/zones/$domainId/dns_records/$recordId');

      if (response.data == null) {
        return {'success': false, 'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE'};
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return {'success': true, 'statusCode': 'OK'};
      }

      final result = _parseResponse(data);
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    } catch (e) {
      final result = _parseException(e);
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    }
  }

  @override
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData) async {
    if (_client == null) {
      return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
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
        return {'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE', 'success': false};
      }

      final data = response.data as Map;
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
          'message': '域名添加成功',
        };
      }

      final result = _parseResponse(data);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    } catch (e) {
      final result = _parseException(e);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> deleteDomain(String domainId) async {
    if (_client == null) {
      return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }

    if (domainId.isEmpty) {
      return {'error': 'Invalid domain identifier', 'errorCode': 'INVALID_ID', 'success': false};
    }

    try {
      final response = await _getClient().delete('/zones/$domainId');

      if (response.data == null) {
        return {'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE', 'success': false};
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'message': '域名已删除'};
      }

      final result = _parseResponse(data);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    } catch (e) {
      final result = _parseException(e);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> renewDomain(String domainId) async => 
    {'error': 'Renewal not supported for Cloudflare zones', 'errorCode': 'NOT_SUPPORTED', 'success': false};

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
  }) => const SizedBox.shrink();

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
    final renderBox = context.findRenderObject() as RenderBox;
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
        if (supportsDelete) const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Color(0xFFEF4444)))),
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
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭'))],
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
            decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(22)),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(type, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
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
            const Icon(Icons.cloud, size: 16, color: Color(0xFF3B82F6)),
          ],
        ],
      ),
    );
  }

  @override
  Map<String, String> getCredentialFields() => {'apiToken': 'API Token'};

  @override
  List<String> getSupportedRecordTypes() => ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SRV', 'CAA'];

  String _parseRegistrarType(String ownerType) {
    switch (ownerType.toLowerCase()) {
      case 'cloudflare': return 'Cloudflare Registrar';
      case 'apex': return 'Apex (Root)';
      case 'full': return 'Full DNS';
      case 'partial': return 'Partial DNS';
      case 'secondary': return 'Secondary DNS';
      default: return ownerType;
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
    child: Text(_label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey)),
  );
}