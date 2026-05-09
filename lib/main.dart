import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'drivers/driver_registry.dart';
import 'services/credential_storage.dart';
import 'services/credential_state.dart';
import 'services/domain_state.dart';
import 'utils/storage/local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await LocalStorage.instance.init();
  await DriverRegistry.initialize();
  
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
    final credentialStorage = CredentialStorage(LocalStorage.instance);
    final credentialState = CredentialState(credentialStorage);
    final domainState = DomainState();

    credentialState.loadCredentials();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: credentialState),
        ChangeNotifierProvider.value(value: domainState),
      ],
      child: MaterialApp.router(
        title: 'DNS管理工具',
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}