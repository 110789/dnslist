class DriverService {
  DriverService._();

  static DriverService? _instance;

  static DriverService get instance {
    _instance ??= DriverService._();
    return _instance!;
  }
}