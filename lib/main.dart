import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/router/app_router.dart';
import 'drivers/driver_registry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp.router(
      title: 'DNS管理工具',
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}