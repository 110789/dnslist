import 'dart:convert';
import '../utils/storage/local_storage.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerId': providerId,
      'providerName': providerName,
      'remark': remark,
      'credentials': credentials,
      'createdAt': createdAt.toIso8601String(),
      'order': order,
    };
  }

  factory CredentialModel.fromJson(Map<String, dynamic> json) {
    return CredentialModel(
      id: json['id'],
      providerId: json['providerId'],
      providerName: json['providerName'],
      remark: json['remark'],
      credentials: Map<String, String>.from(json['credentials'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
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
  }) {
    return CredentialModel(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      remark: remark ?? this.remark,
      credentials: credentials ?? this.credentials,
      createdAt: createdAt ?? this.createdAt,
      order: order ?? this.order,
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

  Future<void> saveOrder(List<CredentialModel> credentials) async {
    await saveAll(credentials);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final list = await loadAll();
    if (oldIndex < 0 || oldIndex >= list.length || newIndex < 0 || newIndex >= list.length) {
      return;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    for (int i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(order: i);
    }
    await saveAll(list);
  }
}