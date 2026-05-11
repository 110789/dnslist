import 'package:flutter/foundation.dart';
import '../drivers/driver_factory.dart';
import '../core/refresh/refresh_core.dart';

enum LoadingState {
  idle,
  loading,
  refreshing,
  operating,
}

enum RefreshAnimationType {
  pullDown,
  centerLoading,
}

class NewDomainState extends ChangeNotifier {
  List<Map<String, dynamic>> _domains = [];
  Map<String, List<Map<String, dynamic>>> _dnsRecords = {};
  LoadingState _loadingState = LoadingState.idle;
  String? _error;
  String? _errorCode;
  String? _selectedDomainId;
  bool _isRefreshing = false;

  final DomainRefreshCore _refreshCore = DomainRefreshCore();

  NewDomainState();

  List<Map<String, dynamic>> get domains => _domains;
  Map<String, List<Map<String, dynamic>>> get dnsRecords => _dnsRecords;

  LoadingState get loadingState => _loadingState;
  bool get isLoading => _loadingState == LoadingState.loading;
  bool get isRefreshing => _loadingState == LoadingState.refreshing;
  bool get isOperating => _loadingState == LoadingState.operating;
  bool get isIdle => _loadingState == LoadingState.idle;
  bool get isManualRefreshing => _isRefreshing;

  bool get showCenterLoading =>
      _loadingState == LoadingState.loading ||
      _loadingState == LoadingState.operating;

  String? get error => _error;
  String? get errorCode => _errorCode;
  String? get selectedDomainId => _selectedDomainId;

  bool get isDomainRefreshing => _refreshCore.isDomainRefreshing;
  bool get isDnsRecordRefreshing => _refreshCore.isDnsRecordRefreshing;
  bool get isDomainLocked => _refreshCore.isDomainLocked;
  bool get isDnsRecordLocked => _refreshCore.isDnsRecordLocked;

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

  void _clearListData({required bool isDomain}) {
    if (isDomain) {
      _domains = [];
    } else if (_selectedDomainId != null) {
      _dnsRecords[_selectedDomainId!] = [];
    }
    notifyListeners();
  }

  void _startRefreshAnimation(RefreshAnimationType animationType) {
    if (animationType == RefreshAnimationType.pullDown) {
      _loadingState = LoadingState.refreshing;
      _isRefreshing = true;
    } else {
      _loadingState = LoadingState.loading;
    }
    notifyListeners();
  }

  void _stopRefreshAnimation() {
    _isRefreshing = false;
    _loadingState = LoadingState.idle;
    notifyListeners();
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

  Future<RefreshResult> _executeRefresh({
    required RefreshCallback fetchData,
    required RefreshTriggerType triggerType,
  }) async {
    final result = await _refreshCore.refreshDomainList(
      fetchData: fetchData,
      triggerType: triggerType,
    );
    _stopRefreshAnimation();
    return result;
  }

  Future<RefreshResult> _executeDnsRefresh({
    required RefreshCallback fetchData,
    required RefreshTriggerType triggerType,
  }) async {
    final result = await _refreshCore.refreshDnsRecordList(
      fetchData: fetchData,
      triggerType: triggerType,
    );
    _stopRefreshAnimation();
    return result;
  }

  Future<RefreshResult> refreshDomainList({
    required String providerId,
    required Map<String, String> credentials,
    required RefreshTriggerType triggerType,
    RefreshAnimationType animationType = RefreshAnimationType.pullDown,
  }) async {
    _clearListData(isDomain: true);
    _startRefreshAnimation(animationType);

    return _executeRefresh(
      fetchData: () => _fetchDomainList(
        providerId: providerId,
        credentials: credentials,
      ),
      triggerType: triggerType,
    );
  }

  Future<RefreshResult> refreshDnsRecordList({
    required String providerId,
    required String domainId,
    required Map<String, String> credentials,
    required RefreshTriggerType triggerType,
    RefreshAnimationType animationType = RefreshAnimationType.pullDown,
  }) async {
    _clearListData(isDomain: false);
    _startRefreshAnimation(animationType);

    return _executeDnsRefresh(
      fetchData: () => _fetchDnsRecordList(
        providerId: providerId,
        domainId: domainId,
        credentials: credentials,
      ),
      triggerType: triggerType,
    );
  }

  Future<Map<String, dynamic>> _refreshAfterOperation({
    required RefreshTriggerType refreshType,
    required String providerId,
    String? domainId,
    required Map<String, String> credentials,
  }) async {
    RefreshResult refreshResult;
    if (domainId != null) {
      refreshResult = await refreshDnsRecordList(
        providerId: providerId,
        domainId: domainId,
        credentials: credentials,
        triggerType: refreshType,
        animationType: RefreshAnimationType.centerLoading,
      );
    } else {
      refreshResult = await refreshDomainList(
        providerId: providerId,
        credentials: credentials,
        triggerType: refreshType,
        animationType: RefreshAnimationType.centerLoading,
      );
    }

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

  Map<String, dynamic> _errorResult(String error, String errorCode, int? statusCode) {
    return {
      'success': false,
      'error': error,
      'errorCode': errorCode,
      'statusCode': statusCode ?? 0,
    };
  }

  Future<Map<String, dynamic>> addDomain(
    String providerId,
    Map<String, dynamic> domainData,
    Map<String, String> credentials,
  ) async {
    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        return _errorResult('Provider not found', 'PROVIDER_NOT_FOUND', 404);
      }

      final result = await driver.createDomain(domainData);

      if (result['error'] != null) {
        return _errorResult(
          result['error'],
          result['errorCode'] ?? 'UNKNOWN',
          result['statusCode'],
        );
      }

      return await _refreshAfterOperation(
        refreshType: RefreshTriggerType.passive,
        providerId: providerId,
        credentials: credentials,
      );
    } catch (e) {
      return _errorResult(e.toString(), 'EXCEPTION', null);
    }
  }

  Future<Map<String, dynamic>> deleteDomain(
    String providerId,
    String domainId,
    Map<String, String> credentials,
  ) async {
    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        return _errorResult('Provider not found', 'PROVIDER_NOT_FOUND', 404);
      }

      final result = await driver.deleteDomain(domainId);

      if (result['success'] == true) {
        return await _refreshAfterOperation(
          refreshType: RefreshTriggerType.passive,
          providerId: providerId,
          credentials: credentials,
        );
      }

      return result;
    } catch (e) {
      return _errorResult(e.toString(), 'EXCEPTION', null);
    }
  }

  Future<Map<String, dynamic>> renewDomain(
    String providerId,
    String domainId,
    Map<String, String> credentials,
  ) async {
    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        return _errorResult('Provider not found', 'PROVIDER_NOT_FOUND', 404);
      }

      final result = await driver.renewDomain(domainId);

      if (result['error'] != null) {
        return _errorResult(
          result['error'],
          result['errorCode'] ?? 'UNKNOWN',
          result['statusCode'],
        );
      }

      final refreshResult = await _refreshAfterOperation(
        refreshType: RefreshTriggerType.passive,
        providerId: providerId,
        credentials: credentials,
      );

      if (refreshResult['success'] == true) {
        return {'success': true, 'statusCode': 'OK', 'data': result['data']};
      }
      return refreshResult;
    } catch (e) {
      return _errorResult(e.toString(), 'EXCEPTION', null);
    }
  }

  Future<Map<String, dynamic>> createDnsRecord(
    String providerId,
    String domainId,
    Map<String, dynamic> recordData,
    Map<String, String> credentials,
  ) async {
    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        return _errorResult('Provider not found', 'PROVIDER_NOT_FOUND', 404);
      }

      final result = await driver.createDnsRecord(domainId, recordData);

      if (result['error'] != null) {
        return _errorResult(
          result['error'],
          result['errorCode'] ?? 'UNKNOWN',
          result['statusCode'],
        );
      }

      return await _refreshAfterOperation(
        refreshType: RefreshTriggerType.passive,
        providerId: providerId,
        domainId: domainId,
        credentials: credentials,
      );
    } catch (e) {
      return _errorResult(e.toString(), 'EXCEPTION', null);
    }
  }

  Future<Map<String, dynamic>> updateDnsRecord(
    String providerId,
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
    Map<String, String> credentials,
  ) async {
    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        return _errorResult('Provider not found', 'PROVIDER_NOT_FOUND', 404);
      }

      final result = await driver.updateDnsRecord(domainId, recordId, recordData);

      if (result['error'] != null) {
        return _errorResult(
          result['error'],
          result['errorCode'] ?? 'UNKNOWN',
          result['statusCode'],
        );
      }

      return await _refreshAfterOperation(
        refreshType: RefreshTriggerType.passive,
        providerId: providerId,
        domainId: domainId,
        credentials: credentials,
      );
    } catch (e) {
      return _errorResult(e.toString(), 'EXCEPTION', null);
    }
  }

  Future<Map<String, dynamic>> deleteDnsRecord(
    String providerId,
    String domainId,
    String recordId,
    Map<String, String> credentials,
  ) async {
    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        return _errorResult('Provider not found', 'PROVIDER_NOT_FOUND', 404);
      }

      final result = await driver.deleteDnsRecord(domainId, recordId);

      if (result['success'] == true) {
        return await _refreshAfterOperation(
          refreshType: RefreshTriggerType.passive,
          providerId: providerId,
          domainId: domainId,
          credentials: credentials,
        );
      }

      return result;
    } catch (e) {
      return _errorResult(e.toString(), 'EXCEPTION', null);
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