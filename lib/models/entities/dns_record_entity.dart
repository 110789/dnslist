class DnsRecordEntity {
  final String id;
  final String name;
  final String type;
  final String content;
  final int ttl;
  final int? priority;
  final bool? proxied;
  final String? provider;
  final Map<String, dynamic>? extra;

  DnsRecordEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.content,
    required this.ttl,
    this.priority,
    this.proxied,
    this.provider,
    this.extra,
  });
}