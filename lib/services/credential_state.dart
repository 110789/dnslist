import 'package:flutter/foundation.dart';
import 'credential_storage.dart';

class CredentialState extends ChangeNotifier {
  final CredentialStorage _storage;
  List<CredentialModel> _credentials = [];
  String? _selectedCredentialId;

  CredentialState(this._storage);

  List<CredentialModel> get credentials {
    final sorted = List<CredentialModel>.from(_credentials);
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }

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
    _selectedCredentialId = await _storage.getSelectedIdAsync();
    if (_credentials.isNotEmpty && _selectedCredentialId == null) {
      final sorted = List<CredentialModel>.from(_credentials);
      sorted.sort((a, b) => a.order.compareTo(b.order));
      _selectedCredentialId = sorted.first.id;
    } else if (_selectedCredentialId != null) {
      final exists = _credentials.any((c) => c.id == _selectedCredentialId);
      if (!exists && _credentials.isNotEmpty) {
        final sorted = List<CredentialModel>.from(_credentials);
        sorted.sort((a, b) => a.order.compareTo(b.order));
        _selectedCredentialId = sorted.first.id;
      }
    }
    notifyListeners();
  }

  Future<void> addCredential(CredentialModel credential) async {
    final maxOrder = _credentials.isEmpty ? 0 : _credentials.map((c) => c.order).reduce((a, b) => a > b ? a : b);
    final newCredential = credential.copyWith(order: maxOrder + 1);
    await _storage.add(newCredential);
    _credentials.add(newCredential);
    _selectedCredentialId = newCredential.id;
    notifyListeners();
  }

  Future<void> removeCredential(String id) async {
    await _storage.remove(id);
    _credentials.removeWhere((e) => e.id == id);
    if (_selectedCredentialId == id) {
      if (_credentials.isNotEmpty) {
        final sorted = List<CredentialModel>.from(_credentials);
        sorted.sort((a, b) => a.order.compareTo(b.order));
        _selectedCredentialId = sorted.first.id;
      } else {
        _selectedCredentialId = null;
      }
    }
    notifyListeners();
  }

  Future<void> updateCredential(CredentialModel credential) async {
    await _storage.update(credential);
    final index = _credentials.indexWhere((e) => e.id == credential.id);
    if (index != -1) {
      _credentials[index] = credential;
      notifyListeners();
    }
  }

  Future<void> reorderCredentials(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final sortedList = credentials;
    final item = sortedList.removeAt(oldIndex);
    sortedList.insert(newIndex, item);

    _credentials = _credentials.map((c) {
      final newIndex = sortedList.indexWhere((s) => s.id == c.id);
      if (newIndex != -1) {
        return c.copyWith(order: newIndex);
      }
      return c;
    }).toList();

    await _storage.saveOrder(_credentials);
  }

  void selectCredential(String id) {
    _selectedCredentialId = id;
    _storage.saveSelectedId(id);
    notifyListeners();
  }

  bool get hasCredentials => _credentials.isNotEmpty;

  bool get hasSelected => _selectedCredentialId != null;

  String? get selectedProviderId => selectedCredential?.providerId;
}