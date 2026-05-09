enum DnsRecordType {
  a, aaaa, cname, mx, txt, ns, srv, caa, other,
}

class DnsRecordModel {
  final String id;
  final String name;
  final DnsRecordType type;
  final String content;
  final int ttl;
  final int? priority;
  final bool? proxied;
  final String? status;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final Map<String, dynamic> _raw;

  DnsRecordModel({
    required this.id,
    required this.name,
    required this.type,
    required this.content,
    required this.ttl,
    this.priority,
    this.proxied,
    this.status,
    this.createdAt,
    this.modifiedAt,
    Map<String, dynamic>? raw,
  }) : _raw = raw ?? {};

  Map<String, dynamic> toMap() => _raw;

  String get typeString {
    switch (type) {
      case DnsRecordType.a: return 'A';
      case DnsRecordType.aaaa: return 'AAAA';
      case DnsRecordType.cname: return 'CNAME';
      case DnsRecordType.mx: return 'MX';
      case DnsRecordType.txt: return 'TXT';
      case DnsRecordType.ns: return 'NS';
      case DnsRecordType.srv: return 'SRV';
      case DnsRecordType.caa: return 'CAA';
      case DnsRecordType.other: return 'OTHER';
    }
  }

  factory DnsRecordModel.fromMap(Map<String, dynamic> map) {
    final typeStr = (map['type'] ?? 'A').toString().toUpperCase();
    DnsRecordType type;
    switch (typeStr) {
      case 'A': type = DnsRecordType.a; break;
      case 'AAAA': type = DnsRecordType.aaaa; break;
      case 'CNAME': type = DnsRecordType.cname; break;
      case 'MX': type = DnsRecordType.mx; break;
      case 'TXT': type = DnsRecordType.txt; break;
      case 'NS': type = DnsRecordType.ns; break;
      case 'SRV': type = DnsRecordType.srv; break;
      case 'CAA': type = DnsRecordType.caa; break;
      default: type = DnsRecordType.other;
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is int) return val > 10000000000 ? DateTime.fromMillisecondsSinceEpoch(val, isUtc: true) : null;
      final s = val.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    final ttlVal = map['ttl'];
    int ttl = 3600;
    if (ttlVal is int) {
      ttl = ttlVal;
    } else if (ttlVal != null) {
      ttl = int.tryParse(ttlVal.toString()) ?? 3600;
    }

    return DnsRecordModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      type: type,
      content: map['content']?.toString() ?? '',
      ttl: ttl,
      priority: map['priority'] as int?,
      proxied: map['proxied'] as bool?,
      status: map['status']?.toString(),
      createdAt: parseDate(map['created_at'] ?? map['created_on']),
      modifiedAt: parseDate(map['updated_at'] ?? map['modified_on']),
      raw: Map<String, dynamic>.from(map),
    );
  }
}