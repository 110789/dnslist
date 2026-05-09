import 'package:go_router/go_router.dart';
import '../../pages/home/home_page.dart';
import '../../pages/settings/settings_page.dart';
import '../../pages/credential/add_credential_page.dart';

class RouteNames {
  static const String home = 'home';
  static const String settings = 'settings';
  static const String addCredential = 'addCredential';

  RouteNames._();
}

class RoutePaths {
  static const String home = '/';
  static const String settings = '/settings';
  static const String addCredential = '/settings/credential/add';

  RoutePaths._();
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: RoutePaths.addCredential,
        builder: (context, state) => const AddCredentialPage(),
      ),
    ],
  );

  AppRouter._();
}