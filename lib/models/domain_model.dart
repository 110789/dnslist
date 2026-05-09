enum DomainStatus {
  active,
  pending,
  expired,
  suspended,
  deleted,
  unknown,
}

class DomainModel {
  final String id;
  final String name;
  final DomainStatus status;
  final String? type;
  final bool? paused;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final Map<String, dynamic> _raw;

  DomainModel({
    required this.id,
    required this.name,
    required this.status,
    this.type,
    this.paused,
    this.createdAt,
    this.modifiedAt,
    Map<String, dynamic>? raw,
  }) : _raw = raw ?? {};

  Map<String, dynamic> toMap() => _raw;

  factory DomainModel.fromMap(Map<String, dynamic> map) {
    final statusStr = (map['status'] ?? '').toString().toLowerCase();
    DomainStatus status;
    switch (statusStr) {
      case 'active': case '活跃': status = DomainStatus.active; break;
      case 'pending': case '待处理': status = DomainStatus.pending; break;
      case 'expired': case '已过期': status = DomainStatus.expired; break;
      case 'suspended': case '已暂停': status = DomainStatus.suspended; break;
      case 'deleted': case '已删除': status = DomainStatus.deleted; break;
      default: status = DomainStatus.unknown;
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is int) return val > 10000000000 ? DateTime.fromMillisecondsSinceEpoch(val, isUtc: true) : null;
      final s = val.toString();
      if (s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return DomainModel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      status: status,
      type: map['type']?.toString(),
      paused: map['paused'] as bool?,
      createdAt: parseDate(map['created_at'] ?? map['created_on']),
      modifiedAt: parseDate(map['updated_at'] ?? map['modified_on']),
      raw: Map<String, dynamic>.from(map),
    );
  }

  String get statusLabel {
    switch (status) {
      case DomainStatus.active: return '活跃';
      case DomainStatus.pending: return '待处理';
      case DomainStatus.expired: return '已过期';
      case DomainStatus.suspended: return '已暂停';
      case DomainStatus.deleted: return '已删除';
      case DomainStatus.unknown: return '未知';
    }
  }
}