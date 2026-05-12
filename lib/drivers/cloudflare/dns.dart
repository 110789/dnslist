import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';
import 'core.dart';
import 'parser.dart';

class CloudflareDns {
  final Dio _client;

  CloudflareDns(this._client);

  Future<Map<String, dynamic>> getRecords(
    String domainId, {
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'per_page': pageSize};
      if (filters != null) queryParams.addAll(filters);

      final response = await _client.get('/zones/$domainId/dns_records', queryParameters: queryParams);

      if (response.data == null) {
        return _emptyResult(page, pageSize);
      }

      final data = response.data as Map;
      if (data['success'] != true) {
        final result = CloudflareParser.parseResponse(data);
        return _errorResult(result, page, pageSize);
      }

      final result = data['result'] as List? ?? [];
      final pagination = data['result_info'] ?? {};

      return {
        'records': result.map(_parseRecord).toList(),
        'pagination': pagination,
        'success': true,
        'statusCode': 'OK',
        'total': pagination['total_count'] ?? result.length,
        'page': page,
        'pageSize': pageSize,
      };
    } catch (e) {
      final result = CloudflareParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, page, pageSize);
    }
  }

  Future<Map<String, dynamic>> createRecord(String domainId, Map<String, dynamic> recordData) async {
    try {
      final preparedData = _prepareRecordData(recordData);
      final response = await _client.post('/zones/$domainId/dns_records', data: preparedData);

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return CloudflareParser.parseSuccess(data: data['result']);
      }

      final result = CloudflareParser.parseResponse(data);
      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = CloudflareParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Future<Map<String, dynamic>> updateRecord(
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
  ) async {
    try {
      final preparedData = _prepareRecordData(recordData);
      final response = await _client.put('/zones/$domainId/dns_records/$recordId', data: preparedData);

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return CloudflareParser.parseSuccess(data: data['result']);
      }

      final result = CloudflareParser.parseResponse(data);
      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = CloudflareParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Future<Map<String, dynamic>> deleteRecord(String domainId, String recordId) async {
    try {
      final response = await _client.delete('/zones/$domainId/dns_records/$recordId');

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return CloudflareParser.parseSuccess();
      }

      final result = CloudflareParser.parseResponse(data);
      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = CloudflareParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Map<String, dynamic> _prepareRecordData(Map<String, dynamic> recordData) {
    final data = Map<String, dynamic>.from(recordData);

    if (data.containsKey('proxied') && data['proxied'] == null) {
      data.remove('proxied');
    } else if (!data.containsKey('proxied')) {
      data['proxied'] = false;
    }

    if (data.containsKey('priority') && data['priority'] == null) {
      data.remove('priority');
    }
    if (data.containsKey('ttl') && (data['ttl'] == null || data['ttl'] == 0)) {
      data.remove('ttl');
    } else if (data['ttl'] == 1) {
      data['ttl'] = 1;
    }
    return data;
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

  Map<String, dynamic> _emptyResult(int page, int pageSize) => {
    'records': [],
    'pagination': {},
    'error': '',
    'errorCode': 'EMPTY_RESPONSE',
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