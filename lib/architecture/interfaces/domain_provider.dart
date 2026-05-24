import 'package:flutter/material.dart';

abstract class DomainProviderInterface {
  String get providerId;
  String get providerName;
  String get providerIcon;

  Future<OperationResult> validateCredential(Map<String, String> credentials);

  Future<QueryResult<List<DomainRecord>>> getDomains({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  });

  Future<QueryResult<List<DnsRecord>>> getDnsRecords(
    String domainId, {
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  });

  Future<OperationResult> createDnsRecord(
    String domainId,
    DnsRecord record,
  );

  Future<OperationResult> updateDnsRecord(
    String domainId,
    String recordId,
    DnsRecord record,
  );

  Future<OperationResult> deleteDnsRecord(String domainId, String recordId);

  Future<OperationResult> createDomain(DomainRecord domain);

  Future<OperationResult> deleteDomain(String domainId);

  Future<OperationResult> renewDomain(String domainId);

  bool get supportsAddDomain;
  bool get supportsDeleteDomain;
  bool get supportsRenewDomain;
  bool get supportsShowNameServers;
  bool get supportsProxy;

  Widget buildDomainListItem(
    DomainRecord domain, {
    required VoidCallback onTap,
    required VoidCallback onDelete,
    required VoidCallback onRenew,
  });

  Widget buildDnsRecordListItem(DnsRecord record);

  Map<String, String> getCredentialFields();

  List<String> getSupportedRecordTypes();

  String mapErrorCode(String code);

  String getAddDomainTitle();

  List<ProviderField> getAddDomainFields();

  DomainRecord prepareDomainData(Map<String, dynamic> input);

  void showDomainListItemMenu(
    BuildContext context,
    DomainRecord domain, {
    required VoidCallback onDelete,
    required VoidCallback onRenew,
    required VoidCallback onShowNameServers,
  });

  List<ProviderField> getAddRecordFields();

  List<ProviderField> getEditRecordFields(DnsRecord record);

  DnsRecord prepareRecordData({
    required Map<String, String> fieldValues,
    required String recordType,
    bool isEdit = false,
  });

  String getAddRecordTitle();

  String getEditRecordTitle();

  bool supportsRecordLine();
}

class OperationResult {
  final bool success;
  final String? error;
  final String? errorCode;
  final dynamic data;

  const OperationResult({
    required this.success,
    this.error,
    this.errorCode,
    this.data,
  });

  factory OperationResult.ok({dynamic data}) => OperationResult(success: true, data: data);
  factory OperationResult.fail({required String error, String? errorCode, int? statusCode}) =>
      OperationResult(success: false, error: error, errorCode: errorCode);
}

class QueryResult<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? errorCode;
  final PaginationInfo? pagination;

  const QueryResult({
    required this.success,
    this.data,
    this.error,
    this.errorCode,
    this.pagination,
  });

  factory QueryResult.ok(T data, {PaginationInfo? pagination}) =>
      QueryResult(success: true, data: data, pagination: pagination);

  factory QueryResult.fail({required String error, String? errorCode}) =>
      QueryResult(success: false, error: error, errorCode: errorCode);
}

class PaginationInfo {
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;

  const PaginationInfo({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) => PaginationInfo(
        page: json['page'] ?? 1,
        pageSize: json['pageSize'] ?? 20,
        total: json['total'] ?? 0,
        hasMore: json['hasMore'] ?? false,
      );
}

class DomainRecord {
  final String id;
  final String name;
  final String? status;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final int? ttl;
  final List<String>? nameServers;
  final Map<String, dynamic> rawData;

  const DomainRecord({
    required this.id,
    required this.name,
    this.status,
    this.createdAt,
    this.expiresAt,
    this.ttl,
    this.nameServers,
    this.rawData = const {},
  });

  factory DomainRecord.fromJson(Map<String, dynamic> json) => DomainRecord(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? json['domain']?.toString() ?? '',
        status: json['status']?.toString(),
        createdAt: _parseDate(json['created_at'] ?? json['created_on']),
        expiresAt: _parseDate(json['expires_at'] ?? json['expiry_at']),
        ttl: json['ttl'] is int ? json['ttl'] : int.tryParse(json['ttl']?.toString() ?? ''),
        nameServers: json['name_servers'] is List
            ? List<String>.from(json['name_servers'])
            : null,
        rawData: json,
      );

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int && value > 10000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    }
    return DateTime.tryParse(value.toString());
  }
}

class DnsRecord {
  final String id;
  final String name;
  final String type;
  final String content;
  final int ttl;
  final int? priority;
  final bool enabled;
  final bool? proxied;
  final String? line;
  final Map<String, dynamic> rawData;

  const DnsRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.content,
    this.ttl = 600,
    this.priority,
    this.enabled = true,
    this.proxied,
    this.line,
    this.rawData = const {},
  });

  factory DnsRecord.fromJson(Map<String, dynamic> json) => DnsRecord(
        id: json['id']?.toString() ?? json['record_id']?.toString() ?? '',
        name: json['name']?.toString() ?? json['sub_domain']?.toString() ?? '',
        type: json['type']?.toString() ?? json['record_type']?.toString() ?? 'A',
        content: json['content']?.toString() ?? json['value']?.toString() ?? '',
        ttl: json['ttl'] is int ? json['ttl'] : int.tryParse(json['ttl']?.toString() ?? '600') ?? 600,
        priority: json['priority'] ?? json['mx'],
        enabled: json['enabled'] == true || json['status']?.toString()?.toLowerCase() == 'active',
        proxied: json['proxied'],
        line: json['line']?.toString() ?? json['record_line']?.toString(),
        rawData: json,
      );
}

class ProviderField {
  final String key;
  final String label;
  final String hintText;
  final String? description;
  final bool required;
  final TextInputType keyboardType;
  final String? initialValue;

  const ProviderField({
    required this.key,
    required this.label,
    required this.hintText,
    this.description,
    this.required = true,
    this.keyboardType = TextInputType.text,
    this.initialValue,
  });
}