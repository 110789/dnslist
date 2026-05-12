import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import '../utils/storage/local_storage.dart';
import '../models/credential_model.dart';
import '../database/repositories/credential_repository.dart';

export '../models/credential_model.dart';

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
  static const String _selectedIdKey = 'selected_credential_id';
  final LocalStorage _storage;
  final CredentialRepository? _repository;
  late String _cipherSeed;
  bool _useSQLite = false;

  CredentialStorage(this._storage, {CredentialRepository? repository})
      : _repository = repository {
    _useSQLite = _repository != null;
  }

  Future<void> ensureCipherSeed() async {
    _cipherSeed = _storage.getString(_storageKey) ?? '';
    if (_cipherSeed.isEmpty) {
      final random = Random.secure();
      _cipherSeed = List.generate(32, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await _storage.setString(_storageKey, _cipherSeed);
    }
  }

  Future<List<CredentialModel>> loadAll() async {
    if (_useSQLite && _repository != null) {
      return await _repository!.loadAll();
    }

    await ensureCipherSeed();
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
    if (_useSQLite && _repository != null) {
      await _repository!.saveAll(credentials);
      return;
    }

    final data = jsonEncode(credentials.map((e) => e.toJson()).toList());
    final encrypted = _AesCipher.encrypt(data, _cipherSeed);
    await _storage.setString(_key, encrypted);
  }

  Future<void> add(CredentialModel credential) async {
    if (_useSQLite && _repository != null) {
      await _repository!.add(credential);
      return;
    }

    final list = await loadAll();
    list.add(credential);
    await saveAll(list);
  }

  Future<void> remove(String id) async {
    if (_useSQLite && _repository != null) {
      await _repository!.remove(id);
      return;
    }

    final list = await loadAll();
    list.removeWhere((e) => e.id == id);
    await saveAll(list);
  }

  Future<CredentialModel?> getById(String id) async {
    if (_useSQLite && _repository != null) {
      return await _repository!.getById(id);
    }

    final list = await loadAll();
    try {
      return list.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> update(CredentialModel credential) async {
    if (_useSQLite && _repository != null) {
      await _repository!.update(credential);
      return;
    }

    final list = await loadAll();
    final index = list.indexWhere((e) => e.id == credential.id);
    if (index != -1) {
      list[index] = credential;
      await saveAll(list);
    }
  }

  Future<void> saveOrder(List<CredentialModel> credentials) async {
    if (_useSQLite && _repository != null) {
      await _repository!.saveOrder(credentials);
      return;
    }

    await saveAll(credentials);
  }

  Future<void> saveSelectedId(String? id) async {
    if (_useSQLite && _repository != null) {
      await _repository!.saveSelectedId(id);
      return;
    }

    if (id == null) {
      await _storage.remove(_selectedIdKey);
    } else {
      await _storage.setString(_selectedIdKey, id);
    }
  }

  String? getSelectedId() {
    if (_useSQLite && _repository != null) {
      return null;
    }
    return _storage.getString(_selectedIdKey);
  }

  Future<String?> getSelectedIdAsync() async {
    if (_useSQLite && _repository != null) {
      return await _repository!.getSelectedId();
    }
    return _storage.getString(_selectedIdKey);
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (_useSQLite && _repository != null) {
      await _repository!.reorder(oldIndex, newIndex);
      return;
    }

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