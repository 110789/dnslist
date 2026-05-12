import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';
import 'core.dart';
import 'parser.dart';

class RainyunZone {
  final Dio _client;

  RainyunZone(this._client);

  Future<Map<String, dynamic>> getList({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    try {
      final options = <String, dynamic>{'page': page, 'page_size': pageSize};
      if (filters != null && filters.containsKey('keyword')) options['keyword'] = filters['keyword'];

      final response = await _client.get('/product/domain/', queryParameters: {'options': '{}'});

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

      final dataObj = data['data'] as Map? ?? {};
      final domainList = dataObj['Records'] as List? ?? [];
      final totalRecords = dataObj['TotalRecords'] as int? ?? 0;
      final domains = domainList.map(_parseDomain).toList();

      return {
        'domains': domains,
        'pagination': {'total': totalRecords, 'page': page, 'pageSize': pageSize},
        'success': true,
        'statusCode': 'OK',
        'total': domains.length,
        'page': page,
        'pageSize': pageSize,
      };
    } catch (e) {
      final result = RainyunParser.parseException(e, e is DioException ? e : null);
      return _errorResult(result, page, pageSize);
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> domainData) async {
    return _errorResult(
      DriverResponseParser.parseError('Not supported', 'NOT_SUPPORTED'),
      1,
      20,
    );
  }

  Future<Map<String, dynamic>> delete(String domainId) async {
    return _errorResult(
      DriverResponseParser.parseError('Not supported', 'NOT_SUPPORTED'),
      1,
      20,
    );
  }

  Future<Map<String, dynamic>> renew(String domainId) async {
    return _errorResult(
      DriverResponseParser.parseError('Not supported', 'NOT_SUPPORTED'),
      1,
      20,
    );
  }

  Map<String, dynamic> _parseDomain(dynamic zone) => {
    'id': zone['ID']?.toString() ?? zone['id']?.toString() ?? '',
    'name': zone['Domain']?.toString() ?? zone['domain']?.toString() ?? zone['Name']?.toString() ?? '',
    'domain': zone['Domain']?.toString() ?? zone['domain']?.toString() ?? zone['Name']?.toString() ?? '',
    'status': zone['Status']?.toString() ?? zone['status']?.toString() ?? 'active',
    'create_date': zone['CreateDate'] ?? zone['create_date'],
    'exp_date': zone['ExpDate'] ?? zone['exp_date'],
    'auto_renew': zone['AutoRenew'] ?? zone['auto_renew'] ?? false,
    'product': zone['Product']?.toString() ?? zone['product']?.toString() ?? 'domain',
  };

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