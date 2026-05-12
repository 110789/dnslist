import 'package:dio/dio.dart';
import '../../../utils/driver/driver_utils.dart';

class DnsheCore {
  static const String providerId = 'dnshe';
  static const String providerName = 'DNSHE';
  static const String providerIcon = 'assets/icons/dnshe.jpg';
  static const String baseUrl = 'https://api005.dnshe.com/index.php';

  static Dio createClient(String apiKey, String apiSecret) {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(milliseconds: DriverConstants.connectionTimeout),
      receiveTimeout: const Duration(milliseconds: DriverConstants.receiveTimeout),
      headers: {
        'X-API-Key': apiKey,
        'X-API-Secret': apiSecret,
        'Content-Type': 'application/json',
      },
    ));
  }

  static Map<String, dynamic> buildListParams({
    int? page,
    int? perPage,
    Map<String, String>? filters,
  }) {
    final params = <String, dynamic>{
      'm': 'domain_hub',
    };
    if (page != null) params['page'] = page;
    if (perPage != null) params['per_page'] = perPage;
    if (filters != null) {
      if (filters.containsKey('name')) params['search'] = filters['name'];
      if (filters.containsKey('rootdomain')) params['rootdomain'] = filters['rootdomain'];
      if (filters.containsKey('status')) params['status'] = filters['status'];
    }
    return params;
  }

  static Map<String, dynamic> buildSubdomainListParams({
    required String action,
    int? page,
    int? perPage,
    Map<String, String>? filters,
  }) {
    final params = <String, dynamic>{
      'm': 'domain_hub',
      'endpoint': 'subdomains',
      'action': action,
    };
    if (page != null) params['page'] = page;
    if (perPage != null) params['per_page'] = perPage;
    if (filters != null) {
      if (filters.containsKey('name')) params['search'] = filters['name'];
      if (filters.containsKey('rootdomain')) params['rootdomain'] = filters['rootdomain'];
      if (filters.containsKey('status')) params['status'] = filters['status'];
    }
    return params;
  }

  static Map<String, dynamic> buildDnsRecordListParams({
    required int subdomainId,
    int? page,
    int? perPage,
  }) {
    return <String, dynamic>{
      'm': 'domain_hub',
      'endpoint': 'dns_records',
      'action': 'list',
      'subdomain_id': subdomainId,
      if (page != null) 'page': page,
      if (perPage != null) 'per_page': perPage,
    };
  }

  static Map<String, dynamic> buildSubdomainCreateBody({
    required String subdomain,
    required String rootdomain,
  }) {
    return <String, dynamic>{
      'subdomain': subdomain,
      'rootdomain': rootdomain,
    };
  }

  static Map<String, dynamic> buildSubdomainDeleteBody(int subdomainId) {
    return <String, dynamic>{
      'subdomain_id': subdomainId,
    };
  }

  static Map<String, dynamic> buildSubdomainRenewBody(int subdomainId) {
    return <String, dynamic>{
      'subdomain_id': subdomainId,
    };
  }

  static Map<String, dynamic> buildDnsRecordCreateBody({
    required int subdomainId,
    required String type,
    String? name,
    required String content,
    int? ttl,
    int? priority,
    bool? proxied,
  }) {
    final body = <String, dynamic>{
      'subdomain_id': subdomainId,
      'type': type,
      'content': content,
    };
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (ttl != null) body['ttl'] = ttl;
    if (priority != null) body['priority'] = priority;
    if (proxied != null) body['proxied'] = proxied;
    return body;
  }

  static Map<String, dynamic> buildDnsRecordUpdateBody({
    int? id,
    String? recordId,
    String? type,
    String? name,
    String? content,
    int? ttl,
    int? priority,
    bool? proxied,
  }) {
    final body = <String, dynamic>{};
    if (id != null) body['id'] = id;
    if (recordId != null) body['record_id'] = recordId;
    if (type != null) body['type'] = type;
    if (name != null) body['name'] = name;
    if (content != null) body['content'] = content;
    if (ttl != null) body['ttl'] = ttl;
    if (priority != null) body['priority'] = priority;
    if (proxied != null) body['proxied'] = proxied;
    return body;
  }

  static Map<String, dynamic> buildDnsRecordDeleteBody({
    int? id,
    String? recordId,
  }) {
    final body = <String, dynamic>{};
    if (id != null) body['id'] = id;
    if (recordId != null) body['record_id'] = recordId;
    return body;
  }
}