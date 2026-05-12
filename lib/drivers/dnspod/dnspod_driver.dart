import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../interfaces/driver_interface.dart';
import '../driver_colors.dart';
import '../../utils/network/api_client.dart';
import '../../core/config/app_config.dart';
import 'dnspod_signer.dart';

class DnspodDriver implements DriverInterface {
  static const String _providerId = 'dnspod';
  static const String _providerName = 'DNSPod';
  static const String _providerIcon = 'assets/icons/dnspod.svg';
  static const String _baseUrl = AppConfig.dnspodBaseUrl;
  static const int _maxMessageLen = 200;

  String? _secretId;
  String? _secretKey;
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

    final response = parsed['Response'] as Map?;
    if (response == null) {
      if (parsed['status'] == 'success' || parsed['status'] == 0) return {'success': true};
      return {'error': 'Invalid response format', 'errorCode': 'INVALID'};
    }

    final error = response['Error'] as Map?;
    if (error != null) {
      final code = error['Code']?.toString() ?? 'UNKNOWN';
      final message = error['Message']?.toString() ?? '';
      if (message.isNotEmpty) {
        final truncated = message.length > _maxMessageLen ? message.substring(0, _maxMessageLen) : message;
        return {'error': truncated, 'errorCode': code};
      }
      return {'error': 'Unknown error', 'errorCode': code};
    }

    return {'success': true};
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

  ApiClient _getClient() {
    if (_client != null) return _client!;
    if (_secretId == null || _secretKey == null) throw StateError('Driver not initialized');
    _client = ApiClient(baseUrl: _baseUrl);
    return _client!;
  }

  @override
  Future<Map<String, dynamic>> validateCredential(Map<String, String> credentials) async {
    final secretId = credentials['secretId'];
    final secretKey = credentials['secretKey'];
    if (secretId == null || secretKey == null || secretId.isEmpty || secretKey.isEmpty) {
      return {'success': false, 'error': 'Secret ID or Secret Key cannot be empty', 'errorCode': 'INVALID_CREDENTIAL'};
    }

    try {
      _secretId = secretId;
      _secretKey = secretKey;
      _client = ApiClient(baseUrl: _baseUrl);

      final signer = DnspodSigner(secretId: secretId, secretKey: secretKey);
      final params = <String, dynamic>{'Action': 'DescribeDomainList', 'Version': '2021-03-23', 'Limit': 1, 'Offset': 0};
      final signed = signer.sign('GET', '/v1/Token/Validate', params);

      final response = await _getClient().get('/v1/Token/Validate', queryParameters: signed);

      final result = _parseResponse(response.data);
      if (result['success'] == true) return {'success': true};

      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    } catch (e) {
      final result = _parseException(e);
      _secretId = null;
      _secretKey = null;
      _client = null;
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    }
  }

  @override
  Future<Map<String, dynamic>> getDomains({int page = 1, int pageSize = 20, Map<String, String>? filters}) async {
    if (_client == null || _secretId == null) return {'domains': [], 'pagination': {}, 'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};

    try {
      final signer = DnspodSigner(secretId: _secretId!, secretKey: _secretKey!);
      final params = <String, dynamic>{
        'Action': 'DescribeDomainList',
        'Version': '2021-03-23',
        'Limit': pageSize,
        'Offset': (page - 1) * pageSize,
      };
      if (filters != null && filters.containsKey('keyword')) params['Keyword'] = filters['keyword'];

      final signed = signer.sign('GET', '/v1/Domain/List', params);
      final response = await _getClient().get('/v1/Domain/List', queryParameters: signed);

      final result = _parseResponse(response.data);
      if (result['success'] != true) return {'domains': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};

      final data = (response.data as Map?)?['Response'] as Map? ?? {};
      final domainList = data['DomainList'] as List? ?? [];
      final domains = domainList.map(_parseDomain).toList();

      return {
        'domains': domains,
        'pagination': {'page': page, 'per_page': pageSize, 'total': data['TotalCount'] ?? domainList.length},
        'success': true,
        'statusCode': 'OK',
        'total': domains.length,
        'page': page,
        'pageSize': pageSize,
      };
    } catch (e) {
      final result = _parseException(e);
      return {'domains': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  Map<String, dynamic> _parseDomain(dynamic domain) => {
    'id': domain['Id']?.toString() ?? domain['DomainId']?.toString() ?? '',
    'name': domain['Name']?.toString() ?? domain['Domain']?.toString() ?? '',
    'domain': domain['Name']?.toString() ?? domain['Domain']?.toString() ?? '',
    'status': domain['Status']?.toString() ?? 'enabled',
    'created_on': domain['CreatedOn'],
    'updated_on': domain['UpdatedOn'],
    'ttl': domain['TTL'],
    'cname_speed_status': domain['CnameSpeedStatus'],
    'dnspod_ns': domain['DnspodNS']?.toString(),
  };

  @override
  Future<Map<String, dynamic>> getDnsRecords(String domainId, {int page = 1, int pageSize = 50, Map<String, String>? filters}) async {
    if (_client == null || _secretId == null) return {'records': [], 'pagination': {}, 'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    if (domainId.isEmpty) return {'records': [], 'pagination': {}, 'error': 'Invalid domain ID', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};

    try {
      final signer = DnspodSigner(secretId: _secretId!, secretKey: _secretKey!);
      final params = <String, dynamic>{
        'Action': 'DescribeRecordList',
        'Version': '2021-03-23',
        'Domain': domainId,
        'Limit': pageSize,
        'Offset': (page - 1) * pageSize,
      };
      if (filters != null && filters.containsKey('type')) params['RecordType'] = filters['type'];
      if (filters != null && filters.containsKey('line')) params['RecordLine'] = filters['line'];

      final signed = signer.sign('GET', '/v1/Domain/Record/List', params);
      final response = await _getClient().get('/v1/Domain/Record/List', queryParameters: signed);

      final result = _parseResponse(response.data);
      if (result['success'] != true) return {'records': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};

      final data = (response.data as Map?)?['Response'] as Map? ?? {};
      final recordsList = data['RecordList'] as List? ?? [];
      final records = recordsList.map(_parseRecord).toList();

      return {
        'records': records,
        'pagination': {'page': page, 'per_page': pageSize, 'total': data['TotalCount'] ?? recordsList.length},
        'success': true,
        'statusCode': 'OK',
        'total': records.length,
        'page': page,
        'pageSize': pageSize,
      };
    } catch (e) {
      final result = _parseException(e);
      return {'records': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  Map<String, dynamic> _parseRecord(dynamic record) => {
    'id': record['Id']?.toString() ?? record['RecordId']?.toString() ?? '',
    'record_id': record['Id'] ?? record['RecordId'],
    'name': record['Name']?.toString() ?? '',
    'type': record['Type']?.toString() ?? 'A',
    'record_type': record['Type']?.toString() ?? 'A',
    'content': record['Value']?.toString() ?? '',
    'ttl': record['TTL'] ?? 600,
    'priority': record['Priority'],
    'line': record['Line']?.toString() ?? '默认',
    'status': record['Status']?.toString() ?? 'enabled',
    'weight': record['Weight'],
    'mx': record['MX'],
  };

  @override
  Future<Map<String, dynamic>> createDnsRecord(String domainId, Map<String, dynamic> recordData) async {
    if (_client == null || _secretId == null) return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    if (domainId.isEmpty) return {'error': 'Invalid domain ID', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};

    try {
      final signer = DnspodSigner(secretId: _secretId!, secretKey: _secretKey!);
      final params = <String, dynamic>{
        'Action': 'CreateRecord',
        'Version': '2021-03-23',
        'Domain': domainId,
      };
      if (recordData.containsKey('sub_domain')) params['SubDomain'] = recordData['sub_domain'];
      if (recordData.containsKey('record_type')) params['RecordType'] = recordData['record_type'];
      if (recordData.containsKey('record_line')) params['RecordLine'] = recordData['record_line'];
      if (recordData.containsKey('value')) params['Value'] = recordData['value'];
      if (recordData.containsKey('ttl') && recordData['ttl'] != null) params['TTL'] = recordData['ttl'];
      if (recordData.containsKey('priority') && recordData['priority'] != null) params['Priority'] = recordData['priority'];
      if (recordData.containsKey('weight') && recordData['weight'] != null) params['Weight'] = recordData['weight'];

      final signed = signer.sign('POST', '/v1/Domain/Record/Create', params);
      final response = await _getClient().post('/v1/Domain/Record/Create', data: signed);

      final result = _parseResponse(response.data);
      if (result['success'] == true) {
        final data = (response.data as Map?)?['Response'] as Map? ?? {};
        return {'success': true, 'statusCode': 'OK', 'data': {'id': data['RecordId']?.toString() ?? ''}};
      }

      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    } catch (e) {
      final result = _parseException(e);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> updateDnsRecord(String domainId, String recordId, Map<String, dynamic> recordData) async {
    if (_client == null || _secretId == null) return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    if (domainId.isEmpty || recordId.isEmpty) return {'error': 'Invalid ID', 'errorCode': 'INVALID_ID', 'success': false};

    try {
      final signer = DnspodSigner(secretId: _secretId!, secretKey: _secretKey!);
      final params = <String, dynamic>{
        'Action': 'ModifyRecord',
        'Version': '2021-03-23',
        'Domain': domainId,
        'RecordId': recordId,
      };
      if (recordData.containsKey('sub_domain')) params['SubDomain'] = recordData['sub_domain'];
      if (recordData.containsKey('record_type')) params['RecordType'] = recordData['record_type'];
      if (recordData.containsKey('record_line')) params['RecordLine'] = recordData['record_line'];
      if (recordData.containsKey('value')) params['Value'] = recordData['value'];
      if (recordData.containsKey('ttl') && recordData['ttl'] != null) params['TTL'] = recordData['ttl'];
      if (recordData.containsKey('priority') && recordData['priority'] != null) params['Priority'] = recordData['priority'];

      final signed = signer.sign('POST', '/v1/Domain/Record/Modify', params);
      final response = await _getClient().post('/v1/Domain/Record/Modify', data: signed);

      final result = _parseResponse(response.data);
      if (result['success'] == true) return {'success': true, 'statusCode': 'OK'};

      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    } catch (e) {
      final result = _parseException(e);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> deleteDnsRecord(String domainId, String recordId) async {
    if (_client == null || _secretId == null) return {'success': false, 'error': '', 'errorCode': 'NOT_INITIALIZED'};
    if (domainId.isEmpty || recordId.isEmpty) return {'success': false, 'error': 'Invalid ID', 'errorCode': 'INVALID_ID'};

    try {
      final signer = DnspodSigner(secretId: _secretId!, secretKey: _secretKey!);
      final params = <String, dynamic>{
        'Action': 'DeleteRecord',
        'Version': '2021-03-23',
        'Domain': domainId,
        'RecordId': recordId,
      };

      final signed = signer.sign('POST', '/v1/Domain/Record/Delete', params);
      final response = await _getClient().post('/v1/Domain/Record/Delete', data: signed);

      final result = _parseResponse(response.data);
      if (result['success'] == true) return {'success': true, 'statusCode': 'OK'};

      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    } catch (e) {
      final result = _parseException(e);
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    }
  }

  @override
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData) async {
    if (_client == null || _secretId == null) return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};

    final domain = domainData['domain']?.toString() ?? domainData['name']?.toString() ?? '';
    if (domain.isEmpty) return {'error': 'Domain cannot be empty', 'errorCode': 'INVALID_DOMAIN', 'success': false};

    try {
      final signer = DnspodSigner(secretId: _secretId!, secretKey: _secretKey!);
      final params = <String, dynamic>{
        'Action': 'CreateDomain',
        'Version': '2021-03-23',
        'Domain': domain,
      };

      final signed = signer.sign('POST', '/v1/Domain/Create', params);
      final response = await _getClient().post('/v1/Domain/Create', data: signed);

      final result = _parseResponse(response.data);
      if (result['success'] == true) {
        final data = (response.data as Map?)?['Response'] as Map? ?? {};
        return {'success': true, 'statusCode': 'OK', 'data': {'id': data['DomainId']?.toString() ?? '', 'name': domain}};
      }

      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    } catch (e) {
      final result = _parseException(e);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> deleteDomain(String domainId) async {
    if (_client == null || _secretId == null) return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    if (domainId.isEmpty) return {'error': 'Invalid domain', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};

    try {
      final signer = DnspodSigner(secretId: _secretId!, secretKey: _secretKey!);
      final params = <String, dynamic>{
        'Action': 'DeleteDomain',
        'Version': '2021-03-23',
        'Domain': domainId,
      };

      final signed = signer.sign('POST', '/v1/Domain/Delete', params);
      final response = await _getClient().post('/v1/Domain/Delete', data: signed);

      final result = _parseResponse(response.data);
      if (result['success'] == true) return {'success': true, 'statusCode': 'OK'};

      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    } catch (e) {
      final result = _parseException(e);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
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
    final name = recordData['name']?.toString() ?? '';
    final type = recordData['type']?.toString() ?? 'A';
    final content = recordData['content']?.toString() ?? '';
    final ttl = recordData['ttl'] as int? ?? 600;
    final typeColor = DriverColorUtils.getDnsTypeColor(type);

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
                Text(name.isEmpty ? '@' : '$name', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
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
  Map<String, String> getCredentialFields() => {'secretId': 'Secret ID', 'secretKey': 'Secret Key'};

  @override
  List<String> getSupportedRecordTypes() => ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SRV', 'CAA', 'URL', 'FRAME'];
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
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)), child: Text(_label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey)));
}