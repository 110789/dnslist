import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';
import 'core.dart';
import 'parser.dart';

class RainyunDns {
  final Dio _client;

  RainyunDns(this._client);

  Future<Map<String, dynamic>> getRecords(
    String domainId, {
    int page = 1,
    int pageSize = 50,
    Map<String, String>? filters,
  }) async {
    if (domainId.isEmpty) {
      return _emptyResult(page, pageSize, 'Invalid domain ID', 'INVALID_DOMAIN_ID');
    }

    try {
      final options = <String, dynamic>{'page': page, 'page_size': pageSize};
      if (filters != null) {
        if (filters.containsKey('type')) options['type'] = filters['type'];
        if (filters.containsKey('line')) options['line'] = filters['line'];
        if (filters.containsKey('keyword')) options['keyword'] = filters['keyword'];
      }

      final response = await _client.get('/product/domain/$domainId/dns', queryParameters: {'options': jsonEncode(options)});

      if (response.data == null) {
        return _emptyResult(page, pageSize);
      }

      final data = RainyunParser.parseResponseData(response.data);
      if (data == null) {
        return _errorResult(DriverResponseParser.parseInvalid(), page, pageSize);
      }

      final result = RainyunParser.parseResponse(data);
      if (result['success'] != true) {
        return _errorResult(result, page, pageSize);
      }

      final recordList = data['data'] as List? ?? [];
      final records = recordList.map(_parseRecord).toList();

      return {
        'records': records,
        'pagination': data['pagination'] ?? {},
        'success': true,
        'statusCode': 'OK',
        'total': recordList.length,
        'page': page,
        'pageSize': pageSize,
      };
    } catch (e) {
      final result = RainyunParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, page, pageSize);
    }
  }

  Future<Map<String, dynamic>> createRecord(String domainId, Map<String, dynamic> recordData) async {
    try {
      final data = _prepareRecordData(recordData);
      final response = await _client.post('/product/domain/$domainId/dns', data: data);

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final dataParsed = RainyunParser.parseResponseData(response.data);
      if (dataParsed == null) {
        return _errorResult(DriverResponseParser.parseInvalid(), 1, 20);
      }

      final result = RainyunParser.parseResponse(dataParsed);
      if (result['success'] == true) {
        return RainyunParser.parseSuccess(data: dataParsed['data'], message: 'DNS record created');
      }

      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = RainyunParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Future<Map<String, dynamic>> updateRecord(
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
  ) async {
    if (recordId.isEmpty) {
      return _errorResult(DriverResponseParser.parseError('Invalid record ID', 'INVALID_RECORD_ID'), 1, 20);
    }

    try {
      final data = Map<String, dynamic>.from(recordData);
      data['record_id'] = int.tryParse(recordId) ?? recordId;
      final response = await _client.patch('/product/domain/$domainId/dns', data: data);

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final dataParsed = RainyunParser.parseResponseData(response.data);
      if (dataParsed == null) {
        return _errorResult(DriverResponseParser.parseInvalid(), 1, 20);
      }

      final result = RainyunParser.parseResponse(dataParsed);
      if (result['success'] == true) {
        return RainyunParser.parseSuccess(data: dataParsed['data'], message: 'DNS record updated');
      }

      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = RainyunParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Future<Map<String, dynamic>> deleteRecord(String domainId, String recordId) async {
    if (domainId.isEmpty || recordId.isEmpty) {
      return _errorResult(DriverResponseParser.parseError('Invalid ID', 'INVALID_ID'), 1, 20);
    }

    try {
      final recordIdValue = int.tryParse(recordId) ?? recordId;
      final response = await _client.delete('/product/domain/$domainId/dns', data: {'record_id': recordIdValue});

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final dataParsed = RainyunParser.parseResponseData(response.data);
      if (dataParsed == null) {
        return _errorResult(DriverResponseParser.parseInvalid(), 1, 20);
      }

      final result = RainyunParser.parseResponse(dataParsed);
      if (result['success'] == true) {
        return RainyunParser.parseSuccess();
      }

      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = RainyunParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Map<String, dynamic> _prepareRecordData(Map<String, dynamic> recordData) {
    final data = Map<String, dynamic>.from(recordData);
    if (data.containsKey('name')) { data['host'] = data['name']; data.remove('name'); }
    if (data.containsKey('record_type')) { data['type'] = data['record_type']; data.remove('record_type'); }
    if (data.containsKey('priority') && (data['priority'] == null || data['priority'] == 0)) data.remove('priority');
    if (data.containsKey('ttl') && (data['ttl'] == null || data['ttl'] == 0)) data['ttl'] = 600;
    if (data.containsKey('line') && (data['line'] == null || data['line'].toString().isEmpty)) data['line'] = 'DEFAULT';
    return data;
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