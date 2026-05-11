import 'package:flutter/foundation.dart';
import '../drivers/driver_factory.dart';
import '../core/refresh/refresh_core.dart';

enum LoadingState {
  idle,
  loading,
  refreshing,
  operating,
}

class NewDomainState extends ChangeNotifier {
  List<Map<String, dynamic>> _domains = [];
  Map<String, List<Map<String, dynamic>>> _dnsRecords = {};
  LoadingState _loadingState = LoadingState.idle;
  String? _error;
  String? _errorCode;
  String? _selectedDomainId;
  bool _isManualRefreshing = false;

  final DomainRefreshCore _refreshCore = DomainRefreshCore();

  NewDomainState();

  List<Map<String, dynamic>> get domains => _domains;
  Map<String, List<Map<String, dynamic>>> get dnsRecords => _dnsRecords;

  LoadingState get loadingState => _loadingState;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get isRefreshing => _loadingState == LoadingState.refreshing;
  bool get isOperating => _loadingState == LoadingState.operating;
  bool get isIdle => _loadingState == LoadingState.idle;
  bool get isManualRefreshing => _isManualRefreshing;

  bool get showCenterLoading =>
      _loadingState == LoadingState.loading ||
      _loadingState == LoadingState.operating;

  String? get error => _error;
  String? get errorCode => _errorCode;
  String? get selectedDomainId => _selectedDomainId;

  bool get isDomainRefreshing => _refreshCore.isDomainRefreshing;
  bool get isDnsRecordRefreshing => _refreshCore.isDnsRecordRefreshing;

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

  Future<RefreshResult> _fetchDomainList({
    required String providerId,
    required Map<String, String> credentials,
  }) async {
    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        return RefreshResult.fail(
          error: 'Provider not found',
          errorCode: 'PROVIDER_NOT_FOUND',
        );
      }

      final valid = await driver.validateCredential(credentials);
      if (!valid) {
        return RefreshResult.fail(
          error: '凭证无效或权限不足',
          errorCode: 'AUTH_FAILED',
        );
      }

      final result = await driver.getDomains();

      if (result['error'] != null) {
        final errorCode = result['errorCode'] ?? 'UNKNOWN';
        final errorMessage = result['error'] ?? '操作失败';
        _setError(errorMessage, errorCode);
        return RefreshResult.fail(
          error: errorMessage,
          errorCode: errorCode,
        );
      }

      _domains = List<Map<String, dynamic>>.from(result['domains'] ?? []);
      _clearError();
      return RefreshResult.ok(data: _domains);
    } catch (e) {
      _setError(e.toString(), 'EXCEPTION');
      return RefreshResult.fail(
        error: e.toString(),
        errorCode: 'EXCEPTION',
      );
    }
  }

  Future<RefreshResult> _fetchDnsRecordList({
    required String providerId,
    required String domainId,
    required Map<String, String> credentials,
  }) async {
    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        return RefreshResult.fail(
          error: 'Provider not found',
          errorCode: 'PROVIDER_NOT_FOUND',
        );
      }

      final result = await driver.getDnsRecords(domainId);

      if (result['error'] != null) {
        final errorCode = result['errorCode'] ?? 'UNKNOWN';
        final errorMessage = result['error'] ?? '操作失败';
        _setError(errorMessage, errorCode);
        return RefreshResult.fail(
          error: errorMessage,
          errorCode: errorCode,
        );
      }

      _dnsRecords[domainId] =
          List<Map<String, dynamic>>.from(result['records'] ?? []);
      _selectedDomainId = domainId;
      _clearError();
      return RefreshResult.ok(data: _dnsRecords[domainId]);
    } catch (e) {
      _setError(e.toString(), 'EXCEPTION');
      return RefreshResult.fail(
        error: e.toString(),
        errorCode: 'EXCEPTION',
      );
    }
  }

  Future<RefreshResult> refreshDomainList({
    required String providerId,
    required Map<String, String> credentials,
    required RefreshTriggerType triggerType,
  }) async {
    if (triggerType == RefreshTriggerType.manual) {
      _loadingState = LoadingState.refreshing;
      _isManualRefreshing = true;
      notifyListeners();
      Future.microtask(() {
        _domains = [];
        notifyListeners();
      });
    } else {
      _loadingState = LoadingState.loading;
      notifyListeners();
    }

    final result = await _refreshCore.refreshDomainList(
      fetchData: () => _fetchDomainList(
        providerId: providerId,
        credentials: credentials,
      ),
      triggerType: triggerType,
    );

    _isManualRefreshing = false;
    _loadingState = LoadingState.idle;
    notifyListeners();
    return result;
  }

  Future<RefreshResult> refreshDnsRecordList({
    required String providerId,
    required String domainId,
    required Map<String, String> credentials,
    required RefreshTriggerType triggerType,
  }) async {
    if (triggerType == RefreshTriggerType.manual) {
      _loadingState = LoadingState.refreshing;
      _isManualRefreshing = true;
      notifyListeners();
      Future.microtask(() {
        _dnsRecords[domainId] = [];
        notifyListeners();
      });
    } else {
      _loadingState = LoadingState.loading;
      notifyListeners();
    }

    final result = await _refreshCore.refreshDnsRecordList(
      fetchData: () => _fetchDnsRecordList(
        providerId: providerId,
        domainId: domainId,
        credentials: credentials,
      ),
      triggerType: triggerType,
    );

    _isManualRefreshing = false;
    _loadingState = LoadingState.idle;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> addDomain(
    String providerId,
    Map<String, dynamic> domainData,
    Map<String, String> credentials,
  ) async {
    _setLoadingState(LoadingState.operating);

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        _setLoadingState(LoadingState.idle);
        return {
          'success': false,
          'error': 'Provider not found',
          'errorCode': 'PROVIDER_NOT_FOUND',
          'statusCode': 404
        };
      }

      final result = await driver.createDomain(domainData);

      if (result['error'] != null) {
        _setLoadingState(LoadingState.idle);
        return {
          'success': false,
          'error': result['error'],
          'errorCode': result['errorCode'] ?? 'UNKNOWN',
          'statusCode': result['statusCode']
        };
      }

      final refreshResult = await refreshDomainList(
        providerId: providerId,
        credentials: credentials,
        triggerType: RefreshTriggerType.passive,
      );

      if (refreshResult.success) {
        return {'success': true, 'statusCode': 'OK', 'data': result['data']};
      } else {
        return {
          'success': false,
          'error': refreshResult.error,
          'errorCode': refreshResult.errorCode,
        };
      }
    } catch (e) {
      _setLoadingState(LoadingState.idle);
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  Future<Map<String, dynamic>> deleteDomain(
    String providerId,
    String domainId,
    Map<String, String> credentials,
  ) async {
    _setLoadingState(LoadingState.operating);

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        _setLoadingState(LoadingState.idle);
        return {
          'success': false,
          'error': 'Provider not found',
          'errorCode': 'PROVIDER_NOT_FOUND',
          'statusCode': 404
        };
      }

      final result = await driver.deleteDomain(domainId);

      if (result['success'] == true) {
        final refreshResult = await refreshDomainList(
          providerId: providerId,
          credentials: credentials,
          triggerType: RefreshTriggerType.passive,
        );

        if (refreshResult.success) {
          return {'success': true, 'statusCode': 'OK'};
        } else {
          return {
            'success': false,
            'error': refreshResult.error,
            'errorCode': refreshResult.errorCode,
          };
        }
      }

      _setLoadingState(LoadingState.idle);
      return result;
    } catch (e) {
      _setLoadingState(LoadingState.idle);
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  Future<Map<String, dynamic>> renewDomain(
    String providerId,
    String domainId,
    Map<String, String> credentials,
  ) async {
    _setLoadingState(LoadingState.operating);

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        _setLoadingState(LoadingState.idle);
        return {
          'success': false,
          'error': 'Provider not found',
          'errorCode': 'PROVIDER_NOT_FOUND',
          'statusCode': 404
        };
      }

      final result = await driver.renewDomain(domainId);

      if (result['error'] != null) {
        _setLoadingState(LoadingState.idle);
        return {
          'success': false,
          'error': result['error'],
          'errorCode': result['errorCode'] ?? 'UNKNOWN',
          'statusCode': result['statusCode']
        };
      }

      final refreshResult = await refreshDomainList(
        providerId: providerId,
        credentials: credentials,
        triggerType: RefreshTriggerType.passive,
      );

      if (refreshResult.success) {
        return {'success': true, 'statusCode': 'OK', 'data': result['data']};
      } else {
        return {
          'success': false,
          'error': refreshResult.error,
          'errorCode': refreshResult.errorCode,
        };
      }
    } catch (e) {
      _setLoadingState(LoadingState.idle);
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  Future<Map<String, dynamic>> createDnsRecord(
    String providerId,
    String domainId,
    Map<String, dynamic> recordData,
    Map<String, String> credentials,
  ) async {
    _setLoadingState(LoadingState.operating);

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        _setLoadingState(LoadingState.idle);
        return {
          'success': false,
          'error': 'Provider not found',
          'errorCode': 'PROVIDER_NOT_FOUND',
          'statusCode': 404
        };
      }

      final result = await driver.createDnsRecord(domainId, recordData);

      if (result['error'] != null) {
        _setLoadingState(LoadingState.idle);
        return {
          'success': false,
          'error': result['error'],
          'errorCode': result['errorCode'] ?? 'UNKNOWN',
          'statusCode': result['statusCode']
        };
      }

      final refreshResult = await refreshDnsRecordList(
        providerId: providerId,
        domainId: domainId,
        credentials: credentials,
        triggerType: RefreshTriggerType.passive,
      );

      if (refreshResult.success) {
        return {'success': true, 'statusCode': 'OK', 'data': result['data']};
      } else {
        return {
          'success': false,
          'error': refreshResult.error,
          'errorCode': refreshResult.errorCode,
        };
      }
    } catch (e) {
      _setLoadingState(LoadingState.idle);
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  Future<Map<String, dynamic>> updateDnsRecord(
    String providerId,
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
    Map<String, String> credentials,
  ) async {
    _setLoadingState(LoadingState.operating);

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        _setLoadingState(LoadingState.idle);
        return {
          'success': false,
          'error': 'Provider not found',
          'errorCode': 'PROVIDER_NOT_FOUND',
          'statusCode': 404
        };
      }

      final result = await driver.updateDnsRecord(domainId, recordId, recordData);

      if (result['error'] != null) {
        _setLoadingState(LoadingState.idle);
        return {
          'success': false,
          'error': result['error'],
          'errorCode': result['errorCode'] ?? 'UNKNOWN',
          'statusCode': result['statusCode']
        };
      }

      final refreshResult = await refreshDnsRecordList(
        providerId: providerId,
        domainId: domainId,
        credentials: credentials,
        triggerType: RefreshTriggerType.passive,
      );

      if (refreshResult.success) {
        return {'success': true, 'statusCode': 'OK', 'data': result['data']};
      } else {
        return {
          'success': false,
          'error': refreshResult.error,
          'errorCode': refreshResult.errorCode,
        };
      }
    } catch (e) {
      _setLoadingState(LoadingState.idle);
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  Future<Map<String, dynamic>> deleteDnsRecord(
    String providerId,
    String domainId,
    String recordId,
    Map<String, String> credentials,
  ) async {
    _setLoadingState(LoadingState.operating);

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        _setLoadingState(LoadingState.idle);
        return {
          'success': false,
          'error': 'Provider not found',
          'errorCode': 'PROVIDER_NOT_FOUND',
          'statusCode': 404
        };
      }

      final result = await driver.deleteDnsRecord(domainId, recordId);

      if (result['success'] == true) {
        final refreshResult = await refreshDnsRecordList(
          providerId: providerId,
          domainId: domainId,
          credentials: credentials,
          triggerType: RefreshTriggerType.passive,
        );

        if (refreshResult.success) {
          return {'success': true, 'statusCode': 'OK'};
        } else {
          return {
            'success': false,
            'error': refreshResult.error,
            'errorCode': refreshResult.errorCode,
          };
        }
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

  void clearDnsRecords(String domainId) {
    _dnsRecords[domainId] = [];
    notifyListeners();
  }

  void clearDomains() {
    _domains = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _errorCode = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshCore.dispose();
    super.dispose();
  }
}