import 'package:dio/dio.dart';
import 'package:dlist/utils/driver/driver_utils.dart';
import 'core.dart';
import 'signer.dart';
import 'parser.dart';

class DnspodZone {
  final Dio _client;
  final String _secretId;
  final String _secretKey;

  DnspodZone(this._client, this._secretId, this._secretKey);

  Future<Map<String, dynamic>> getList({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    try {
      final params = <String, dynamic>{
        'Offset': (page - 1) * pageSize,
        'Limit': pageSize,
        'Type': 'ALL',
      };
      if (filters != null && filters.containsKey('keyword')) {
        params['Keyword'] = filters['keyword'];
      }

      final result = await _callApi('DescribeDomainList', params);
      if (result['success'] == true) {
        final data = result['data'] as Map;
        final domainList = data['DomainList'] as List? ?? [];
        final countInfo = data['DomainCountInfo'] as Map? ?? {};
        final domains = domainList.map(_parseDomain).toList();
        final total = countInfo['AllTotal'] ?? countInfo['DomainTotal'] ?? domainList.length;

        return {
          'domains': domains,
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

  Future<Map<String, dynamic>> create(Map<String, dynamic> domainData) async {
    final domain = domainData['domain']?.toString() ?? domainData['name']?.toString() ?? '';
    if (domain.isEmpty) {
      return _errorResult(DriverResponseParser.parseError('Domain cannot be empty', 'INVALID_DOMAIN'), 1, 20);
    }

    try {
      final params = <String, dynamic>{'Domain': domain};
      final result = await _callApi('CreateDomain', params);
      if (result['success'] == true) {
        final data = result['data'] as Map;
        final domainInfo = data['DomainInfo'] as Map? ?? {};
        return {
          'success': true,
          'statusCode': 'OK',
          'data': {
            'id': domainInfo['Id']?.toString() ?? domainInfo['DomainId']?.toString() ?? '',
            'domain_id': domainInfo['Id'] ?? domainInfo['DomainId'],
            'name': domainInfo['Domain']?.toString() ?? domain,
            'domain': domainInfo['Domain']?.toString() ?? domain,
            'punycode': domainInfo['Punycode']?.toString() ?? domain,
          },
          'message': '域名添加成功',
        };
      }

      final error = DnspodParser.parseResponse(result['data'] ?? result);
      return _errorResult(error, 1, 20);
    } catch (e) {
      final result = DnspodParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Future<Map<String, dynamic>> delete(String domainId) async {
    if (domainId.isEmpty) {
      return _errorResult(DriverResponseParser.parseError('Invalid domain ID', 'INVALID_DOMAIN_ID'), 1, 20);
    }

    try {
      final domainIdInt = int.tryParse(domainId);
      final params = <String, dynamic>{'DomainId': domainIdInt ?? domainId};
      final result = await _callApi('DeleteDomain', params);
      if (result['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'message': '域名已删除'};
      }

      final error = DnspodParser.parseResponse(result['data'] ?? result);
      return _errorResult(error, 1, 20);
    } catch (e) {
      final result = DnspodParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, 1, 20);
    }
  }

  Future<Map<String, dynamic>> renew(String domainId) async {
    return _errorResult(
      DriverResponseParser.parseError('DNSPod 域名续期需在腾讯云控制台操作，不支持 API 续期', 'NOT_SUPPORTED'),
      1,
      20,
    );
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
          final parsed = respData is String ? parseJson(respData.toString()) : respData;
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

  Map<String, dynamic> _parseDomain(dynamic domain) => {
    'id': domain['DomainId']?.toString() ?? '',
    'domain_id': domain['DomainId'],
    'name': domain['Name']?.toString() ?? '',
    'domain': domain['Name']?.toString() ?? '',
    'status': domain['Status']?.toString()?.toLowerCase() == 'enable' ? 'active' : 'paused',
    'grade': domain['Grade']?.toString() ?? '',
    'grade_title': domain['GradeTitle']?.toString() ?? '',
    'is_vip': domain['IsVip']?.toString() == 'YES',
    'ttl': domain['TTL'] ?? 600,
    'remark': domain['Remark']?.toString() ?? '',
    'created_on': domain['CreatedOn'],
    'updated_on': domain['UpdatedOn'],
    'record_count': domain['RecordCount'] ?? 0,
    'effective_dns': domain['EffectiveDNS'] as List? ?? [],
    'punycode': domain['Punycode']?.toString() ?? '',
    'dns_status': domain['DNSStatus']?.toString() ?? '',
  };

  Map<String, dynamic> _errorResult(Map<String, dynamic> error, int page, int pageSize) => {
    'domains': [],
    'pagination': {},
    'error': error['error'],
    'errorCode': error['errorCode'],
    'success': false,
  };
}