import 'dart:async';
import 'package:flutter/foundation.dart';

enum RefreshTriggerType {
  manual,
  passive,
}

enum RefreshState {
  idle,
  refreshing,
  loading,
}

class RefreshResult {
  final bool success;
  final String? error;
  final String? errorCode;
  final dynamic data;

  const RefreshResult({
    required this.success,
    this.error,
    this.errorCode,
    this.data,
  });

  factory RefreshResult.ok({dynamic data}) => RefreshResult(
        success: true,
        data: data,
      );

  factory RefreshResult.fail({
    required String error,
    String? errorCode,
  }) =>
      RefreshResult(
        success: false,
        error: error,
        errorCode: errorCode,
      );
}

typedef RefreshCallback = Future<RefreshResult> Function();

class RefreshLock {
  bool _isLocked = false;
  DateTime? _lastExecuteTime;

  bool get isLocked => _isLocked;
  DateTime? get lastExecuteTime => _lastExecuteTime;

  bool tryLock() {
    if (_isLocked) return false;
    _isLocked = true;
    _lastExecuteTime = DateTime.now();
    return true;
  }

  void unlock() {
    _isLocked = false;
  }

  bool canExecute({Duration? minInterval}) {
    if (_isLocked) return false;
    if (minInterval != null && _lastExecuteTime != null) {
      final elapsed = DateTime.now().difference(_lastExecuteTime!);
      if (elapsed < minInterval) return false;
    }
    return true;
  }
}

class RefreshCore extends ChangeNotifier {
  RefreshState _state = RefreshState.idle;
  RefreshTriggerType? _triggerType;
  final RefreshLock _lock = RefreshLock();

  static const Duration _debounceDuration = Duration(milliseconds: 500);
  static const Duration _minExecuteInterval = Duration(milliseconds: 300);

  RefreshState get state => _state;
  bool get isRefreshing => _state == RefreshState.refreshing || _state == RefreshState.loading;
  bool get isLocked => _lock.isLocked;
  RefreshTriggerType? get triggerType => _triggerType;

  Future<RefreshResult> execute({
    required RefreshCallback fetchData,
    required RefreshTriggerType triggerType,
    bool clearList = false,
  }) async {
    if (!_lock.canExecute(minInterval: _minExecuteInterval)) {
      return RefreshResult.fail(
        error: '刷新进行中，请勿重复操作',
        errorCode: 'REFRESH_LOCKED',
      );
    }

    _lock.tryLock();
    _triggerType = triggerType;

    if (triggerType == RefreshTriggerType.manual) {
      _state = RefreshState.refreshing;
    } else {
      _state = RefreshState.loading;
    }
    notifyListeners();

    try {
      final result = await fetchData();
      _lock.unlock();
      _state = RefreshState.idle;
      notifyListeners();
      return result;
    } catch (e) {
      _lock.unlock();
      _state = RefreshState.idle;
      notifyListeners();
      return RefreshResult.fail(
        error: e.toString(),
        errorCode: 'EXCEPTION',
      );
    }
  }

  void forceReset() {
    _lock.unlock();
    _state = RefreshState.idle;
    _triggerType = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _lock.unlock();
    super.dispose();
  }
}

class DomainRefreshCore {
  final RefreshCore _domainRefresh = RefreshCore();
  final RefreshCore _dnsRecordRefresh = RefreshCore();

  RefreshCore get domainRefresh => _domainRefresh;
  RefreshCore get dnsRecordRefresh => _dnsRecordRefresh;

  bool get isDomainRefreshing => _domainRefresh.isRefreshing;
  bool get isDnsRecordRefreshing => _dnsRecordRefresh.isRefreshing;

  bool get isDomainLocked => _domainRefresh.isLocked;
  bool get isDnsRecordLocked => _dnsRecordRefresh.isLocked;

  RefreshState get domainState => _domainRefresh.state;
  RefreshState get dnsRecordState => _dnsRecordRefresh.state;

  Future<RefreshResult> refreshDomainList({
    required RefreshCallback fetchData,
    required RefreshTriggerType triggerType,
    bool clearList = false,
  }) {
    return _domainRefresh.execute(
      fetchData: fetchData,
      triggerType: triggerType,
      clearList: clearList,
    );
  }

  Future<RefreshResult> refreshDnsRecordList({
    required RefreshCallback fetchData,
    required RefreshTriggerType triggerType,
    bool clearList = false,
  }) {
    return _dnsRecordRefresh.execute(
      fetchData: fetchData,
      triggerType: triggerType,
      clearList: clearList,
    );
  }

  void resetDomainState() => _domainRefresh.forceReset();
  void resetDnsRecordState() => _dnsRecordRefresh.forceReset();

  void dispose() {
    _domainRefresh.dispose();
    _dnsRecordRefresh.dispose();
  }
}