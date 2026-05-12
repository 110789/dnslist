import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../interfaces/driver_interface.dart';
import '../../utils/driver/driver_utils.dart';

class RainyunDriver implements DriverInterface {
  static const String _providerId = 'rainyun';
  static const String _providerName = '雨云';
  static const String _providerIcon = 'assets/icons/rainyun.svg';
  static const String _baseUrl = 'https://api.v2.rainyun.com';
  static const int _maxMessageLen = DriverConstants.maxMessageLen;
  static const int _connectionTimeout = 30000;
  static const int _receiveTimeout = 30000;

  Dio? _client;
  String? _apiKey;

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

  Dio _getClient() {
    if (_client != null) return _client!;
    if (_apiKey == null) throw StateError('Driver not initialized');
    _client = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: Duration(milliseconds: _connectionTimeout),
      receiveTimeout: Duration(milliseconds: _receiveTimeout),
      headers: {'X-Api-Key': _apiKey, 'Content-Type': 'application/json'},
    ));
    return _client!;
  }

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

    final code = parsed['code'];
    if (code == 200 || code == '200') return {'success': true};

    final errorCode = parsed['error_code']?.toString() ?? code?.toString() ?? 'UNKNOWN';
    final message = parsed['message']?.toString() ?? parsed['msg']?.toString() ?? '';

    if (message.isNotEmpty) {
      final truncated = message.length > _maxMessageLen ? message.substring(0, _maxMessageLen) : message;
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
    if (apiKey == null || apiKey.isEmpty) {
      return {'success': false, 'error': 'API Key cannot be empty', 'errorCode': 'INVALID_CREDENTIAL'};
    }

    try {
      final dio = Dio(BaseOptions(baseUrl: _baseUrl, connectTimeout: Duration(milliseconds: _connectionTimeout), receiveTimeout: Duration(milliseconds: _receiveTimeout), headers: {'X-Api-Key': apiKey, 'Content-Type': 'application/json'}, validateStatus: (status) => true));
      final response = await dio.get('/product/');

      if (response.data == null) {
        return {'success': false, 'error': 'Empty response from server', 'errorCode': 'EMPTY_RESPONSE'};
      }

      final result = _parseResponse(response.data);
      if (result['success'] == true) {
        _apiKey = apiKey;
        _client = dio;
        return {'success': true};
      }

      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    } catch (e) {
      final result = _parseException(e);
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    }
  }

  @override
  Future<Map<String, dynamic>> getDomains({int page = 1, int pageSize = 20, Map<String, String>? filters}) async {
    if (_client == null) return {'domains': [], 'pagination': {}, 'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};

    try {
      final options = <String, dynamic>{'page': page, 'page_size': pageSize};
      if (filters != null && filters.containsKey('keyword')) options['keyword'] = filters['keyword'];

      final response = await _getClient().get('/product/domain/', queryParameters: {'options': '{}'});

      if (response.data == null) return {'domains': [], 'pagination': {}, 'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE', 'success': false};

      final data = _parseResponseData(response.data);
      if (data == null) return {'domains': [], 'pagination': {}, 'error': 'Invalid response', 'errorCode': 'INVALID', 'success': false};

      final result = _parseResponse(data);
      if (result['success'] != true) return {'domains': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};

      final dataObj = data['data'] as Map? ?? {};
      final domainList = dataObj['Records'] as List? ?? [];
      final totalRecords = dataObj['TotalRecords'] as int? ?? 0;
      final domains = domainList.map(_parseDomain).toList();

      return {'domains': domains, 'pagination': {'total': totalRecords, 'page': page, 'pageSize': pageSize}, 'success': true, 'statusCode': 'OK', 'total': domains.length, 'page': page, 'pageSize': pageSize};
    } catch (e) {
      final result = _parseException(e);
      return {'domains': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  Map<String, dynamic> _parseDomain(dynamic zone) => {
    'id': zone['ID']?.toString() ?? zone['id']?.toString() ?? '',
    'name': zone['Domain']?.toString() ?? zone['domain']?.toString() ?? zone['Name']?.toString() ?? '',
    'domain': zone['Domain']?.toString() ?? zone['domain']?.toString() ?? zone['Name']?.toString() ?? '',
    'status': zone['Status']?.toString() ?? zone['status']?.toString() ?? 'active',
    'create_date': zone['CreateDate'] ?? zone['create_date'],
    'exp_date': zone['ExpDate'] ?? zone['exp_date'],
    'auto_renew': zone['AutoRenew'] ?? zone['auto_renew'] ?? false,
    'product': zone['Product']?.toString() ?? zone['product']?.toString() ?? 'domain',
  };

  @override
  Future<Map<String, dynamic>> getDnsRecords(String domainId, {int page = 1, int pageSize = 50, Map<String, String>? filters}) async {
    if (_client == null) return {'records': [], 'pagination': {}, 'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    if (domainId.isEmpty) return {'records': [], 'pagination': {}, 'error': 'Invalid domain ID', 'errorCode': 'INVALID_DOMAIN_ID', 'success': false};

    try {
      final options = <String, dynamic>{'page': page, 'page_size': pageSize};
      if (filters != null) {
        if (filters.containsKey('type')) options['type'] = filters['type'];
        if (filters.containsKey('line')) options['line'] = filters['line'];
        if (filters.containsKey('keyword')) options['keyword'] = filters['keyword'];
      }

      final response = await _getClient().get('/product/domain/$domainId/dns', queryParameters: {'options': jsonEncode(options)});

      if (response.data == null) return {'records': [], 'pagination': {}, 'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE', 'success': false};

      final data = _parseResponseData(response.data);
      if (data == null) return {'records': [], 'pagination': {}, 'error': 'Invalid response', 'errorCode': 'INVALID', 'success': false};

      final result = _parseResponse(data);
      if (result['success'] != true) return {'records': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};

      final recordList = data['data'] as List? ?? [];
      final records = recordList.map(_parseRecord).toList();

      return {'records': records, 'pagination': data['pagination'] ?? {}, 'success': true, 'statusCode': 'OK', 'total': recordList.length, 'page': page, 'pageSize': pageSize};
    } catch (e) {
      final result = _parseException(e);
      return {'records': [], 'pagination': {}, 'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  Map<String, dynamic> _parseRecord(dynamic record) => {
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

  @override
  Future<Map<String, dynamic>> createDnsRecord(String domainId, Map<String, dynamic> recordData) async {
    if (_client == null) return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};

    try {
      final data = _prepareDnsRecordData(recordData);
      final response = await _getClient().post('/product/domain/$domainId/dns', data: data);

      if (response.data == null) return {'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE', 'success': false};

      final dataParsed = _parseResponseData(response.data);
      if (dataParsed == null) return {'error': 'Invalid response', 'errorCode': 'INVALID', 'success': false};

      final result = _parseResponse(dataParsed);
      if (result['success'] == true) return {'success': true, 'statusCode': 'OK', 'message': 'DNS record created', 'data': dataParsed['data']};

      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    } catch (e) {
      final result = _parseException(e);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  @override
  Future<Map<String, dynamic>> updateDnsRecord(String domainId, String recordId, Map<String, dynamic> recordData) async {
    if (_client == null) return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    if (recordId.isEmpty) return {'error': 'Invalid record ID', 'errorCode': 'INVALID_RECORD_ID', 'success': false};

    try {
      final data = Map<String, dynamic>.from(recordData);
      data['record_id'] = int.tryParse(recordId) ?? recordId;
      final response = await _getClient().patch('/product/domain/$domainId/dns', data: data);

      if (response.data == null) return {'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE', 'success': false};

      final dataParsed = _parseResponseData(response.data);
      if (dataParsed == null) return {'error': 'Invalid response', 'errorCode': 'INVALID', 'success': false};

      final result = _parseResponse(dataParsed);
      if (result['success'] == true) return {'success': true, 'statusCode': 'OK', 'message': 'DNS record updated', 'data': dataParsed['data']};

      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    } catch (e) {
      final result = _parseException(e);
      return {'error': result['error'], 'errorCode': result['errorCode'], 'success': false};
    }
  }

  Map<String, dynamic> _prepareDnsRecordData(Map<String, dynamic> recordData) {
    final data = Map<String, dynamic>.from(recordData);
    if (data.containsKey('name')) { data['host'] = data['name']; data.remove('name'); }
    if (data.containsKey('record_type')) { data['type'] = data['record_type']; data.remove('record_type'); }
    if (data.containsKey('priority') && (data['priority'] == null || data['priority'] == 0)) data.remove('priority');
    if (data.containsKey('ttl') && (data['ttl'] == null || data['ttl'] == 0)) data['ttl'] = 600;
    if (data.containsKey('line') && (data['line'] == null || data['line'].toString().isEmpty)) data['line'] = 'DEFAULT';
    return data;
  }

  @override
  Future<Map<String, dynamic>> deleteDnsRecord(String domainId, String recordId) async {
    if (_client == null) return {'success': false, 'error': '', 'errorCode': 'NOT_INITIALIZED'};
    if (domainId.isEmpty || recordId.isEmpty) return {'success': false, 'error': 'Invalid ID', 'errorCode': 'INVALID_ID'};

    try {
      final recordIdValue = int.tryParse(recordId) ?? recordId;
      final response = await _getClient().delete('/product/domain/$domainId/dns', data: {'record_id': recordIdValue});

      if (response.data == null) return {'success': false, 'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE'};

      final dataParsed = _parseResponseData(response.data);
      if (dataParsed == null) return {'success': false, 'error': 'Invalid response', 'errorCode': 'INVALID'};

      final result = _parseResponse(dataParsed);
      if (result['success'] == true) return {'success': true, 'statusCode': 'OK'};

      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    } catch (e) {
      final result = _parseException(e);
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    }
  }

  @override
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData) async => 
    {'error': 'Not supported', 'errorCode': 'NOT_SUPPORTED', 'success': false};

  @override
  Future<Map<String, dynamic>> deleteDomain(String domainId) async => 
    {'error': 'Not supported', 'errorCode': 'NOT_SUPPORTED', 'success': false};

  @override
  Future<Map<String, dynamic>> renewDomain(String domainId) async => 
    {'error': 'Not supported', 'errorCode': 'NOT_SUPPORTED', 'success': false};

  @override
  bool get supportsAddDomain => false;

  @override
  bool get supportsDeleteDomain => false;

  @override
  bool get supportsRenewDomain => false;

  @override
  bool get supportsShowNameServers => false;

  @override
  Widget buildDomainListItem(Map<String, dynamic> domainData, {required VoidCallback onTap, required VoidCallback onDelete, required VoidCallback onRenew, required bool supportsDelete, required bool supportsRenew}) => const SizedBox.shrink();

  @override
  void showDomainListItemMenu(BuildContext context, Map<String, dynamic> domainData, {required VoidCallback onDelete, required VoidCallback onRenew, required VoidCallback onShowNameServers, required bool supportsDelete, required bool supportsRenew, required bool supportsShowNameServers}) {}

  @override
  Widget buildDnsRecordListItem(Map<String, dynamic> recordData) {
    final name = recordData['host']?.toString() ?? recordData['name']?.toString() ?? '';
    final type = recordData['type']?.toString() ?? recordData['record_type']?.toString() ?? 'A';
    final content = recordData['value']?.toString() ?? recordData['content']?.toString() ?? '';
    final ttl = recordData['ttl'] as int? ?? 600;
    final level = recordData['level'] as int? ?? recordData['priority'] as int? ?? 1;
    final line = recordData['line']?.toString() ?? 'DEFAULT';
    final enabled = recordData['enabled'] == true || recordData['status']?.toString() == 'enabled';
    final typeColor = DriverColorTokens.getDnsTypeColor(type);

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
                Row(
                  children: [
                    Flexible(child: Text(name.isEmpty ? '@' : name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (type == 'MX' || type == 'SRV') ...[const SizedBox(width: 4), Text('P$level', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DriverColorTokens.dnsTypeMX))],
                    if (!enabled) ...[const SizedBox(width: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2)), child: const Text('暂停', style: TextStyle(fontSize: 9, color: Colors.orange)))],
                  ],
                ),
                const SizedBox(height: 2),
                Text(content, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildTtlTag(ttl),
          if (line != 'DEFAULT') ...[const SizedBox(width: 4), _buildLineTag(line)],
        ],
      ),
    );
  }

  Widget _buildTtlTag(int ttl) {
    String label;
    if (ttl <= 0) {
      label = 'TTL: $ttl';
    } else if (ttl < 60) {
      label = 'TTL: ${ttl}s';
    } else if (ttl < 3600) {
      label = 'TTL: ${(ttl / 60).round()}m';
    } else if (ttl < 86400) {
      label = 'TTL: ${(ttl / 3600).round()}h';
    } else {
      label = 'TTL: ${(ttl / 86400).round()}d';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
      ),
    );
  }

  Widget _buildLineTag(String line) {
    String label;
    switch (line) {
      case 'LTEL': label = '电信'; break;
      case 'LCNC': label = '联通'; break;
      case 'LMOB': label = '移动'; break;
      case 'LEDU': label = '教育'; break;
      case 'LSEO': label = '搜索'; break;
      case 'LFOR': label = '国外'; break;
      default: label = line;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(label, style: const TextStyle(fontSize: 9, color: Colors.blue)),
    );
  }

  @override
  Map<String, String> getCredentialFields() => {'apiKey': 'API Key'};

  @override
  List<String> getSupportedRecordTypes() => ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'SRV'];
}