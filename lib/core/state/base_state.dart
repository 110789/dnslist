import 'package:flutter/foundation.dart';

abstract class BaseState extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _message;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get message => _message;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void setMessage(String? message) {
    _message = message;
    notifyListeners();
  }

  void clearState() {
    _isLoading = false;
    _error = null;
    _message = null;
    notifyListeners();
  }
}