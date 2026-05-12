import 'dart:ui';

abstract class FrameworkConfig {
  String get appName;
  String get appVersion;
  Map<String, String> get providerBaseUrls;
  int get defaultPageSize;
  int get connectionTimeout;
  int get receiveTimeout;
}

class DefaultFrameworkConfig implements FrameworkConfig {
  @override
  final String appName;
  @override
  final String appVersion;
  @override
  final Map<String, String> providerBaseUrls;
  @override
  final int defaultPageSize;
  @override
  final int connectionTimeout;
  @override
  final int receiveTimeout;

  const DefaultFrameworkConfig({
    required this.appName,
    required this.appVersion,
    required this.providerBaseUrls,
    this.defaultPageSize = 20,
    this.connectionTimeout = 30000,
    this.receiveTimeout = 30000,
  });
}

abstract class ThemeService {
  Color getDnsTypeColor(String type);
  Color getStatusColor(String status);
  Color get successColor;
  Color get warningColor;
  Color get errorColor;
  Color get infoColor;
  double get spacingXs;
  double get spacingSm;
  double get spacingMd;
  double get spacingLg;
  double get radiusSm;
  double get radiusMd;
  double get radiusLg;
}

abstract class NetworkService {
  String getBaseUrl(String providerId);
  Future<Map<String, dynamic>> get(String url, {Map<String, dynamic>? queryParameters, Map<String, String>? headers});
  Future<Map<String, dynamic>> post(String url, {dynamic data, Map<String, String>? headers});
  Future<Map<String, dynamic>> put(String url, {dynamic data, Map<String, String>? headers});
  Future<Map<String, dynamic>> delete(String url, {Map<String, String>? headers});
}

abstract class StorageService {
  Future<void> set(String key, dynamic value);
  Future<dynamic> get(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

class ServiceRegistry {
  static ServiceRegistry? _instance;
  late final FrameworkConfig config;
  late final ThemeService themeService;
  late final NetworkService networkService;
  late final StorageService storageService;

  ServiceRegistry._();

  static ServiceRegistry get instance {
    _instance ??= ServiceRegistry._();
    return _instance!;
  }

  void initialize({
    required FrameworkConfig config,
    required ThemeService themeService,
    required NetworkService networkService,
    required StorageService storageService,
  }) {
    this.config = config;
    this.themeService = themeService;
    this.networkService = networkService;
    this.storageService = storageService;
  }

  String getProviderBaseUrl(String providerId) {
    return config.providerBaseUrls[providerId] ?? '';
  }

  int get connectionTimeout => config.connectionTimeout;
  int get receiveTimeout => config.receiveTimeout;
}