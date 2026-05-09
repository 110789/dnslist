import 'interfaces/driver_interface.dart';

class DriverFactory {
  static final Map<String, DriverInterface> _drivers = {};
  static bool _isInitialized = false;

  static void register(DriverInterface driver) {
    _drivers[driver.providerId] = driver;
  }

  static DriverInterface? get(String providerId) {
    return _drivers[providerId];
  }

  static List<DriverInterface> getAll() {
    return _drivers.values.toList();
  }

  static bool has(String providerId) {
    return _drivers.containsKey(providerId);
  }

  static void unregister(String providerId) {
    _drivers.remove(providerId);
  }

  static void clear() {
    _drivers.clear();
    _isInitialized = false;
  }

  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
  }

  DriverFactory._();
}