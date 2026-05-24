import 'package:flutter/widgets.dart';

class RecordsUxState extends ChangeNotifier {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isEmpty = false;
  String? _error;
  String? _errorCode;

  List<Map<String, dynamic>> get records => _records;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isEmpty => _isEmpty;
  bool get showCenterLoading => _isLoading || _isRefreshing;
  bool get hasError => _error != null && _records.isEmpty;
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

  void setRecords(List<Map<String, dynamic>> records) {
    _records = records;
    _isEmpty = records.isEmpty;
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
    _records = [];
    _isEmpty = false;
    _error = null;
    _errorCode = null;
    notifyListeners();
  }

  void addRecord(Map<String, dynamic> record) {
    _records = [..._records, record];
    notifyListeners();
  }

  void updateRecord(String recordId, Map<String, dynamic> record) {
    _records = _records.map((r) => r['id']?.toString() == recordId ? record : r).toList();
    notifyListeners();
  }

  void removeRecord(String recordId) {
    _records = _records.where((r) => r['id']?.toString() != recordId).toList();
    notifyListeners();
  }
}