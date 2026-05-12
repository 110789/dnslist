import 'dart:convert';
import 'package:dio/dio.dart';
import '../../utils/driver/driver_utils.dart';
import 'core.dart';
import 'signer.dart';
import 'parser.dart';

class DnspodDns {
  final Dio _client;
  final String _secretId;
  final String _secretKey;

  DnspodDns(this._client, this._secretId, this._secretKey);

  Future<Map<String, dynamic>> getRecords(
    String domainId, {
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    if (domainId.isEmpty) {
      return _emptyResult(page, pageSize, 'Invalid domain ID', 'INVALID_DOMAIN_ID');
    }

    try {
      final domainIdInt = int.tryParse(domainId);
      final params = <String, dynamic>{
        'DomainId': domainIdInt ?? domainId,
        'Offset': (page - 1) * pageSize,
        'Limit': pageSize,
      };
      if (filters != null) {
        if (filters.containsKey('subdomain')) params['Subdomain'] = filters['subdomain'];
        if (filters.containsKey('record_type')) params['RecordType'] = filters['record_type'];
        if (filters.containsKey('record_line')) params['RecordLine'] = filters['record_line'];
        if (filters.containsKey('keyword')) params['Keyword'] = filters['keyword'];
      }

      final result = await _callApi('DescribeRecordList', params);
      if (result['success'] == true) {
        final data = Map<String, dynamic>.from(result['data'] as Map);
        final recordList = data['RecordList'] as List? ?? [];
        final countInfo = data['RecordCountInfo'] as Map? ?? {};
        final records = recordList.map(_parseRecord).toList();
        final total = countInfo['TotalCount'] ?? recordList.length;

        return {
          'records': records,
          'pagination': {'total': total, 'page': page, 'per_page': pageSize},
          'success': true,
          'statusCode': 'OK',
          'total': total,
          'page': page,
          'pageSize': pageSize,
        };
      }

      final error = DnspodParser.parseResponse(result['data'] ?? result);
      return _errorResult(error, page, pageSize);
    } catch (e) {
      final result = DnspodParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, page, pageSize);
    }
  }

  Future<Map<String, dynamic>> createRecord(
    String domainId,
    Map<String, dynamic> recordData,
  ) async {
    final domainIdInt = int.tryParse(domainId);
    final params = <String, dynamic>{'DomainId': domainIdInt ?? domainId};

    final recordType = recordData['type']?.toString()?.toUpperCase() ?? recordData['record_type']?.toString()?.toUpperCase();
    if (recordType != null) params['RecordType'] = recordType;

    final recordLine = recordData['line']?.toString() ?? recordData['record_line']?.toString();
    params['RecordLine'] = (recordLine != null && recordLine.isNotEmpty) ? recordLine : '默认';

    final value = recordData['content']?.toString() ?? recordData['value']?.toString() ?? '';
    if (value.isNotEmpty) params['Value'] = value;

    final subDomain = recordData['name']?.toString() ?? recordData['sub_domain']?.toString();
    params['SubDomain'] = (subDomain != null && subDomain.isNotEmpty) ? subDomain : '@';

    final ttl = recordData['ttl'];
    if (ttl != null && ttl > 0) params['TTL'] = ttl;

    final mx = recordData['mx'] ?? recordData['priority'];
    if (mx != null && mx > 0 && (recordType == 'MX' || recordType == 'SRV')) {
      params['MX'] = mx;
    }

    final weight = recordData['weight'];
    if (weight != null && weight > 0) params['Weight'] = weight;

    final status = recordData['status'];
    params['Status'] = (status != null && status.toString().toLowerCase() == 'disabled') ? 'DISABLE' : 'ENABLE';

    final remark = recordData['remark'];
    if (remark != null && remark.toString().isNotEmpty) params['Remark'] = remark.toString();

    try {
      final result = await _callApi('CreateRecord', params);
      if (result['success'] == true) {
        final data = Map<String, dynamic>.from(result['data'] as Map);
        return DnspodParser.parseSuccess(data: {
          'id': data['RecordId']?.toString() ?? '',
          'record_id': data['RecordId'],
        });
      }

      final error = DnspodParser.parseResponse(result['data'] ?? result);
      return _errorResult(error, 1, 20);
    } catch (e) {
      final result = DnspodParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Future<Map<String, dynamic>> updateRecord(
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
  ) async {
    final domainIdInt = int.tryParse(domainId);
    final recordIdInt = int.tryParse(recordId);
    final params = <String, dynamic>{
      'DomainId': domainIdInt ?? domainId,
      'RecordId': recordIdInt ?? recordId,
    };

    final recordType = recordData['type']?.toString()?.toUpperCase() ?? recordData['record_type']?.toString()?.toUpperCase();
    if (recordType != null) params['RecordType'] = recordType;

    final recordLine = recordData['line']?.toString() ?? recordData['record_line']?.toString();
    params['RecordLine'] = (recordLine != null && recordLine.isNotEmpty) ? recordLine : '默认';

    final value = recordData['content']?.toString() ?? recordData['value']?.toString() ?? '';
    if (value.isNotEmpty) params['Value'] = value;

    final subDomain = recordData['name']?.toString() ?? recordData['sub_domain']?.toString();
    params['SubDomain'] = (subDomain != null && subDomain.isNotEmpty) ? subDomain : '@';

    final ttl = recordData['ttl'];
    if (ttl != null && ttl > 0) params['TTL'] = ttl;

    final mx = recordData['mx'] ?? recordData['priority'];
    if (mx != null && mx > 0 && (recordType == 'MX' || recordType == 'SRV')) {
      params['MX'] = mx;
    }

    final weight = recordData['weight'];
    if (weight != null && weight > 0) params['Weight'] = weight;

    if (recordData.containsKey('status')) {
      params['Status'] = recordData['status'].toString().toLowerCase() == 'disabled' ? 'DISABLE' : 'ENABLE';
    }
    if (recordData.containsKey('remark')) {
      params['Remark'] = recordData['remark']?.toString() ?? '';
    }

    try {
      final result = await _callApi('ModifyRecord', params);
      if (result['success'] == true) {
        final data = Map<String, dynamic>.from(result['data'] as Map);
        return DnspodParser.parseSuccess(data: {
          'id': data['RecordId']?.toString() ?? recordId,
          'record_id': data['RecordId'] ?? recordIdInt,
        });
      }

      final error = DnspodParser.parseResponse(result['data'] ?? result);
      return _errorResult(error, 1, 20);
    } catch (e) {
      final result = DnspodParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Future<Map<String, dynamic>> deleteRecord(String domainId, String recordId) async {
    final domainIdInt = int.tryParse(domainId);
    final recordIdInt = int.tryParse(recordId);
    final params = <String, dynamic>{
      'DomainId': domainIdInt ?? domainId,
      'RecordId': recordIdInt ?? recordId,
    };

    try {
      final result = await _callApi('DeleteRecord', params);
      if (result['success'] == true) {
        return DnspodParser.parseSuccess();
      }

      final error = DnspodParser.parseResponse(result['data'] ?? result);
      return _errorResult(error, 1, 20);
    } catch (e) {
      final result = DnspodParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Future<Map<String, dynamic>> _callApi(String action, Map<String, dynamic> params) async {
    final headers = buildDnspodHeaders(
      secretId: _secretId,
      secretKey: _secretKey,
      action: action,
      payload: params,
    );
    _client.options.headers.addAll(headers);

    try {
      final response = await _client.post('', data: params);
      if (response.data == null) {
        return {'success': false, 'data': null};
      }

      final respData = response.data;
      if (respData is! Map) {
        try {
          final parsed = parseJson(respData.toString());
          if (parsed is Map) {
            return {'success': DnspodCore.isSuccessResponse(Map<String, dynamic>.from(parsed)), 'data': parsed};
          }
        } catch (_) {}
        return {'success': false, 'data': null};
      }
      return {'success': DnspodCore.isSuccessResponse(Map<String, dynamic>.from(respData)), 'data': respData};
    } on DioException catch (e) {
      return {'success': false, 'error': _handleException(e)};
    } catch (e) {
      return {'success': false, 'error': 'Operation failed'};
    }
  }

  String _handleException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout';
      case DioExceptionType.sendTimeout:
        return 'Request timeout';
      case DioExceptionType.connectionError:
        return 'Connection failed';
      default:
        return 'Request failed';
    }
  }

  Map<String, dynamic> _parseRecord(dynamic record) => {
    'id': record['RecordId']?.toString() ?? '',
    'record_id': record['RecordId'],
    'name': record['Name']?.toString() ?? '',
    'sub_domain': record['Name']?.toString() ?? '',
    'type': record['Type']?.toString() ?? 'A',
    'record_type': record['Type']?.toString() ?? 'A',
    'value': record['Value']?.toString() ?? '',
    'content': record['Value']?.toString() ?? '',
    'ttl': record['TTL'] ?? 600,
    'mx': record['MX'] ?? 0,
    'priority': record['MX'] ?? 0,
    'line': record['Line']?.toString() ?? '默认',
    'line_id': record['LineId']?.toString() ?? '0',
    'status': record['Status']?.toString()?.toLowerCase() == 'enable' ? 'active' : 'disabled',
    'enabled': record['Status']?.toString()?.toLowerCase() == 'enable',
    'weight': record['Weight'],
    'remark': record['Remark']?.toString() ?? '',
    'updated_on': record['UpdatedOn'],
    'created_on': record['UpdatedOn'],
    'monitor_status': record['MonitorStatus']?.toString() ?? '',
  };

  Map<String, dynamic> _emptyResult(int page, int pageSize, [String? error, String? errorCode]) => {
    'records': [],
    'pagination': {},
    'error': error ?? '',
    'errorCode': errorCode ?? 'EMPTY_RESPONSE',
    'success': false,
  };

  Map<String, dynamic> _errorResult(Map<String, dynamic> error, int page, int pageSize) => {
    'records': [],
    'pagination': {},
    'error': error['error'],
    'errorCode': error['errorCode'],
    'success': false,
  };
}