class DnsRecordDto {
  final String name;
  final String type;
  final String content;
  final int? ttl;
  final int? priority;
  final bool? proxied;

  DnsRecordDto({
    required this.name,
    required this.type,
    required this.content,
    this.ttl,
    this.priority,
    this.proxied,
  });
}