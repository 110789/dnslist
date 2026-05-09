import 'dart:convert';

class CredentialModel {
  final String id;
  final String providerId;
  final String providerName;
  final String? remark;
  final Map<String, String> credentials;
  final DateTime createdAt;
  final int order;

  CredentialModel({
    required this.id,
    required this.providerId,
    required this.providerName,
    this.remark,
    required this.credentials,
    required this.createdAt,
    this.order = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'providerId': providerId,
    'providerName': providerName,
    'remark': remark,
    'credentials': credentials,
    'createdAt': createdAt.toIso8601String(),
    'order': order,
  };

  factory CredentialModel.fromJson(Map<String, dynamic> json) {
    final credsRaw = json['credentials'];
    Map<String, String> creds;
    if (credsRaw is Map) {
      creds = credsRaw.map((k, v) => MapEntry(k.toString(), v.toString()));
    } else if (credsRaw is String) {
      final decoded = jsonDecode(credsRaw) as Map;
      creds = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
    } else {
      creds = {};
    }
    return CredentialModel(
      id: json['id'],
      providerId: json['providerId'],
      providerName: json['providerName'],
      remark: json['remark'],
      credentials: creds,
      createdAt: json['createdAt'] is String
        ? DateTime.parse(json['createdAt'])
        : DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      order: json['order'] ?? 0,
    );
  }

  CredentialModel copyWith({
    String? id,
    String? providerId,
    String? providerName,
    String? remark,
    Map<String, String>? credentials,
    DateTime? createdAt,
    int? order,
  }) => CredentialModel(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    providerName: providerName ?? this.providerName,
    remark: remark ?? this.remark,
    credentials: credentials ?? this.credentials,
    createdAt: createdAt ?? this.createdAt,
    order: order ?? this.order,
  );
}