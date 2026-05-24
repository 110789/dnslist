import 'package:flutter/foundation.dart';
import '../utils/log/log.dart';
import 'credential_storage.dart';

class CredentialState extends ChangeNotifier {
  final CredentialStorage _storage;
  List<CredentialModel> _credentials = [];
  String? _selectedCredentialId;
  List<CredentialModel>? _sortedCredentials;
  bool _dirty = true;
  bool _isInitialized = false;

  CredentialState(this._storage);

  Future<void> init() async {
    if (_isInitialized) return;
    LogService.instance.info(
      module: 'services',
      className: 'CredentialState',
      methodName: 'init',
      action: '凭证状态初始化',
      status: 'pending',
    );
    await loadCredentials();
    _isInitialized = true;
    LogService.instance.info(
      module: 'services',
      className: 'CredentialState',
      methodName: 'init',
      action: '凭证状态初始化完成',
      data: {'count': _credentials.length, 'selectedId': _selectedCredentialId},
      status: 'success',
    );
  }

  List<CredentialModel> get credentials {
    if (_sortedCredentials == null || _dirty) {
      _sortedCredentials = List<CredentialModel>.from(_credentials)
        ..sort((a, b) => a.order.compareTo(b.order));
      _dirty = false;
    }
    return _sortedCredentials!;
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
      _dirty = true;
      _selectedCredentialId = credentials.first.id;
    } else if (_selectedCredentialId != null) {
      final exists = _credentials.any((c) => c.id == _selectedCredentialId);
      if (!exists && _credentials.isNotEmpty) {
        _dirty = true;
        _selectedCredentialId = credentials.first.id;
      }
    }
    notifyListeners();
  }

  Future<void> addCredential(CredentialModel credential) async {
    LogService.instance.info(
      module: 'services',
      className: 'CredentialState',
      methodName: 'addCredential',
      action: '添加凭证',
      data: {'providerId': credential.providerId, 'providerName': credential.providerName},
      status: 'pending',
    );
    final maxOrder = _credentials.isEmpty ? 0 : _credentials.map((c) => c.order).reduce((a, b) => a > b ? a : b);
    final newCredential = credential.copyWith(order: maxOrder + 1);
    await _storage.add(newCredential);
    _credentials.add(newCredential);
    _selectedCredentialId = newCredential.id;
    _dirty = true;
    notifyListeners();
    LogService.instance.info(
      module: 'services',
      className: 'CredentialState',
      methodName: 'addCredential',
      action: '添加凭证成功',
      data: {'credentialId': newCredential.id},
      status: 'success',
    );
  }

  Future<void> removeCredential(String id) async {
    await _storage.remove(id);
    _credentials.removeWhere((e) => e.id == id);
    if (_selectedCredentialId == id) {
      if (_credentials.isNotEmpty) {
        _dirty = true;
        _selectedCredentialId = credentials.first.id;
      } else {
        _selectedCredentialId = null;
      }
    }
    _dirty = true;
    notifyListeners();
  }

  Future<void> updateCredential(CredentialModel credential) async {
    await _storage.update(credential);
    final index = _credentials.indexWhere((e) => e.id == credential.id);
    if (index != -1) {
      _credentials[index] = credential;
      _dirty = true;
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
    _dirty = true;
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