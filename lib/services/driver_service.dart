import '../drivers/driver_factory.dart';
import '../drivers/driver_registry.dart';
import '../drivers/interfaces/driver_interface.dart';
import '../utils/log/log.dart';

class DriverService {
  static final DriverService _instance = DriverService._internal();
  factory DriverService() => _instance;
  DriverService._internal();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      LogService.instance.info(
        module: 'drivers',
        className: 'DriverService',
        methodName: 'initialize',
        action: '开始初始化驱动注册表',
        status: 'pending',
      );
      await DriverRegistry.initialize();
      _isInitialized = true;
      final driverCount = DriverFactory.getAll().length;
      LogService.instance.info(
        module: 'drivers',
        className: 'DriverService',
        methodName: 'initialize',
        action: '驱动注册表初始化完成',
        data: {'driverCount': driverCount},
        status: 'success',
      );
    } catch (e, stack) {
      LogService.instance.error(
        module: 'drivers',
        className: 'DriverService',
        methodName: 'initialize',
        action: '驱动服务初始化失败',
        errorMessage: e.toString(),
        stackTrace: stack.toString(),
      );
      rethrow;
    }
  }

  DriverInterface? getDriver(String providerId) {
    if (!_isInitialized) {
      LogService.instance.warn(
        module: 'drivers',
        className: 'DriverService',
        methodName: 'getDriver',
        action: 'DriverService 未初始化',
        data: {'providerId': providerId},
        status: 'error',
      );
      return null;
    }
    return DriverFactory.get(providerId);
  }

  List<DriverInterface> getAllDrivers() {
    if (!_isInitialized) return [];
    return DriverFactory.getAll();
  }

  bool hasDriver(String providerId) {
    return _isInitialized && DriverFactory.has(providerId);
  }
}