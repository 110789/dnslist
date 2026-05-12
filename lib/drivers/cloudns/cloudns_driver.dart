import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../interfaces/driver_interface.dart';
import '../../utils/network/api_client.dart';
import '../../utils/driver/driver_utils.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/design_system.dart';
import '../../core/ui/md3_widgets.dart';

class ClouDNSDriver implements DriverInterface {
  static const String _providerId = 'cloudns';
  static const String _providerName = 'ClouDNS';
  static const String _providerIcon = 'assets/icons/cloudns.svg';
  static const String _baseUrl = AppConfig.cloudnsBaseUrl;
  static const int _maxMessageLen = DriverConstants.maxMessageLen;

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
  String mapErrorCode(String code) => '';

  @override
  String getAddDomainTitle() => '添加域名';

  @override
  List<AddDomainField> getAddDomainFields() => [
    const AddDomainField(key: 'domain', label: '域名', hintText: '例如: example.com', description: '输入要添加的域名'),
  ];

  @override
  Map<String, dynamic> prepareDomainData(Map<String, dynamic> input) => {'domain': input['domain'] ?? input['name'] ?? ''};

  dynamic _parseResponseData(dynamic data) {
    if (data is String) {
      try {
        return jsonDecode(data);
      } catch (_) {
        return null;
      }
    }
    return data;
  }

  Map<String, dynamic> _parseResponse(dynamic data) {
    final parsed = _parseResponseData(data);
    if (parsed == null) return {'error': 'Empty response', 'errorCode': 'EMPTY'};
    if (parsed is! Map) return {'error': 'Invalid response', 'errorCode': 'INVALID'};

    final status = parsed['status']?.toString();
    if (status == 'Success') return {'success': true};

    final message = parsed['statusDescription']?.toString() ?? '';
    if (message.isNotEmpty) {
      final truncated = message.length > _maxMessageLen ? message.substring(0, _maxMessageLen) : message;
      return {'error': truncated, 'errorCode': message};
    }

    return {'error': 'Unknown error', 'errorCode': 'UNKNOWN'};
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

  Future<Map<String, dynamic>> _callApi(String action, Map<String, dynamic> params) async {
    if (_authId == null || _authPassword == null) return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};

    try {
      final queryParams = <String, dynamic>{'auth-id': _authId, 'auth-password': _authPassword, ...params};
      final response = await Dio(BaseOptions(baseUrl: _baseUrl, connectTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 30))).get('/$action', queryParameters: queryParams);

      if (response.data == null) return {'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE', 'success': false};

      final result = _parseResponse(response.data);
      if (result['success'] == true) return {'success': true, 'statusCode': 'OK', 'data': response.data};

      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    } catch (e) {
      return _parseException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> validateCredential(Map<String, String> credentials) async {
    final authId = credentials['authId'];
    final authPassword = credentials['authPassword'];
    if (authId == null || authPassword == null || authId.isEmpty || authPassword.isEmpty) {
      return {'success': false, 'error': 'Auth ID or password cannot be empty', 'errorCode': 'INVALID_CREDENTIAL'};
    }

    try {
      _authId = int.tryParse(authId);
      _authPassword = authPassword;
      if (_authId == null) {
        return {'success': false, 'error': 'Invalid auth ID format', 'errorCode': 'INVALID_CREDENTIAL'};
      }
      return await _callApi('get-balance.json', {});
    } catch (e) {
      final result = _parseException(e);
      _authId = null;
      _authPassword = null;
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    }
  }

  @override
  Future<Map<String, dynamic>> getDomains({int page = 1, int pageSize = 20, Map<String, String>? filters}) async {
    final result = await _callApi('dns/list-zones.json', {'page': page.toString(), 'rows-per-page': pageSize.toString()});
    if (result['success'] != true) {
      final parsed = _parseResponseData(result['data']);
      return {'domains': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }

    final data = result['data'] as Map? ?? {};
    final zones = data['zones'] as List? ?? [];
    final domains = zones.map(_parseZone).toList();

    return {'domains': domains, 'pagination': {'page': page, 'per_page': pageSize, 'total': zones.length}, 'success': true, 'statusCode': 'OK', 'total': domains.length, 'page': page, 'pageSize': pageSize};
  }

  Map<String, dynamic> _parseZone(dynamic zone) => {
    'id': zone['id']?.toString() ?? '',
    'name': zone['domain']?.toString() ?? '',
    'domain': zone['domain']?.toString() ?? '',
    'status': zone['status']?.toString() ?? 'active',
    'created': zone['create_date'],
    'expire': zone['expire_date'],
  };

  @override
  Future<Map<String, dynamic>> getDnsRecords(String domainId, {int page = 1, int pageSize = 50, Map<String, String>? filters}) async {
    if (domainId.isEmpty) return {'records': [], 'pagination': {}, 'error': 'Invalid domain', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};

    final params = <String, dynamic>{'domain-name': domainId};
    if (filters != null && filters.containsKey('type')) params['type'] = filters['type'];

    final result = await _callApi('dns/records.json', params);
    if (result['success'] != true) {
      return {'records': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }

    final data = result['data'] as Map? ?? {};
    final recordsList = data['records'] as List? ?? [];
    final records = recordsList.map(_parseRecord).toList();

    return {'records': records, 'pagination': {'total': recordsList.length, 'page': 1, 'per_page': pageSize}, 'success': true, 'statusCode': 'OK', 'total': recordsList.length, 'page': 1, 'pageSize': pageSize};
  }

  Map<String, dynamic> _parseRecord(dynamic record) => {
    'id': record['id']?.toString() ?? '',
    'record_id': record['id'],
    'name': record['host']?.toString() ?? '',
    'type': record['type']?.toString() ?? 'A',
    'record_type': record['type']?.toString() ?? 'A',
    'content': record['record']?.toString() ?? '',
    'ttl': record['ttl'] ?? 3600,
    'priority': record['priority'],
    'status': record['status']?.toString() ?? 'active',
  };

  @override
  Future<Map<String, dynamic>> createDnsRecord(String domainId, Map<String, dynamic> recordData) async {
    if (domainId.isEmpty) return {'error': 'Invalid domain', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};

    final params = <String, dynamic>{'domain-name': domainId};
    if (recordData.containsKey('type')) params['record-type'] = recordData['type'];
    if (recordData.containsKey('host')) params['host'] = recordData['host'];
    if (recordData.containsKey('record')) params['record'] = recordData['record'];
    if (recordData.containsKey('ttl') && recordData['ttl'] != null) params['ttl'] = recordData['ttl'];
    if (recordData.containsKey('priority') && recordData['priority'] != null) params['priority'] = recordData['priority'];

    return await _callApi('dns/add-record.json', params);
  }

  @override
  Future<Map<String, dynamic>> updateDnsRecord(String domainId, String recordId, Map<String, dynamic> recordData) async {
    if (domainId.isEmpty || recordId.isEmpty) return {'error': 'Invalid ID', 'errorCode': 'INVALID_ID', 'success': false};

    final params = <String, dynamic>{'domain-name': domainId, 'record-id': recordId};
    if (recordData.containsKey('host')) params['host'] = recordData['host'];
    if (recordData.containsKey('record')) params['record'] = recordData['record'];
    if (recordData.containsKey('ttl') && recordData['ttl'] != null) params['ttl'] = recordData['ttl'];
    if (recordData.containsKey('priority') && recordData['priority'] != null) params['priority'] = recordData['priority'];

    return await _callApi('dns/mod-record.json', params);
  }

  @override
  Future<Map<String, dynamic>> deleteDnsRecord(String domainId, String recordId) async {
    if (domainId.isEmpty || recordId.isEmpty) return {'success': false, 'error': 'Invalid ID', 'errorCode': 'INVALID_ID'};

    return await _callApi('dns/delete-record.json', {'domain-name': domainId, 'record-id': recordId});
  }

  @override
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData) async {
    final domain = domainData['domain']?.toString() ?? domainData['name']?.toString() ?? '';
    if (domain.isEmpty) return {'error': 'Domain cannot be empty', 'errorCode': 'INVALID_DOMAIN', 'success': false};

    return await _callApi('dns/register.json', {'domain-name': domain});
  }

  @override
  Future<Map<String, dynamic>> deleteDomain(String domainId) async {
    if (domainId.isEmpty) return {'error': 'Invalid domain', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};

    return await _callApi('dns/delete.json', {'domain-name': domainId});
  }

  @override
  Future<Map<String, dynamic>> renewDomain(String domainId) async => 
    {'error': 'Not supported', 'errorCode': 'NOT_SUPPORTED', 'success': false};

  @override
  bool get supportsAddDomain => true;

  @override
  bool get supportsDeleteDomain => true;

  @override
  bool get supportsRenewDomain => false;

  @override
  bool get supportsShowNameServers => false;

  @override
  Widget buildDomainListItem(Map<String, dynamic> domainData, {required VoidCallback onTap, required VoidCallback onDelete, required VoidCallback onRenew, required bool supportsDelete, required bool supportsRenew}) => const SizedBox.shrink();

  @override
  void showDomainListItemMenu(BuildContext context, Map<String, dynamic> domainData, {required VoidCallback onDelete, required VoidCallback onRenew, required VoidCallback onShowNameServers, required bool supportsDelete, required bool supportsRenew, required bool supportsShowNameServers}) {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(offset.dx + renderBox.size.width / 2, offset.dy + renderBox.size.height / 2, offset.dx + renderBox.size.width, offset.dy + renderBox.size.height),
      items: [if (supportsDelete) const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Color(0xFFEF4444))))],
    ).then((value) { if (value == 'delete') onDelete(); });
  }

  @override
  Widget buildDnsRecordListItem(Map<String, dynamic> recordData) {
    final name = recordData['host']?.toString() ?? '';
    final type = recordData['type']?.toString() ?? 'A';
    final content = recordData['record']?.toString() ?? recordData['content']?.toString() ?? '';
    final ttl = recordData['ttl'] as int? ?? 3600;
    final typeColor = DnsDesignTokens.getDnsTypeColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(22)), child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(type, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name.isEmpty ? '@' : name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(content, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DnsTtlTag(ttl: ttl),
        ],
      ),
    );
  }

  @override
  Map<String, String> getCredentialFields() => {'authId': 'Auth ID', 'authPassword': 'Auth Password'};

  @override
  List<String> getSupportedRecordTypes() => ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SRV', 'SPF', 'CAA'];
}