import 'package:dio/dio.dart';

class DigitalplatDns {
  final Dio _client;

  DigitalplatDns(this._client);

  Future<Map<String, dynamic>> getRecords(
    String domainId, {
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    return _notSupported();
  }

  Future<Map<String, dynamic>> createRecord(
    String domainId,
    Map<String, dynamic> recordData,
  ) async {
    return _notSupported();
  }

  Future<Map<String, dynamic>> updateRecord(
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
  ) async {
    return _notSupported();
  }

  Future<Map<String, dynamic>> deleteRecord(String domainId, String recordId) async {
    return _notSupported();
  }

  Map<String, dynamic> _notSupported() => {
    'success': false,
    'error': 'DigitalPlat API 不支持 DNS 记录管理功能，仅支持域名注册管理',
    'errorCode': 'NOT_SUPPORTED',
    'records': [],
    'pagination': {},
  };
}