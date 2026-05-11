import 'package:flutter/foundation.dart';
import '../drivers/driver_factory.dart';
import '../drivers/driver_manager.dart';

enum LoadingState {
  idle,
  loading,
  refreshing,
  operating,
}

class CredentialInfo {
  final String providerId;
  final Map<String, String> credentials;
  CredentialInfo({required this.providerId, required this.credentials});
}

class DomainState extends ChangeNotifier {
  List<Map<String, dynamic>> _domains = [];
  Map<String, List<Map<String, dynamic>>> _dnsRecords = {};
  LoadingState _loadingState = LoadingState.idle;
  String? _error;
  String? _errorCode;
  String? _selectedDomainId;

  bool _refreshLock = false;
  bool _isFirstLoad = true;

  DomainState();

  List<Map<String, dynamic>> get domains => _domains;
  Map<String, List<Map<String, dynamic>>> get dnsRecords => _dnsRecords;

  LoadingState get loadingState => _loadingState;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get isRefreshing => _loadingState == LoadingState.refreshing;
  bool get isOperating => _loadingState == LoadingState.operating;
  bool get isIdle => _loadingState == LoadingState.idle;

  bool get showCenterLoading => _loadingState == LoadingState.loading || _loadingState == LoadingState.operating;

  String? get error => _error;
  String? get errorCode => _errorCode;
  String? get selectedDomainId => _selectedDomainId;

  List<Map<String, dynamic>> get currentDnsRecords {
    if (_selectedDomainId == null) return [];
    return _dnsRecords[_selectedDomainId] ?? [];
  }

  void _setLoadingState(LoadingState state) {
    _loadingState = state;
    notifyListeners();
  }

  void _setError(String? error, String? errorCode) {
    _error = error;
    _errorCode = errorCode;
  }

  void _clearError() {
    _error = null;
    _errorCode = null;
  }

  void _updateCurrentCredential(String providerId, Map<String, String> credentials) {
    _currentProviderId = providerId;
    _currentCredentials = credentials;
  }

  String? _currentProviderId;
  Map<String, String>? _currentCredentials;

  Future<Map<String, dynamic>> refreshDomainList({
    required String providerId,
    required Map<String, String> credentials,
    bool isManual = false,
  }) async {
    if (_refreshLock) return {'success': false, 'error': '刷新中', 'errorCode': 'REFRESH_LOCKED'};
    _refreshLock = true;
    _updateCurrentCredential(providerId, credentials);

    _clearError();
    
    if (isManual) {
      _setLoadingState(LoadingState.refreshing);
    } else {
      _domains = [];
      _setLoadingState(LoadingState.loading);
    }

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        final result = <String, dynamic>{'success': false, 'error': 'Provider not found', 'errorCode': 'PROVIDER_NOT_FOUND', 'statusCode': 404};
        _setError(result['error'] as String, result['errorCode'] as String);
        _setLoadingState(LoadingState.idle);
        return result;
      }

      final valid = await driver.validateCredential(credentials);
      if (!valid) {
        final result = <String, dynamic>{'success': false, 'error': '凭证无效或权限不足', 'errorCode': 'AUTH_FAILED', 'statusCode': 401};
        _setError(result['error'] as String, result['errorCode'] as String);
        _setLoadingState(LoadingState.idle);
        return result;
      }

      final result = await driver.getDomains();

      if (result['error'] != null) {
        final errorCode = result['errorCode'] ?? 'UNKNOWN';
        final errorMessage = result['error'] ?? '操作失败';
        _setError(errorMessage, errorCode);
        _setLoadingState(LoadingState.idle);
        return {'success': false, 'error': errorMessage, 'errorCode': errorCode, 'statusCode': result['statusCode']};
      }

      _domains = List<Map<String, dynamic>>.from(result['domains'] ?? []);
      DriverManager().setCredential(providerId, credentials);
      _isFirstLoad = false;
      _setLoadingState(LoadingState.idle);
      return {'success': true, 'statusCode': result['statusCode'] ?? 'OK'};
    } catch (e) {
      _setError(e.toString(), 'EXCEPTION');
      _setLoadingState(LoadingState.idle);
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    } finally {
      _refreshLock = false;
    }
  }

  Future<Map<String, dynamic>> refreshDnsRecordList({
    required String providerId,
    required String domainId,
    required Map<String, String> credentials,
    bool isManual = false,
  }) async {
    if (_refreshLock) return {'success': false, 'error': '刷新中', 'errorCode': 'REFRESH_LOCKED'};
    _refreshLock = true;

    _clearError();

    if (isManual) {
      _setLoadingState(LoadingState.refreshing);
    } else {
      _dnsRecords[domainId] = [];
      _setLoadingState(LoadingState.loading);
    }

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        final result = <String, dynamic>{'success': false, 'error': 'Provider not found', 'errorCode': 'PROVIDER_NOT_FOUND', 'statusCode': 404};
        _setError(result['error'] as String, result['errorCode'] as String);
        _setLoadingState(LoadingState.idle);
        return result;
      }

      final result = await driver.getDnsRecords(domainId);

      if (result['error'] != null) {
        final errorCode = result['errorCode'] ?? 'UNKNOWN';
        final errorMessage = result['error'] ?? '操作失败';
        _setError(errorMessage, errorCode);
        _setLoadingState(LoadingState.idle);
        return {'success': false, 'error': errorMessage, 'errorCode': errorCode, 'statusCode': result['statusCode']};
      }

      _dnsRecords[domainId] = List<Map<String, dynamic>>.from(result['records'] ?? []);
      _selectedDomainId = domainId;
      _isFirstLoad = false;
      _setLoadingState(LoadingState.idle);
      return {'success': true, 'statusCode': result['statusCode'] ?? 'OK'};
    } catch (e) {
      _setError(e.toString(), 'EXCEPTION');
      _setLoadingState(LoadingState.idle);
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    } finally {
      _refreshLock = false;
    }
  }

  Future<Map<String, dynamic>> addDomain(String providerId, Map<String, dynamic> domainData, Map<String, String> credentials) async {
    _setLoadingState(LoadingState.operating);

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        _setLoadingState(LoadingState.idle);
        return {'success': false, 'error': 'Provider not found', 'errorCode': 'PROVIDER_NOT_FOUND', 'statusCode': 404};
      }

      final result = await driver.createDomain(domainData);

      if (result['error'] != null) {
        _setLoadingState(LoadingState.idle);
        return {'success': false, 'error': result['error'], 'errorCode': result['errorCode'] ?? 'UNKNOWN', 'statusCode': result['statusCode']};
      }

      await refreshDomainList(providerId: providerId, credentials: credentials);
      return {'success': true, 'statusCode': 'OK', 'data': result['data']};
    } catch (e) {
      _setLoadingState(LoadingState.idle);
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  Future<Map<String, dynamic>> deleteDomain(String providerId, String domainId, Map<String, String> credentials) async {
    _setLoadingState(LoadingState.operating);

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        _setLoadingState(LoadingState.idle);
        return {'success': false, 'error': 'Provider not found', 'errorCode': 'PROVIDER_NOT_FOUND', 'statusCode': 404};
      }

      final result = await driver.deleteDomain(domainId);

      if (result['success'] == true) {
        await refreshDomainList(providerId: providerId, credentials: credentials);
        return {'success': true, 'statusCode': 'OK'};
      }

      _setLoadingState(LoadingState.idle);
      return result;
    } catch (e) {
      _setLoadingState(LoadingState.idle);
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  Future<Map<String, dynamic>> renewDomain(String providerId, String domainId, Map<String, String> credentials) async {
    _setLoadingState(LoadingState.operating);

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        _setLoadingState(LoadingState.idle);
        return {'success': false, 'error': 'Provider not found', 'errorCode': 'PROVIDER_NOT_FOUND', 'statusCode': 404};
      }

      final result = await driver.renewDomain(domainId);

      if (result['error'] != null) {
        _setLoadingState(LoadingState.idle);
        return {'success': false, 'error': result['error'], 'errorCode': result['errorCode'] ?? 'UNKNOWN', 'statusCode': result['statusCode']};
      }

      await refreshDomainList(providerId: providerId, credentials: credentials);
      return {'success': true, 'statusCode': 'OK', 'data': result['data']};
    } catch (e) {
      _setLoadingState(LoadingState.idle);
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  Future<Map<String, dynamic>> createDnsRecord(String providerId, String domainId, Map<String, dynamic> recordData, Map<String, String> credentials) async {
    _setLoadingState(LoadingState.operating);

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        _setLoadingState(LoadingState.idle);
        return {'success': false, 'error': 'Provider not found', 'errorCode': 'PROVIDER_NOT_FOUND', 'statusCode': 404};
      }

      final result = await driver.createDnsRecord(domainId, recordData);

      if (result['error'] != null) {
        _setLoadingState(LoadingState.idle);
        return {'success': false, 'error': result['error'], 'errorCode': result['errorCode'] ?? 'UNKNOWN', 'statusCode': result['statusCode']};
      }

      await refreshDnsRecordList(providerId: providerId, domainId: domainId, credentials: credentials);
      return {'success': true, 'statusCode': 'OK', 'data': result['data']};
    } catch (e) {
      _setLoadingState(LoadingState.idle);
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  Future<Map<String, dynamic>> updateDnsRecord(String providerId, String domainId, String recordId, Map<String, dynamic> recordData, Map<String, String> credentials) async {
    _setLoadingState(LoadingState.operating);

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        _setLoadingState(LoadingState.idle);
        return {'success': false, 'error': 'Provider not found', 'errorCode': 'PROVIDER_NOT_FOUND', 'statusCode': 404};
      }

      final result = await driver.updateDnsRecord(domainId, recordId, recordData);

      if (result['error'] != null) {
        _setLoadingState(LoadingState.idle);
        return {'success': false, 'error': result['error'], 'errorCode': result['errorCode'] ?? 'UNKNOWN', 'statusCode': result['statusCode']};
      }

      await refreshDnsRecordList(providerId: providerId, domainId: domainId, credentials: credentials);
      return {'success': true, 'statusCode': 'OK', 'data': result['data']};
    } catch (e) {
      _setLoadingState(LoadingState.idle);
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  Future<Map<String, dynamic>> deleteDnsRecord(String providerId, String domainId, String recordId, Map<String, String> credentials) async {
    _setLoadingState(LoadingState.operating);

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        _setLoadingState(LoadingState.idle);
        return {'success': false, 'error': 'Provider not found', 'errorCode': 'PROVIDER_NOT_FOUND', 'statusCode': 404};
      }

      final result = await driver.deleteDnsRecord(domainId, recordId);

      if (result['success'] == true) {
        await refreshDnsRecordList(providerId: providerId, domainId: domainId, credentials: credentials);
        return {'success': true, 'statusCode': 'OK'};
      }

      _setLoadingState(LoadingState.idle);
      return result;
    } catch (e) {
      _setLoadingState(LoadingState.idle);
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  void clear() {
    _domains = [];
    _dnsRecords = {};
    _selectedDomainId = null;
    _clearError();
    _setLoadingState(LoadingState.idle);
  }

  void clearError() {
    _error = null;
    _errorCode = null;
    notifyListeners();
  }
}
