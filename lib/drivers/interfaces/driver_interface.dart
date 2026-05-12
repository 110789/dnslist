import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AddDomainField {
  final String key;
  final String label;
  final String hintText;
  final String? description;
  final bool required;

  const AddDomainField({
    required this.key,
    required this.label,
    required this.hintText,
    this.description,
    this.required = true,
  });
}

class DnsRecordField {
  final String key;
  final String label;
  final String hintText;
  final String? description;
  final bool required;
  final TextInputType keyboardType;
  final String? initialValue;

  const DnsRecordField({
    required this.key,
    required this.label,
    required this.hintText,
    this.description,
    this.required = true,
    this.keyboardType = TextInputType.text,
    this.initialValue,
  });
}

abstract class DriverInterface {
  String get providerId;
  String get providerName;
  String get providerIcon;

  Future<Map<String, dynamic>> validateCredential(Map<String, String> credentials);

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

  Future<Map<String, dynamic>> deleteDnsRecord(String domainId, String recordId);

  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData);

  Future<Map<String, dynamic>> deleteDomain(String domainId);

  Future<Map<String, dynamic>> renewDomain(String domainId);

  bool get supportsAddDomain;

  bool get supportsDeleteDomain;

  bool get supportsRenewDomain;

  bool get supportsShowNameServers;

  bool get supportsProxy;

  Widget buildDomainListItem(
    Map<String, dynamic> domainData, {
    required VoidCallback onTap,
    required VoidCallback onDelete,
    required VoidCallback onRenew,
    required bool supportsDelete,
    required bool supportsRenew,
  });

  Widget buildDnsRecordListItem(Map<String, dynamic> recordData);

  Map<String, String> getCredentialFields();

  List<String> getSupportedRecordTypes();

  String mapErrorCode(String code);

  String getAddDomainTitle();

  List<AddDomainField> getAddDomainFields();

  Map<String, dynamic> prepareDomainData(Map<String, dynamic> input);

  void showDomainListItemMenu(
    BuildContext context,
    Map<String, dynamic> domainData, {
    required VoidCallback onDelete,
    required VoidCallback onRenew,
    required VoidCallback onShowNameServers,
    required bool supportsDelete,
    required bool supportsRenew,
    required bool supportsShowNameServers,
  });

  List<DnsRecordField> getAddRecordFields();

  List<DnsRecordField> getEditRecordFields(Map<String, dynamic> recordData);

  Map<String, dynamic> prepareRecordData({
    required Map<String, String> fieldValues,
    required String recordType,
    bool isEdit = false,
  });

  String getAddRecordTitle();

  String getEditRecordTitle();

  bool supportsRecordLine();
}