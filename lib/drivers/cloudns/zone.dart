import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';
import 'core.dart';
import 'parser.dart';

class CloudnsZone {
  final Dio _client;
  final int _authId;
  final String _authPassword;

  CloudnsZone(this._client, this._authId, this._authPassword);

  Future<Map<String, dynamic>> getList({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    try {
      final result = await _callApi('dns/list-zones.json', {
        'page': page.toString(),
        'rows-per-page': pageSize.toString(),
      });

      if (result['success'] != true) {
        final parsed = CloudnsParser.parseResponseData(result['data']);
        return _errorResult({'error': result['error'], 'errorCode': result['errorCode']}, page, pageSize);
      }

      final data = result['data'] as Map? ?? {};
      final zones = data['zones'] as List? ?? [];

      return {
        'domains': zones.map(_parseZone).toList(),
        'pagination': {'page': page, 'per_page': pageSize, 'total': zones.length},
        'success': true,
        'statusCode': 'OK',
        'total': zones.length,
        'page': page,
        'pageSize': pageSize,
      };
    } catch (e) {
      final result = CloudnsParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, page, pageSize);
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> domainData) async {
    final domain = domainData['domain']?.toString() ?? domainData['name']?.toString() ?? '';
    if (domain.isEmpty) {
      return _errorResult(DriverResponseParser.parseError('Domain cannot be empty', 'INVALID_DOMAIN'), 1, 20);
    }

    return await _callApi('dns/register.json', {'domain-name': domain});
  }

  Future<Map<String, dynamic>> delete(String domainId) async {
    if (domainId.isEmpty) {
      return _errorResult(DriverResponseParser.parseError('Invalid domain ID', 'INVALID_DOMAIN_ID'), 1, 20);
    }

    return await _callApi('dns/delete.json', {'domain-name': domainId});
  }

  Future<Map<String, dynamic>> renew(String domainId) async {
    return _errorResult(
      DriverResponseParser.parseError('Not supported', 'NOT_SUPPORTED'),
      1,
      20,
    );
  }

  Future<Map<String, dynamic>> _callApi(String action, Map<String, dynamic> params) async {
    try {
      final queryParams = <String, dynamic>{
        'auth-id': _authId,
        'auth-password': _authPassword,
        ...params,
      };

      final response = await _client.get('/$action', queryParameters: queryParams);

      if (response.data == null) {
        return _errorResult(DriverResponseParser.parseEmpty(), 1, 20);
      }

      final result = CloudnsParser.parseResponse(response.data);
      if (result['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'data': response.data};
      }

      return _errorResult(result, 1, 20);
    } catch (e) {
      final result = CloudnsParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Map<String, dynamic> _parseZone(dynamic zone) => {
    'id': zone['id']?.toString() ?? '',
    'name': zone['domain']?.toString() ?? '',
    'domain': zone['domain']?.toString() ?? '',
    'status': zone['status']?.toString() ?? 'active',
    'created': zone['create_date'],
    'expire': zone['expire_date'],
  };

  Map<String, dynamic> _errorResult(Map<String, dynamic> error, int page, int pageSize) => {
    'domains': [],
    'pagination': {},
    'error': error['error'],
    'errorCode': error['errorCode'],
    'success': false,
  };
}