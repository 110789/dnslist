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

class RefreshCore extends ChangeNotifier {
  RefreshState _state = RefreshState.idle;
  RefreshTriggerType? _triggerType;
  DateTime? _lastRefreshTime;
  Timer? _debounceTimer;

  static const Duration _debounceDuration = Duration(milliseconds: 500);

  RefreshState get state => _state;
  bool get isRefreshing => _state == RefreshState.refreshing || _state == RefreshState.loading;
  RefreshTriggerType? get triggerType => _triggerType;

  Future<RefreshResult> execute({
    required RefreshCallback fetchData,
    required RefreshTriggerType triggerType,
    bool clearList = false,
  }) async {
    if (_debounceTimer?.isActive ?? false) {
      return RefreshResult.fail(
        error: '刷新过于频繁',
        errorCode: 'DEBOUNCE',
      );
    }

    _triggerType = triggerType;
    _lastRefreshTime = DateTime.now();

    if (triggerType == RefreshTriggerType.manual) {
      _state = RefreshState.refreshing;
    } else {
      _state = RefreshState.loading;
    }
    notifyListeners();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {});

    try {
      final result = await fetchData();

      if (result.success) {
        _state = RefreshState.idle;
        notifyListeners();
        return result;
      } else {
        _state = RefreshState.idle;
        notifyListeners();
        return result;
      }
    } catch (e) {
      _state = RefreshState.idle;
      notifyListeners();
      return RefreshResult.fail(
        error: e.toString(),
        errorCode: 'EXCEPTION',
      );
    }
  }

  void resetState() {
    _state = RefreshState.idle;
    _triggerType = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
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

  void resetDomainState() => _domainRefresh.resetState();
  void resetDnsRecordState() => _dnsRecordRefresh.resetState();

  void dispose() {
    _domainRefresh.dispose();
    _dnsRecordRefresh.dispose();
  }
}