import 'package:flutter/widgets.dart';

import '../interfaces/driver_interface.dart';

class CloudflareDriver implements DriverInterface {
  static const String _providerId = 'cloudflare';
  static const String _providerName = 'Cloudflare';
  static const String _providerIcon = 'cloud';

  @override
  String get providerId => _providerId;

  @override
  String get providerName => _providerName;

  @override
  String get providerIcon => _providerIcon;

  @override
  Future<bool> validateCredential(Map<String, String> credentials) async {
    return false;
  }

  @override
  Future<Map<String, dynamic>> getDomains({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    return {'domains': [], 'pagination': {}};
  }

  @override
  Future<Map<String, dynamic>> getDnsRecords(
    String domainId, {
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    return {'records': [], 'pagination': {}};
  }

  @override
  Future<Map<String, dynamic>> createDnsRecord(
    String domainId,
    Map<String, dynamic> recordData,
  ) async {
    return {};
  }

  @override
  Future<Map<String, dynamic>> updateDnsRecord(
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
  ) async {
    return {};
  }

  @override
  Future<void> deleteDnsRecord(String domainId, String recordId) async {}

  @override
  Widget buildDomainListItem(Map<String, dynamic> domainData) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildDnsRecordListItem(Map<String, dynamic> recordData) {
    return const SizedBox.shrink();
  }

  @override
  Map<String, String> getCredentialFields() {
    return {
      'apiToken': 'API Token',
    };
  }

  @override
  List<String> getSupportedRecordTypes() {
    return ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SRV', 'CAA'];
  }
}