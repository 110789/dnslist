import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'dart:ui';

import 'core/router/app_router.dart';
import 'core/state/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/service_registry.dart';
import 'core/services/framework_services_impl.dart';
import 'drivers/driver_registry.dart';
import 'services/credential_storage.dart';
import 'services/credential_state.dart';
import 'services/new_domain_state.dart';
import 'utils/storage/local_storage.dart';
import 'database/database.dart';
import 'database/repositories/credential_repository.dart';
import 'database/repositories/user_preferences_repository.dart';

void _globalErrorHandler(FlutterErrorDetails details) {
  developer.log(
    'Flutter Error: ${details.exceptionAsString()}',
    name: 'GlobalErrorHandler',
    error: details.exception,
  );
  developer.log(
    'StackTrace: ${details.stack}',
    name: 'GlobalErrorHandler',
  );
}

void _asyncErrorHandler(Object error, StackTrace stackTrace) {
  developer.log(
    'Async Error: $error\nStackTrace: $stackTrace',
    name: 'AsyncErrorHandler',
    error: error,
  );
}

Future<void> _safeInit(String name, Future<void> Function() initFn) async {
  try {
    await initFn();
    developer.log('$name initialized successfully', name: 'AppInit');
  } catch (e, stack) {
    developer.log(
      '$name initialization failed: $e\nStackTrace: $stack',
      name: 'AppInit',
      error: e,
    );
  }
}

Future<void> _safeDriverInit() async {
  try {
    await DriverRegistry.initialize();
    developer.log('Driver registry initialized', name: 'AppInit');
  } catch (e, stack) {
    developer.log(
      'Driver registry initialization failed: $e\nStackTrace: $stack',
      name: 'AppInit',
      error: e,
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
    providerBaseUrls: const {
      'cloudflare': 'https://api.cloudflare.com/client/v4',
      'dnshe': 'https://api005.dnshe.com/index.php',
      'dnspod': 'https://dnspod.tencentcloudapi.com',
      'cloudns': 'https://api.cloudns.net',
      'rainyun': 'https://api.v2.rainyun.com',
    },
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

  developer.log('ServiceRegistry initialized', name: 'AppInit');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final credentialRepository = CredentialRepository();
    final userPrefsRepository = UserPreferencesRepository();
    final credentialStorage = CredentialStorage(
      LocalStorage.instance,
      repository: credentialRepository,
    );
    final credentialState = CredentialState(credentialStorage);
    credentialState.init();
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