import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';
import 'core.dart';
import 'parser.dart';

class DnsheDns {
  final Dio _client;

  DnsheDns(this._client);

  Future<Map<String, dynamic>> getRecords(
    String domainId, {
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    if (domainId.isEmpty) {
      return _emptyResult(page, pageSize, 'Invalid subdomain ID', 'INVALID_DOMAIN_ID');
    }

    try {
      final queryParams = <String, dynamic>{
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'list',
        'subdomain_id': int.tryParse(domainId) ?? domainId,
      };

      final response = await _client.get('', queryParameters: queryParams);

      if (response.data == null) {
        return _emptyResult(page, pageSize);
      }

      final data = response.data as Map;
      if (data['success'] != true) {
        final result = DnsheParser.parseResponse(data);
        return _errorResult(result, page, pageSize);
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
      final result = DnsheParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, page, pageSize);
    }
  }

  Future<Map<String, dynamic>> createRecord(String domainId, Map<String, dynamic> recordData) async {
    final subdomainId = int.tryParse(domainId) ?? 0;
    if (subdomainId <= 0) {
      return _errorResult(DriverResponseParser.parseError('Invalid subdomain ID', 'INVALID_DOMAIN_ID'), 1, 20);
    }

    try {
      final bodyData = <String, dynamic>{
        'subdomain_id': subdomainId,
        'type': recordData['type'] ?? 'A',
        'content': recordData['content'] ?? '',
      };

      final name = recordData['name'];
      if (name != null && name.toString().isNotEmpty) {
        bodyData['name'] = name;
      }

      final ttl = recordData['ttl'];
      if (ttl != null && ttl is int && ttl > 0) {
        bodyData['ttl'] = ttl;
      }

      final priority = recordData['priority'];
      if (priority != null && priority is int && priority > 0) {
        bodyData['priority'] = priority;
      }

      final response = await _client.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'create',
      }, data: bodyData);

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return DnsheParser.parseSuccess(data: {
          'id': data['id']?.toString() ?? '',
          'record_id': data['record_id']?.toString() ?? '',
          'message': data['message'] ?? '',
        });
      }

      final result = DnsheParser.parseResponse(data);
      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = DnsheParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Future<Map<String, dynamic>> updateRecord(
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
  ) async {
    final recordIdInt = int.tryParse(recordId);
    if (recordIdInt == null || recordIdInt <= 0) {
      return _errorResult(DriverResponseParser.parseError('Invalid record ID', 'INVALID_RECORD_ID'), 1, 20);
    }

    try {
      final bodyData = <String, dynamic>{'id': recordIdInt};

      final type = recordData['type'];
      if (type != null) bodyData['type'] = type;

      final name = recordData['name'];
      if (name != null && name.toString().isNotEmpty) {
        bodyData['name'] = name;
      }

      final content = recordData['content'];
      if (content != null && content.toString().isNotEmpty) {
        bodyData['content'] = content;
      }

      final ttl = recordData['ttl'];
      if (ttl != null && ttl is int && ttl > 0) {
        bodyData['ttl'] = ttl;
      }

      final priority = recordData['priority'];
      if (priority != null && priority is int && priority > 0) {
        bodyData['priority'] = priority;
      }

      final response = await _client.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'update',
      }, data: bodyData);

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return DnsheParser.parseSuccess(data: {
          'id': data['id']?.toString() ?? recordId,
          'record_id': data['record_id']?.toString() ?? '',
          'message': data['message'] ?? '',
        });
      }

      final result = DnsheParser.parseResponse(data);
      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = DnsheParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Future<Map<String, dynamic>> deleteRecord(String domainId, String recordId) async {
    final recordIdInt = int.tryParse(recordId);
    if (recordIdInt == null || recordIdInt <= 0) {
      return _errorResult(DriverResponseParser.parseError('Invalid record ID', 'INVALID_RECORD_ID'), 1, 20);
    }

    try {
      final response = await _client.post('', queryParameters: {
        'm': 'domain_hub',
        'endpoint': 'dns_records',
        'action': 'delete',
      }, data: {'id': recordIdInt});

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return DnsheParser.parseSuccess(message: 'DNS record deleted');
      }

      final result = DnsheParser.parseResponse(data);
      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = DnsheParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
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