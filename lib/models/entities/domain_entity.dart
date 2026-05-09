class DomainEntity {
  final String id;
  final String name;
  final String status;
  final String? provider;
  final Map<String, dynamic>? extra;

  DomainEntity({
    required this.id,
    required this.name,
    required this.status,
    this.provider,
    this.extra,
  });
}