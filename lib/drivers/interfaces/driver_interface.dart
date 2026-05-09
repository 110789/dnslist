import 'package:flutter/widgets.dart';

abstract class DriverInterface {
  String get providerId;
  String get providerName;
  String get providerIcon;

  Future<bool> validateCredential(Map<String, String> credentials);

  Future<Map<String, dynamic>> getDomains({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  });

  Future<Map<String, dynamic>> getDnsRecords(
    String domainId, {
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  });

  Future<Map<String, dynamic>> createDnsRecord(
    String domainId,
    Map<String, dynamic> recordData,
  );

  Future<Map<String, dynamic>> updateDnsRecord(
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
  );

  Future<void> deleteDnsRecord(String domainId, String recordId);

  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData);

  Future<Map<String, dynamic>> deleteDomain(String domainId);

  Future<Map<String, dynamic>> renewDomain(String domainId);

  bool get supportsAddDomain;

  bool get supportsDeleteDomain;

  bool get supportsRenewDomain;

  Widget buildDomainListItem(Map<String, dynamic> domainData);

  Widget buildDnsRecordListItem(Map<String, dynamic> recordData);

  Map<String, String> getCredentialFields();

  List<String> getSupportedRecordTypes();
}