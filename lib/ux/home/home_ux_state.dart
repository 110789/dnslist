import 'package:flutter/widgets.dart';
import '../../models/credential_model.dart';

abstract class HomeUxStateDelegate {
  void onCredentialSelected(CredentialModel credential);
  void onCredentialAdded(CredentialModel credential);
  void onCredentialUpdated(CredentialModel credential);
  void onCredentialDeleted(String credentialId);
  void onDomainRefreshRequested();
  void onDomainOperationStart();
  void onDomainOperationEnd();
}

class HomeUxState extends ChangeNotifier {
  final HomeUxStateDelegate? _delegate;

  List<CredentialModel> _credentials = [];
  CredentialModel? _selectedCredential;
  bool _hasCredentials = false;
  bool _isInitialized = false;
  String? _error;
  String? _errorCode;

  HomeUxState({HomeUxStateDelegate? delegate}) : _delegate = delegate;

  List<CredentialModel> get credentials => _credentials;
  CredentialModel? get selectedCredential => _selectedCredential;
  bool get hasCredentials => _hasCredentials;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  String? get errorCode => _errorCode;

  void updateCredentials(List<CredentialModel> credentials) {
    _credentials = credentials;
    _hasCredentials = credentials.isNotEmpty;
    notifyListeners();
  }

  void updateSelectedCredential(CredentialModel? credential) {
    _selectedCredential = credential;
    notifyListeners();
  }

  void setInitialized(bool value) {
    _isInitialized = value;
    notifyListeners();
  }

  void setError(String? error, String? errorCode) {
    _error = error;
    _errorCode = errorCode;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _errorCode = null;
    notifyListeners();
  }

  void selectCredential(String credentialId) {
    final credential = _credentials.firstWhere(
      (c) => c.id == credentialId,
      orElse: () => _credentials.first,
    );
    _selectedCredential = credential;
    _delegate?.onCredentialSelected(credential);
    notifyListeners();
  }

  void requestDomainRefresh() {
    _delegate?.onDomainRefreshRequested();
  }

  void notifyOperationStart() {
    _delegate?.onDomainOperationStart();
  }

  void notifyOperationEnd() {
    _delegate?.onDomainOperationEnd();
  }
}

class DomainListUxState extends ChangeNotifier {
  List<Map<String, dynamic>> _domains = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isEmpty = false;
  String? _error;
  String? _errorCode;

  List<Map<String, dynamic>> get domains => _domains;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isEmpty => _isEmpty;
  bool get showCenterLoading => _isLoading || _isRefreshing;
  bool get hasError => _error != null;
  String? get error => _error;
  String? get errorCode => _errorCode;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setRefreshing(bool value) {
    _isRefreshing = value;
    notifyListeners();
  }

  void setDomains(List<Map<String, dynamic>> domains) {
    _domains = domains;
    _isEmpty = domains.isEmpty;
    notifyListeners();
  }

  void setError(String? error, String? errorCode) {
    _error = error;
    _errorCode = errorCode;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _errorCode = null;
    notifyListeners();
  }

  void clear() {
    _domains = [];
    _isEmpty = false;
    _error = null;
    _errorCode = null;
    notifyListeners();
  }
}