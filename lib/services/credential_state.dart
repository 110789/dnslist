import 'package:flutter/foundation.dart';
import 'credential_storage.dart';

class CredentialState extends ChangeNotifier {
  final CredentialStorage _storage;
  List<CredentialModel> _credentials = [];
  String? _selectedCredentialId;

  CredentialState(this._storage);

  List<CredentialModel> get credentials => _credentials;
  String? get selectedCredentialId => _selectedCredentialId;

  CredentialModel? get selectedCredential {
    if (_selectedCredentialId == null) return null;
    try {
      return _credentials.firstWhere((c) => c.id == _selectedCredentialId);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadCredentials() async {
    _credentials = await _storage.loadAll();
    if (_credentials.isNotEmpty && _selectedCredentialId == null) {
      _selectedCredentialId = _credentials.first.id;
    } else if (_selectedCredentialId != null) {
      final exists = _credentials.any((c) => c.id == _selectedCredentialId);
      if (!exists && _credentials.isNotEmpty) {
        _selectedCredentialId = _credentials.first.id;
      }
    }
    notifyListeners();
  }

  Future<void> addCredential(CredentialModel credential) async {
    await _storage.add(credential);
    await loadCredentials();
    _selectedCredentialId = credential.id;
    notifyListeners();
  }

  Future<void> removeCredential(String id) async {
    await _storage.remove(id);
    if (_selectedCredentialId == id) {
      _selectedCredentialId = _credentials.isNotEmpty ? _credentials.first.id : null;
    }
    await loadCredentials();
  }

  Future<void> updateCredential(CredentialModel credential) async {
    await _storage.update(credential);
    await loadCredentials();
  }

  void selectCredential(String id) {
    _selectedCredentialId = id;
    notifyListeners();
  }

  bool get hasCredentials => _credentials.isNotEmpty;

  bool get hasSelected => _selectedCredentialId != null;
}