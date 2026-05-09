class DomainDto {
  final String name;
  final String? status;
  final String? type;

  DomainDto({
    required this.name,
    this.status,
    this.type,
  });
}