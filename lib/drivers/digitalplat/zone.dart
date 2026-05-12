import 'package:dio/dio.dart';
import 'parser.dart';

class DigitalplatZone {
  final Dio _client;

  DigitalplatZone(this._client);

  Future<Map<String, dynamic>> getList({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    try {
      final response = await _client.get('/domains');
      if (response.data == null) {
        return _errorResult('Empty response', 'EMPTY_RESPONSE', page, pageSize);
      }

      final result = DigitalplatParser.parseResponse(response.data);
      if (result['success'] == true) {
        final responseData = response.data as Map<String, dynamic>;
        final dataList = responseData['data'] as List<dynamic>? ?? [];
        final meta = responseData['meta'] as Map<String, dynamic>? ?? {};
        final count = meta['count'] as int? ?? dataList.length;

        return {
          'domains': dataList.map((item) => _parseDomain(item as Map<String, dynamic>)).toList(),
          'pagination': {
            'total': count,
            'page': page,
            'per_page': pageSize,
          },
          'success': true,
          'statusCode': 'OK',
          'total': count,
          'page': page,
          'pageSize': pageSize,
        };
      }

      final error = DigitalplatParser.parseResponse(response.data);
      return _errorResult(error['error'] ?? 'Unknown error', error['errorCode'] ?? 'UNKNOWN', page, pageSize);
    } catch (e) {
      final result = DigitalplatParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result['error'] ?? 'Unknown error', result['errorCode'] ?? 'UNKNOWN', page, pageSize);
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> domainData) async {
    final domain = domainData['domain']?.toString() ?? domainData['name']?.toString() ?? '';
    if (domain.isEmpty) {
      return _errorResult('Domain cannot be empty', 'INVALID_DOMAIN', 1, 20);
    }

    try {
      final requestBody = <String, dynamic>{
        'domain': domain,
      };

      if (domainData.containsKey('slot_type')) {
        requestBody['slot_type'] = domainData['slot_type'];
      } else {
        requestBody['slot_type'] = 'free';
      }

      if (domainData.containsKey('nameservers') && domainData['nameservers'] is List) {
        requestBody['nameservers'] = domainData['nameservers'];
      } else {
        requestBody['nameservers'] = [];
      }

      final response = await _client.post('/domains', data: requestBody);
      final result = DigitalplatParser.parseResponse(response.data);

      if (result['success'] == true) {
        final data = result['data'] as Map? ?? {};
        return {
          'success': true,
          'statusCode': 'OK',
          'data': {
            'id': data['domain']?.toString() ?? domain,
            'domain_id': data['domain']?.toString() ?? domain,
            'name': data['name']?.toString() ?? domain,
            'domain': data['name']?.toString() ?? domain,
            'status': data['status']?.toString() ?? 'ok',
          },
          'message': '域名添加成功',
        };
      }

      final error = DigitalplatParser.parseResponse(response.data);
      return _errorResult(error['error'] ?? 'Unknown error', error['errorCode'] ?? 'UNKNOWN', 1, 20);
    } catch (e) {
      final result = DigitalplatParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result['error'] ?? 'Unknown error', result['errorCode'] ?? 'UNKNOWN', 1, 20);
    }
  }

  Future<Map<String, dynamic>> delete(String domainId) async {
    if (domainId.isEmpty) {
      return _errorResult('Invalid domain ID', 'INVALID_DOMAIN_ID', 1, 20);
    }

    try {
      final response = await _client.delete('/domains/$domainId');
      final result = DigitalplatParser.parseResponse(response.data);

      if (result['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'message': '域名已删除'};
      }

      final error = DigitalplatParser.parseResponse(response.data);
      return _errorResult(error['error'] ?? 'Unknown error', error['errorCode'] ?? 'UNKNOWN', 1, 20);
    } catch (e) {
      final result = DigitalplatParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result['error'] ?? 'Unknown error', result['errorCode'] ?? 'UNKNOWN', 1, 20);
    }
  }

  Future<Map<String, dynamic>> updateNameservers(String domain, List<String> nameservers) async {
    if (domain.isEmpty) {
      return _errorResult('Invalid domain', 'INVALID_DOMAIN', 1, 20);
    }

    try {
      final response = await _client.patch(
        '/domains/$domain/nameservers',
        data: {'nameservers': nameservers},
      );
      final result = DigitalplatParser.parseResponse(response.data);

      if (result['success'] == true) {
        final data = result['data'] as Map? ?? {};
        return {
          'success': true,
          'statusCode': 'OK',
          'data': {
            'name': data['name']?.toString() ?? domain,
            'nameservers': data['nameservers'] as List? ?? [],
          },
          'message': '名称服务器已更新',
        };
      }

      final error = DigitalplatParser.parseResponse(response.data);
      return _errorResult(error['error'] ?? 'Unknown error', error['errorCode'] ?? 'UNKNOWN', 1, 20);
    } catch (e) {
      final result = DigitalplatParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result['error'] ?? 'Unknown error', result['errorCode'] ?? 'UNKNOWN', 1, 20);
    }
  }

  Future<Map<String, dynamic>> renew(String domainId) async {
    return _errorResult(
      'DigitalPlat 域名续期需在控制台操作，不支持 API 续期',
      'NOT_SUPPORTED',
      1,
      20,
    );
  }

  Map<String, dynamic> _parseDomain(dynamic domain) {
    if (domain is! Map) {
      return {
        'id': '',
        'domain_id': '',
        'name': '',
        'domain': '',
        'status': 'unknown',
      };
    }

    return {
      'id': domain['domain']?.toString() ?? '',
      'domain_id': domain['domain']?.toString() ?? '',
      'name': domain['domain']?.toString() ?? '',
      'domain': domain['domain']?.toString() ?? '',
      'status': domain['status']?.toString() ?? 'unknown',
      'slot_type': domain['slot_type']?.toString() ?? '',
      'lifecycle_type': domain['lifecycle_type']?.toString() ?? '',
      'expires_at': domain['expires_at']?.toString() ?? '',
      'created_at': domain['created_at']?.toString() ?? '',
      'nameservers': domain['nameservers'] as List? ?? [],
      'registrant': domain['registrant']?.toString() ?? '',
      'registrar': domain['registrar']?.toString() ?? '',
      'dns_server': domain['dns_server']?.toString() ?? '',
      'zone': domain['zone']?.toString() ?? '',
      'whois_privacy': domain['whois_privacy']?.toString() ?? '',
    };
  }

  Map<String, dynamic> _errorResult(String error, String errorCode, int page, int pageSize) => {
    'domains': [],
    'pagination': {},
    'error': error,
    'errorCode': errorCode,
    'success': false,
  };
}