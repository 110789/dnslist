import 'package:go_router/go_router.dart';
import '../../pages/home/home_page.dart';
import '../../pages/settings/settings_page.dart';
import '../../pages/credential/add_credential_page.dart';
import '../../pages/domains/dns_records_page.dart';

class RouteNames {
  static const String home = 'home';
  static const String settings = 'settings';
  static const String addCredential = 'addCredential';
  static const String dnsRecords = 'dnsRecords';

  RouteNames._();
}

class RoutePaths {
  static const String home = '/';
  static const String settings = '/settings';
  static const String addCredential = '/settings/credential/add';
  static const String dnsRecords = '/domains/:domainId/records';

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
      GoRoute(
        path: '/domains/:domainId/records',
        builder: (context, state) {
          final domainId = state.pathParameters['domainId'] ?? '';
          final domainName = state.uri.queryParameters['name'] ?? 'DNS记录';
          return DnsRecordsPage(
            domainId: domainId,
            domainName: domainName,
          );
        },
      ),
    ],
  );

  AppRouter._();
}