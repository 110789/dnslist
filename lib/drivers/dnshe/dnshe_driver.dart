import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../interfaces/driver_interface.dart';
import '../../utils/network/api_client.dart';
import '../../utils/driver/driver_utils.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/design_system.dart';
import '../../core/ui/md3_widgets.dart';

class DnsheDriver implements DriverInterface {
  static const String _providerId = 'dnshe';
  static const String _providerName = 'DNSHE';
  static const String _providerIcon = 'assets/icons/dnshe.jpg';
  static const String _baseUrl = AppConfig.dnsheBaseUrl;
  static const int _maxMessageLen = DriverConstants.maxMessageLen;

  ApiClient? _client;
  String? _apiKey;
  String? _apiSecret;

  @override
  String get providerId => _providerId;

  @override
  String get providerName => _providerName;

  @override
  String get providerIcon => _providerIcon;

  @override
  String mapErrorCode(String code) => '';

  @override
  String getAddDomainTitle() => '添加子域名';

  @override
  List<AddDomainField> getAddDomainFields() => [
    const AddDomainField(key: 'subdomain', label: '子域名前缀', hintText: '例如: myapp'),
    const AddDomainField(key: 'rootdomain', label: '根域名', hintText: '例如: example.com', description: '将创建: {子域名}.{根域名}'),
  ];

  @override
  Map<String, dynamic> prepareDomainData(Map<String, dynamic> input) => {
    'subdomain': input['subdomain'] ?? '',
    'rootdomain': input['rootdomain'] ?? '',
  };

  ApiClient _getClient() {
    if (_client != null) return _client!;
    if (_apiKey == null || _apiSecret == null) {
      throw StateError('Driver not initialized');
    }
    _client = ApiClient(
      baseUrl: _baseUrl,
      headers: {'X-API-Key': _apiKey!, 'X-API-Secret': _apiSecret!},
    );
    return _client!;
  }

  Map<String, dynamic> _parseResponse(dynamic data) {
    if (data == null) return {'error': 'Empty response', 'errorCode': 'EMPTY'};
    if (data is! Map) return {'error': 'Invalid response', 'errorCode': 'INVALID'};

    if (data['success'] == true) return {'success': true};

    final errorCode = data['error_code']?.toString() ?? data['errorCode']?.toString() ?? 'UNKNOWN';
    final message = data['message']?.toString() ?? data['error']?.toString() ?? '';

    if (message.isNotEmpty) {
      final truncated = message.length > _maxMessageLen
          ? message.substring(0, _maxMessageLen)
          : message;
      return {'error': truncated, 'errorCode': errorCode};
    }

    return {'error': 'Unknown error', 'errorCode': errorCode};
  }

  Map<String, dynamic> _parseException(Object e) {
    final result = DioErrorParser.parse(e);
    if (result['errorCode'] != 'UNKNOWN') return result;

    if (e is! DioException) return result;
    final responseData = e.response?.data;
    if (responseData != null) {
      final parsed = _parseResponse(responseData);
      if (parsed['error'] != 'Unknown error') return parsed;
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>> validateCredential(Map<String, String> credentials) async {
    final apiKey = credentials['apiKey'];
    final apiSecret = credentials['apiSecret'];
    if (apiKey == null || apiKey.isEmpty || apiSecret == null || apiSecret.isEmpty) {
      return {'success': false, 'error': 'API Key or API Secret cannot be empty', 'errorCode': 'INVALID_CREDENTIAL'};
    }

    try {
      _apiKey = apiKey;
      _apiSecret = apiSecret;
      _client = ApiClient(baseUrl: _baseUrl, headers: {'X-API-Key': apiKey, 'X-API-Secret': apiSecret!});

      final response = await _client!.get('', queryParameters: {'m': 'domain_hub', 'endpoint': 'quota'});

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
    _apiKey = null;
    _apiSecret = null;
    _client = null;
  }

  @override
  Future<Map<String, dynamic>> getDomains({int page = 1, int pageSize = 20, Map<String, String>? filters}) async {
    if (_client == null) {
      return {'subdomains': [], 'pagination': {}, 'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
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
        if (filters.containsKey('name')) queryParams['search'] = filters['name'];
        if (filters.containsKey('rootdomain')) queryParams['rootdomain'] = filters['rootdomain'];
        if (filters.containsKey('status')) queryParams['status'] = filters['status'];
      }

      final response = await _getClient().get('', queryParameters: queryParams);

      if (response.data == null) {
        return {'subdomains': [], 'pagination': {}, 'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE', 'success': false};
      }

      final data = response.data as Map;
      if (data['success'] != true) {
        final result = _parseResponse(data);
        return {'subdomains': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
      }

      final subdomainsList = data['subdomains'] as List? ?? [];
      final subdomains = subdomainsList.map(_parseSubdomain).toList();
      final pagination = data['pagination'] ?? {'page': page, 'per_page': pageSize, 'total': subdomainsList.length};

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
    } catch (e) {
      final result = _parseException(e);
      return {'subdomains': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  Map<String, dynamic> _parseSubdomain(dynamic sub) => {
    'id': sub['id']?.toString() ?? '',
    'name': sub['full_domain']?.toString() ?? sub['subdomain']?.toString() ?? '',
    'subdomain': sub['subdomain']?.toString() ?? '',
    'rootdomain': sub['rootdomain']?.toString() ?? '',
    'status': sub['status']?.toString() ?? 'active',
    'created_at': sub['created_at'],
    'updated_at': sub['updated_at'],
    'expires_at': sub['expires_at'],
  };

  @override
  Future<Map<String, dynamic>> getDnsRecords(String domainId, {int page = 1, int pageSize = 20, Map<String, String>? filters}) async {
    if (_client == null) {
      return {'records': [], 'pagination': {}, 'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }

    if (domainId.isEmpty) {
      return {'records': [], 'pagination': {}, 'error': 'Invalid subdomain ID', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};
    }

    try {
      final queryParams = <String, dynamic>{
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'list',
        'subdomain_id': int.tryParse(domainId) ?? domainId,
      };

      final response = await _getClient().get('', queryParameters: queryParams);

      if (response.data == null) {
        return {'records': [], 'pagination': {}, 'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE', 'success': false};
      }

      final data = response.data as Map;
      if (data['success'] != true) {
        final result = _parseResponse(data);
        return {'records': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
      }

      final recordsList = data['records'] as List? ?? [];
      final records = recordsList.map(_parseRecord).toList();

      return {
        'records': records,
        'pagination': {'total': recordsList.length, 'page': 1, 'per_page': pageSize},
        'success': true,
        'statusCode': 'OK',
        'total': recordsList.length,
        'page': 1,
        'pageSize': pageSize,
      };
    } catch (e) {
      final result = _parseException(e);
      return {'records': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  Map<String, dynamic> _parseRecord(dynamic record) => {
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

  @override
  Future<Map<String, dynamic>> createDnsRecord(String domainId, Map<String, dynamic> recordData) async {
    if (_client == null) {
      return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }

    final subdomainId = int.tryParse(domainId) ?? 0;
    if (subdomainId <= 0) {
      return {'error': 'Invalid subdomain ID', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};
    }

    try {
      final bodyData = <String, dynamic>{'subdomain_id': subdomainId};
      if (recordData.containsKey('type')) bodyData['type'] = recordData['type'];
      if (recordData.containsKey('name')) bodyData['name'] = recordData['name'];
      if (recordData.containsKey('content')) bodyData['content'] = recordData['content'];
      if (recordData.containsKey('ttl') && recordData['ttl'] != null && recordData['ttl'] > 0) bodyData['ttl'] = recordData['ttl'];
      if (recordData.containsKey('priority') && recordData['priority'] != null && recordData['priority'] > 0) bodyData['priority'] = recordData['priority'];
      if (recordData.containsKey('line')) bodyData['line'] = recordData['line'];
      if (recordData.containsKey('proxied')) bodyData['proxied'] = recordData['proxied'] ?? false;

      final response = await _getClient().post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'create',
      }, data: bodyData);

      if (response.data == null) {
        return {'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE', 'success': false};
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'data': {'id': data['id']?.toString() ?? '', 'record_id': data['record_id']?.toString() ?? '', 'message': data['message'] ?? ''}};
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

    final recordIdInt = int.tryParse(recordId);
    if (recordIdInt == null || recordIdInt <= 0) {
      return {'error': 'Invalid record ID', 'errorCode': 'INVALID_RECORD_ID', 'success': false};
    }

    try {
      final bodyData = <String, dynamic>{'id': recordIdInt};
      if (recordData.containsKey('type')) bodyData['type'] = recordData['type'];
      if (recordData.containsKey('name')) bodyData['name'] = recordData['name'];
      if (recordData.containsKey('content')) bodyData['content'] = recordData['content'];
      if (recordData.containsKey('ttl') && recordData['ttl'] != null && recordData['ttl'] > 0) bodyData['ttl'] = recordData['ttl'];
      if (recordData.containsKey('priority') && recordData['priority'] != null && recordData['priority'] > 0) bodyData['priority'] = recordData['priority'];
      if (recordData.containsKey('proxied')) bodyData['proxied'] = recordData['proxied'];

      final response = await _getClient().post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'update',
      }, data: bodyData);

      if (response.data == null) {
        return {'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE', 'success': false};
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'data': {'id': data['id']?.toString() ?? recordId, 'record_id': data['record_id']?.toString() ?? '', 'message': data['message'] ?? ''}};
      }

      final result = _parseResponse(data);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    } catch (e) {
      final result = _parseException(e);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> deleteDnsRecord(String domainId, String recordId) async {
    if (_client == null) {
      return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }

    final recordIdInt = int.tryParse(recordId);
    if (recordIdInt == null || recordIdInt <= 0) {
      return {'error': 'Invalid record ID', 'errorCode': 'INVALID_RECORD_ID', 'success': false};
    }

    try {
      final response = await _getClient().post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'delete',
      }, data: {'id': recordIdInt});

      if (response.data == null) {
        return {'success': false, 'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE'};
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'message': 'DNS record deleted'};
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

    final subdomain = domainData['subdomain']?.toString().trim() ?? '';
    final rootdomain = domainData['rootdomain']?.toString().trim() ?? '';
    if (subdomain.isEmpty) {
      return {'error': 'Subdomain cannot be empty', 'errorCode': 'INVALID_SUBDOMAIN', 'success': false};
    }
    if (rootdomain.isEmpty) {
      return {'error': 'Root domain cannot be empty', 'errorCode': 'INVALID_ROOTDOMAIN', 'success': false};
    }

    try {
      final response = await _getClient().post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'subdomains',
        'action': 'register',
      }, data: {'subdomain': subdomain, 'rootdomain': rootdomain});

      if (response.data == null) {
        return {'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE', 'success': false};
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return {
          'success': true,
          'statusCode': 'OK',
          'data': {
            'id': data['subdomain_id']?.toString() ?? '',
            'name': data['full_domain']?.toString() ?? '$subdomain.$rootdomain',
            'subdomain': subdomain,
            'rootdomain': rootdomain,
          },
          'message': data['message'] ?? 'Subdomain registered',
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
      return {'error': 'Invalid subdomain ID', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};
    }

    final subdomainId = int.tryParse(domainId);
    if (subdomainId == null || subdomainId <= 0) {
      return {'error': 'Invalid subdomain ID', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};
    }

    try {
      final response = await _getClient().post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'subdomains',
        'action': 'delete',
      }, data: {'subdomain_id': subdomainId});

      if (response.data == null) {
        return {'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE', 'success': false};
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'message': data['message'] ?? 'Subdomain deleted', 'dns_records_deleted': data['dns_records_deleted'] ?? 0};
      }

      final result = _parseResponse(data);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    } catch (e) {
      final result = _parseException(e);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> renewDomain(String domainId) async {
    if (_client == null) return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    if (domainId.isEmpty) return {'error': 'Invalid subdomain ID', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};

    final subdomainId = int.tryParse(domainId);
    if (subdomainId == null || subdomainId <= 0) {
      return {'error': 'Invalid subdomain ID', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};
    }

    try {
      final response = await _getClient().post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'subdomains',
        'action': 'renew',
      }, data: {'subdomain_id': subdomainId});

      if (response.data == null) {
        return {'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE', 'success': false};
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return {
          'success': true,
          'statusCode': 'OK',
          'data': {
            'subdomain_id': data['subdomain_id'],
            'remaining_days': data['remaining_days'] ?? 365,
            'new_expires_at': data['new_expires_at'],
            'charged_amount': data['charged_amount'] ?? 0,
          },
          'message': data['message'] ?? 'Subdomain renewed',
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
  bool get supportsAddDomain => true;

  @override
  bool get supportsDeleteDomain => true;

  @override
  bool get supportsRenewDomain => true;

  @override
  bool get supportsShowNameServers => false;

  @override
  Widget buildDomainListItem(Map<String, dynamic> domainData, {required VoidCallback onTap, required VoidCallback onDelete, required VoidCallback onRenew, required bool supportsDelete, required bool supportsRenew}) =>
    const SizedBox.shrink();

  @override
  void showDomainListItemMenu(BuildContext context, Map<String, dynamic> domainData, {required VoidCallback onDelete, required VoidCallback onRenew, required VoidCallback onShowNameServers, required bool supportsDelete, required bool supportsRenew, required bool supportsShowNameServers}) {
    final renderBox = context.findRenderObject() as RenderBox;
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
    final typeColor = DnsDesignTokens.getDnsTypeColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(22)),
            child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(type, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)))),
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
                    if (priority != null) ...[const SizedBox(width: 4), Text('P$priority', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DnsDesignTokens.dnsTypeMX))],
                  ],
                ),
                const SizedBox(height: 2),
                Text(content, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DnsTtlTag(ttl: ttl),
          if (proxied) ...[const SizedBox(width: 4), const Icon(Icons.cloud, size: 16, color: DnsDesignTokens.dnsTypeA)],
        ],
      ),
    );
  }

  @override
  Map<String, String> getCredentialFields() => {'apiKey': 'API Key', 'apiSecret': 'API Secret'};

  @override
  List<String> getSupportedRecordTypes() => ['A', 'AAAA', 'CNAME', 'MX', 'TXT'];
}