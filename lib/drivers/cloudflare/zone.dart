import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';
import 'core.dart';
import 'parser.dart';

class CloudflareZone {
  final Dio _client;

  CloudflareZone(this._client);

  Future<Map<String, dynamic>> getList({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'per_page': pageSize};
      if (filters != null) queryParams.addAll(filters);

      final response = await _client.get('/zones', queryParameters: queryParams);

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
        'domains': result.map(_parseZone).toList(),
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

  Future<Map<String, dynamic>> create(Map<String, dynamic> domainData) async {
    try {
      final preparedData = {
        'name': domainData['name']?.toString() ?? '',
        'type': domainData['type']?.toString() ?? 'full',
      };
      if (domainData.containsKey('account') && domainData['account'] != null) {
        preparedData['account'] = domainData['account'];
      }

      final response = await _client.post('/zones', data: preparedData);

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        final result = data['result'];
        return {
          'success': true,
          'statusCode': 'OK',
          'data': {
            'id': result['id']?.toString() ?? '',
            'name': result['name']?.toString() ?? '',
            'status': result['status']?.toString() ?? 'initializing',
            'type': result['type']?.toString() ?? 'full',
            'name_servers': result['name_servers'] as List? ?? [],
          },
          'message': '域名添加成功',
        };
      }

      final result = CloudflareParser.parseResponse(data);
      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = CloudflareParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Future<Map<String, dynamic>> delete(String domainId) async {
    if (domainId.isEmpty) {
      return _errorResult(DriverResponseParser.parseError('Invalid domain identifier', 'INVALID_ID'), 1, 20);
    }

    try {
      final response = await _client.delete('/zones/$domainId');

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final data = response.data as Map;
      if (data['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'message': '域名已删除'};
      }

      final result = CloudflareParser.parseResponse(data);
      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = CloudflareParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Future<Map<String, dynamic>> renew(String domainId) async {
    return _errorResult(
      DriverResponseParser.parseError('Renewal not supported for Cloudflare zones', 'NOT_SUPPORTED'),
      1,
      20,
    );
  }

  Map<String, dynamic> _parseZone(dynamic zone) {
    String? registrar;
    final owner = zone['owner'];
    if (owner != null) {
      final ownerType = owner['type']?.toString();
      if (ownerType != null && ownerType.isNotEmpty) {
        registrar = _parseRegistrarType(ownerType);
      }
    }
    return {
      'id': zone['id']?.toString() ?? '',
      'name': zone['name']?.toString() ?? '',
      'status': zone['status']?.toString() ?? 'unknown',
      'type': zone['type']?.toString() ?? 'full',
      'paused': zone['paused'] ?? false,
      'created_on': zone['created_on'],
      'modified_on': zone['modified_on'],
      'name_servers': zone['name_servers'] as List? ?? [],
      'owner': zone['owner'],
      'plan': zone['plan'],
      'registrar': registrar,
    };
  }

  String _parseRegistrarType(String ownerType) {
    switch (ownerType.toLowerCase()) {
      case 'cloudflare': return 'Cloudflare Registrar';
      case 'apex': return 'Apex (Root)';
      case 'full': return 'Full DNS';
      case 'partial': return 'Partial DNS';
      case 'secondary': return 'Secondary DNS';
      default: return ownerType;
    }
  }

  Map<String, dynamic> _emptyResult(int page, int pageSize) => {
    'domains': [],
    'pagination': {},
    'error': '',
    'errorCode': 'EMPTY_RESPONSE',
    'success': false,
  };

  Map<String, dynamic> _errorResult(Map<String, dynamic> error, int page, int pageSize) => {
    'domains': [],
    'pagination': {},
    'error': error['error'],
    'errorCode': error['errorCode'],
    'success': false,
  };
}