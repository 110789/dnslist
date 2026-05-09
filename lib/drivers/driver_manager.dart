import 'driver_factory.dart';

class DriverManager {
  static final DriverManager _instance = DriverManager._internal();
  factory DriverManager() => _instance;
  DriverManager._internal();

  final Map<String, Map<String, String>> _credentials = {};
  final Set<String> _initializedDrivers = {};

  Future<void> setCredential(String providerId, Map<String, String> credentials) async {
    _credentials[providerId] = credentials;
    final driver = DriverFactory.get(providerId);
    if (driver != null) {
      await driver.validateCredential(credentials);
      _initializedDrivers.add(providerId);
    }
  }

  Map<String, String>? getCredential(String providerId) {
    return _credentials[providerId];
  }

  bool isDriverInitialized(String providerId) {
    return _initializedDrivers.contains(providerId);
  }

  void clearCredential(String providerId) {
    _credentials.remove(providerId);
    _initializedDrivers.remove(providerId);
  }

  void clearAll() {
    _credentials.clear();
    _initializedDrivers.clear();
  }

  List<String> get initializedProviders => _initializedDrivers.toList();
}