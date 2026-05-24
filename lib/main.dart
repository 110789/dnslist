import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import 'core/router/app_router.dart';
import 'core/state/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/service_registry.dart';
import 'core/services/framework_services_impl.dart';
import 'services/credential_storage.dart';
import 'services/credential_state.dart';
import 'services/new_domain_state.dart';
import 'services/driver_service.dart';
import 'utils/storage/local_storage.dart';
import 'database/database.dart';
import 'database/repositories/credential_repository.dart';
import 'database/repositories/user_preferences_repository.dart';
import 'utils/log/log.dart';

void _globalErrorHandler(FlutterErrorDetails details) {
  LogService.instance.fatal(
    module: 'core',
    className: 'FlutterError',
    methodName: 'onError',
    action: 'Flutter 框架异常捕获',
    errorMessage: details.exceptionAsString(),
    stackTrace: details.stack?.toString(),
  );
}

void _asyncErrorHandler(Object error, StackTrace stackTrace) {
  LogService.instance.fatal(
    module: 'core',
    className: 'PlatformDispatcher',
    methodName: 'onError',
    action: '平台异步异常捕获',
    errorMessage: error.toString(),
    stackTrace: stackTrace.toString(),
  );
}

Future<void> _safeInit(String name, Future<void> Function() initFn) async {
  final stopwatch = Stopwatch()..start();
  try {
    await initFn();
    stopwatch.stop();
    LogService.instance.info(
      module: 'architecture',
      className: 'AppInit',
      methodName: name,
      action: '初始化成功',
      durationMs: stopwatch.elapsedMilliseconds,
      status: 'success',
    );
  } catch (e, stack) {
    stopwatch.stop();
    LogService.instance.error(
      module: 'architecture',
      className: 'AppInit',
      methodName: name,
      action: '初始化失败',
      errorMessage: e.toString(),
      stackTrace: stack.toString(),
    );
  }
}

Future<void> _safeDriverInit() async {
  final stopwatch = Stopwatch()..start();
  try {
    await DriverService().initialize();
    stopwatch.stop();
    LogService.instance.info(
      module: 'drivers',
      className: 'DriverService',
      methodName: 'initialize',
      action: '驱动服务初始化成功',
      durationMs: stopwatch.elapsedMilliseconds,
      status: 'success',
    );
  } catch (e, stack) {
    stopwatch.stop();
    LogService.instance.error(
      module: 'drivers',
      className: 'DriverService',
      methodName: 'initialize',
      action: '驱动服务初始化失败',
      errorMessage: e.toString(),
      stackTrace: stack.toString(),
    );
  }
}

Future<void> _initDatabase() async {
  await DatabaseInitService.initialize();
  final storage = LocalStorage.instance;
  final needsMigration = storage.getString('_db_version') == null;
  if (needsMigration) {
    await DatabaseInitService.runMigration();
  }
}

Future<void> _initServiceRegistry() async {
  final localStorage = LocalStorage.instance;
  await localStorage.init();

  final config = DefaultFrameworkConfig(
    appName: 'DNS管理工具',
    appVersion: '1.0.0',
    defaultPageSize: 20,
    connectionTimeout: 30000,
    receiveTimeout: 30000,
  );

  ServiceRegistry.instance.initialize(
    config: config,
    themeService: ThemeServiceImpl(),
    networkService: NetworkServiceImpl(),
    storageService: StorageServiceImpl(localStorage),
  );

  LogService.instance.info(
    module: 'core',
    className: 'ServiceRegistry',
    methodName: 'initialize',
    action: '服务注册初始化完成',
    status: 'success',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LogService.instance.init(config: LogConfig(
    debugEnabled: kDebugMode,
    infoEnabled: true,
    warnEnabled: true,
    errorEnabled: true,
    fatalEnabled: true,
    enableLocalPersist: kDebugMode == false,
    enableConsoleOutput: true,
    enableCrashReport: kDebugMode == false,
  ));

  LogCrashHandler.instance.install();

  LogService.instance.info(
    module: 'architecture',
    className: 'App',
    methodName: 'main',
    action: '应用启动',
    data: {'version': '1.0.0', 'debug': kDebugMode},
  );

  FlutterError.onError = _globalErrorHandler;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    _asyncErrorHandler(error, stackTrace);
    return true;
  };

  await Future.wait([
    _safeInit('LocalStorage', () async {
      await LocalStorage.instance.init();
    }),
    _safeInit('Database', _initDatabase),
  ]);

  await Future.wait([
    _safeInit('ServiceRegistry', _initServiceRegistry),
    _safeDriverInit(),
  ]);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  LogService.instance.info(
    module: 'architecture',
    className: 'App',
    methodName: 'main',
    action: '应用就绪，准备渲染',
    status: 'success',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final CredentialState credentialState;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCredentialState();
  }

  Future<void> _initCredentialState() async {
    final credentialRepository = CredentialRepository();
    final credentialStorage = CredentialStorage(
      LocalStorage.instance,
      repository: credentialRepository,
    );
    credentialState = CredentialState(credentialStorage);
    await credentialState.init();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final userPrefsRepository = UserPreferencesRepository();
    final domainState = NewDomainState();
    final themeProvider = ThemeProvider(repository: userPrefsRepository);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: credentialState),
        ChangeNotifierProvider.value(value: domainState),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: Selector<ThemeProvider, bool>(
        selector: (_, theme) => theme.isDarkMode,
        builder: (context, isDarkMode, _) {
          return MaterialApp.router(
            title: 'DNS管理工具',
            routerConfig: AppRouter.router,
            debugShowCheckedModeBanner: false,
            theme: isDarkMode ? AppTheme.md3Dark : AppTheme.md3Light,
          );
        },
      ),
    );
  }
}