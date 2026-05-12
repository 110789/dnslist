import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';
import 'core.dart';
import 'parser.dart';

class CloudnsDns {
  final Dio _client;
  final int _authId;
  final String _authPassword;

  CloudnsDns(this._client, this._authId, this._authPassword);

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
      final params = <String, dynamic>{
        'domain-name': domainId,
        'auth-id': _authId,
        'auth-password': _authPassword,
      };
      if (filters != null && filters.containsKey('type')) params['type'] = filters['type'];

      final response = await _client.get('/dns/records.json', queryParameters: params);

      if (response.data == null) {
        return _emptyResult(page, pageSize);
      }

      final data = response.data as Map? ?? {};
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
      final result = CloudnsParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, page, pageSize);
    }
  }

  Future<Map<String, dynamic>> createRecord(String domainId, Map<String, dynamic> recordData) async {
    if (domainId.isEmpty) {
      return _errorResult(DriverResponseParser.parseError('Invalid domain ID', 'INVALID_DOMAIN_ID'), 1, 20);
    }

    final params = <String, dynamic>{
      'domain-name': domainId,
      'auth-id': _authId,
      'auth-password': _authPassword,
    };
    if (recordData.containsKey('type')) params['record-type'] = recordData['type'];
    if (recordData.containsKey('host')) params['host'] = recordData['host'];
    if (recordData.containsKey('record')) params['record'] = recordData['record'];
    if (recordData.containsKey('ttl') && recordData['ttl'] != null) params['ttl'] = recordData['ttl'];
    if (recordData.containsKey('priority') && recordData['priority'] != null) params['priority'] = recordData['priority'];

    try {
      final response = await _client.get('/dns/add-record.json', queryParameters: params);

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final result = CloudnsParser.parseResponse(response.data);
      if (result['success'] == true) {
        return CloudnsParser.parseSuccess(data: response.data);
      }

      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = CloudnsParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Future<Map<String, dynamic>> updateRecord(
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
  ) async {
    if (domainId.isEmpty || recordId.isEmpty) {
      return _errorResult(DriverResponseParser.parseError('Invalid ID', 'INVALID_ID'), 1, 20);
    }

    final params = <String, dynamic>{
      'domain-name': domainId,
      'record-id': recordId,
      'auth-id': _authId,
      'auth-password': _authPassword,
    };
    if (recordData.containsKey('host')) params['host'] = recordData['host'];
    if (recordData.containsKey('record')) params['record'] = recordData['record'];
    if (recordData.containsKey('ttl') && recordData['ttl'] != null) params['ttl'] = recordData['ttl'];
    if (recordData.containsKey('priority') && recordData['priority'] != null) params['priority'] = recordData['priority'];

    try {
      final response = await _client.get('/dns/mod-record.json', queryParameters: params);

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final result = CloudnsParser.parseResponse(response.data);
      if (result['success'] == true) {
        return CloudnsParser.parseSuccess(data: response.data);
      }

      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = CloudnsParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Future<Map<String, dynamic>> deleteRecord(String domainId, String recordId) async {
    if (domainId.isEmpty || recordId.isEmpty) {
      return _errorResult(DriverResponseParser.parseError('Invalid ID', 'INVALID_ID'), 1, 20);
    }

    try {
      final response = await _client.get('/dns/delete-record.json', queryParameters: {
        'domain-name': domainId,
        'record-id': recordId,
        'auth-id': _authId,
        'auth-password': _authPassword,
      });

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final result = CloudnsParser.parseResponse(response.data);
      if (result['success'] == true) {
        return CloudnsParser.parseSuccess();
      }

      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = CloudnsParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
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