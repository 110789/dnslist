import 'dart:convert';
import '../utils/storage/local_storage.dart';

class CredentialModel {
  final String id;
  final String providerId;
  final String providerName;
  final Map<String, String> credentials;
  final DateTime createdAt;

  CredentialModel({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.credentials,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'providerName': providerName,
      'credentials': credentials,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CredentialModel.fromJson(Map<String, dynamic> json) {
    return CredentialModel(
      id: json['id'],
      providerId: json['providerId'],
      providerName: json['providerName'],
      credentials: Map<String, String>.from(json['credentials']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  CredentialModel copyWith({
    String? id,
    String? providerId,
    String? providerName,
    Map<String, String>? credentials,
    DateTime? createdAt,
  }) {
    return CredentialModel(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      credentials: credentials ?? this.credentials,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CredentialStorage {
  static const String _key = 'credentials';
  final LocalStorage _storage;

  CredentialStorage(this._storage);

  Future<List<CredentialModel>> loadAll() async {
    final data = _storage.getString(_key);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => CredentialModel.fromJson(e)).toList();
  }

  Future<void> saveAll(List<CredentialModel> credentials) async {
    final data = jsonEncode(credentials.map((e) => e.toJson()).toList());
    await _storage.setString(_key, data);
  }

  Future<void> add(CredentialModel credential) async {
    final list = await loadAll();
    list.add(credential);
    await saveAll(list);
  }

  Future<void> remove(String id) async {
    final list = await loadAll();
    list.removeWhere((e) => e.id == id);
    await saveAll(list);
  }

  Future<CredentialModel?> getById(String id) async {
    final list = await loadAll();
    try {
      return list.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> update(CredentialModel credential) async {
    final list = await loadAll();
    final index = list.indexWhere((e) => e.id == credential.id);
    if (index != -1) {
      list[index] = credential;
      await saveAll(list);
    }
  }
}