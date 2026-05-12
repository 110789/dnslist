import 'package:dio/dio.dart';
import 'core.dart';
import 'parser.dart';

class DnsheDns {
  final Dio _client;

  DnsheDns(this._client);

  Future<Map<String, dynamic>> getRecords({
    required int subdomainId,
    int page = 1,
    int pageSize = 100,
  }) async {
    if (subdomainId <= 0) {
      return _emptyResult('Invalid subdomain ID', 'INVALID_SUBDOMAIN_ID');
    }

    try {
      final queryParams = DnsheCore.buildDnsRecordListParams(
        subdomainId: subdomainId,
        page: page,
        perPage: pageSize,
      );

      final response = await _client.get('', queryParameters: queryParams);

      if (response.data == null) {
        return _emptyResult('Empty response', 'EMPTY_RESPONSE');
      }

      final data = response.data as Map;
      final result = DnsheParser.parseResponse(data);

      if (result['success'] != true) {
        return _errorResult(result);
      }

      final recordsList = data['records'] as List? ?? [];
      final records = recordsList.map(_parseRecord).toList();

      return {
        'records': records,
        'pagination': data['pagination'] ?? {'page': page, 'per_page': pageSize, 'total': recordsList.length},
        'count': data['count'] ?? recordsList.length,
        'success': true,
        'statusCode': 'OK',
      };
    } on DioException catch (e) {
      final result = DnsheParser.parseException(e);
      return _errorResult(result);
    } catch (e) {
      return _errorResult(DnsheParser.parseUnknown(e.toString()));
    }
  }

  Future<Map<String, dynamic>> createRecord(Map<String, dynamic> recordData) async {
    final subdomainId = recordData['subdomain_id'];
    if (subdomainId == null || (subdomainId is int && subdomainId <= 0)) {
      return _errorResult(DnsheParser.parseError('Invalid subdomain ID', 'INVALID_SUBDOMAIN_ID'));
    }

    final type = recordData['type']?.toString();
    if (type == null || type.isEmpty) {
      return _errorResult(DnsheParser.parseError('Record type is required', 'MISSING_TYPE'));
    }

    final content = recordData['content']?.toString();
    if (content == null || content.isEmpty) {
      return _errorResult(DnsheParser.parseError('Record content is required', 'MISSING_CONTENT'));
    }

    try {
      final body = DnsheCore.buildDnsRecordCreateBody(
        subdomainId: subdomainId as int,
        type: type,
        name: recordData['name']?.toString(),
        content: content,
        ttl: recordData['ttl'] as int?,
        priority: recordData['priority'] as int?,
        proxied: recordData['proxied'] as bool?,
      );

      final response = await _client.post(
        '',
        queryParameters: {
          'm': 'domain_hub',
          'endpoint': 'dns_records',
          'action': 'create',
        },
        data: body,
      );

      if (response.data == null) {
        return _errorResult(DnsheParser.parseEmpty());
      }

      final data = response.data as Map;
      final result = DnsheParser.parseResponse(data);

      if (result['success'] != true) {
        return _errorResult(result);
      }

      return {
        'success': true,
        'statusCode': 'OK',
        'id': data['id']?.toString(),
        'record_id': data['record_id']?.toString(),
        'message': data['message']?.toString() ?? 'DNS record created successfully',
      };
    } on DioException catch (e) {
      final result = DnsheParser.parseException(e);
      return _errorResult(result);
    } catch (e) {
      return _errorResult(DnsheParser.parseUnknown(e.toString()));
    }
  }

  Future<Map<String, dynamic>> updateRecord(Map<String, dynamic> recordData) async {
    final id = recordData['id'];
    final recordId = recordData['record_id']?.toString();

    if ((id == null || (id is int && id <= 0)) && (recordId == null || recordId.isEmpty)) {
      return _errorResult(DnsheParser.parseError('Record ID or record_id is required', 'MISSING_ID'));
    }

    try {
      final body = DnsheCore.buildDnsRecordUpdateBody(
        id: id as int?,
        recordId: recordId,
        type: recordData['type']?.toString(),
        name: recordData['name']?.toString(),
        content: recordData['content']?.toString(),
        ttl: recordData['ttl'] as int?,
        priority: recordData['priority'] as int?,
        proxied: recordData['proxied'] as bool?,
      );

      final response = await _client.post(
        '',
        queryParameters: {
          'm': 'domain_hub',
          'endpoint': 'dns_records',
          'action': 'update',
        },
        data: body,
      );

      if (response.data == null) {
        return _errorResult(DnsheParser.parseEmpty());
      }

      final data = response.data as Map;
      final result = DnsheParser.parseResponse(data);

      if (result['success'] != true) {
        return _errorResult(result);
      }

      return {
        'success': true,
        'statusCode': 'OK',
        'id': data['id']?.toString(),
        'record_id': data['record_id']?.toString(),
        'message': data['message']?.toString() ?? 'DNS record updated successfully',
      };
    } on DioException catch (e) {
      final result = DnsheParser.parseException(e);
      return _errorResult(result);
    } catch (e) {
      return _errorResult(DnsheParser.parseUnknown(e.toString()));
    }
  }

  Future<Map<String, dynamic>> deleteRecord(Map<String, dynamic> recordData) async {
    final id = recordData['id'];
    final recordId = recordData['record_id']?.toString();

    if ((id == null || (id is int && id <= 0)) && (recordId == null || recordId.isEmpty)) {
      return _errorResult(DnsheParser.parseError('Record ID or record_id is required', 'MISSING_ID'));
    }

    try {
      final body = DnsheCore.buildDnsRecordDeleteBody(
        id: id as int?,
        recordId: recordId,
      );

      final response = await _client.post(
        '',
        queryParameters: {
          'm': 'domain_hub',
          'endpoint': 'dns_records',
          'action': 'delete',
        },
        data: body,
      );

      if (response.data == null) {
        return _errorResult(DnsheParser.parseEmpty());
      }

      final data = response.data as Map;
      final result = DnsheParser.parseResponse(data);

      if (result['success'] != true) {
        return _errorResult(result);
      }

      return {
        'success': true,
        'statusCode': 'OK',
        'message': data['message']?.toString() ?? 'DNS record deleted successfully',
      };
    } on DioException catch (e) {
      final result = DnsheParser.parseException(e);
      return _errorResult(result);
    } catch (e) {
      return _errorResult(DnsheParser.parseUnknown(e.toString()));
    }
  }

  Map<String, dynamic> _parseRecord(dynamic record) {
    return {
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
  }

  Map<String, dynamic> _emptyResult(String error, String errorCode) {
    return {
      'records': <Map<String, dynamic>>[],
      'pagination': <String, dynamic>{},
      'error': error,
      'errorCode': errorCode,
      'success': false,
    };
  }

  Map<String, dynamic> _errorResult(Map<String, dynamic> error) {
    return {
      'records': <Map<String, dynamic>>[],
      'pagination': <String, dynamic>{},
      'error': error['error'] ?? 'Unknown error',
      'errorCode': error['errorCode'] ?? 'UNKNOWN',
      'success': false,
    };
  }
}