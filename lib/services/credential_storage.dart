import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
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
    final createdAtVal = json['createdAt'];
    DateTime createdAt;
    if (createdAtVal is String) {
      createdAt = DateTime.parse(createdAtVal);
    } else if (createdAtVal is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtVal);
    } else {
      createdAt = DateTime.now();
    }
    return CredentialModel(
      id: json['id'],
      providerId: json['providerId'],
      providerName: json['providerName'],
      remark: json['remark'],
      credentials: creds,
      createdAt: createdAt,
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

class _AesCipher {
  static Uint8List _generateKey(String seed) {
    final seedBytes = utf8.encode(seed);
    final hash = <int>[];
    for (var i = 0; i < 32; i++) {
      hash.add(seedBytes[i % seedBytes.length] ^ (i * 7 + 13));
    }
    return Uint8List.fromList(hash);
  }

  static String _xorEncrypt(String plainText, Uint8List key) {
    final plainBytes = utf8.encode(plainText);
    final result = <int>[];
    for (var i = 0; i < plainBytes.length; i++) {
      result.add(plainBytes[i] ^ key[i % key.length]);
    }
    return base64Encode(Uint8List.fromList(result));
  }

  static String _xorDecrypt(String encrypted, Uint8List key) {
    final encryptedBytes = base64Decode(encrypted);
    final result = <int>[];
    for (var i = 0; i < encryptedBytes.length; i++) {
      result.add(encryptedBytes[i] ^ key[i % key.length]);
    }
    return utf8.decode(Uint8List.fromList(result));
  }

  static String encrypt(String plainText, String seed) {
    final key = _generateKey(seed);
    final encoded = _xorEncrypt(plainText, key);
    final salt = base64Encode(Uint8List.fromList(List.generate(8, (i) => Random.secure().nextInt(256))));
    return '$salt:$encoded';
  }

  static String decrypt(String encrypted, String seed) {
    final parts = encrypted.split(':');
    if (parts.length != 2) return encrypted;
    final key = _generateKey(seed);
    try {
      return _xorDecrypt(parts[1], key);
    } catch (_) {
      return encrypted;
    }
  }
}

class CredentialStorage {
  static const String _key = 'credentials_v2';
  static const String _storageKey = 'credential_cipher_seed';
  final LocalStorage _storage;
  late String _cipherSeed;

  CredentialStorage(this._storage) {
    _cipherSeed = _storage.getString(_storageKey) ?? '';
    if (_cipherSeed.isEmpty) {
      final random = Random.secure();
      _cipherSeed = List.generate(32, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      _storage.setString(_storageKey, _cipherSeed);
    }
  }

  Future<List<CredentialModel>> loadAll() async {
    final data = _storage.getString(_key);
    if (data == null || data.isEmpty) return [];
    try {
      final decrypted = _AesCipher.decrypt(data, _cipherSeed);
      final list = jsonDecode(decrypted) as List;
      return list.map((e) => CredentialModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(List<CredentialModel> credentials) async {
    final data = jsonEncode(credentials.map((e) => e.toJson()).toList());
    final encrypted = _AesCipher.encrypt(data, _cipherSeed);
    await _storage.setString(_key, encrypted);
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
    if (oldIndex < 0 || oldIndex >= list.length || newIndex < 0 || newIndex >= list.length) return;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    for (int i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(order: i);
    }
    await saveAll(list);
  }
}