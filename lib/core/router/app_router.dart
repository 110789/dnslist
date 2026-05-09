import 'package:go_router/go_router.dart';
import '../../pages/home/home_page.dart';
import '../../pages/domains/dns_records_page.dart';
import '../../pages/settings/settings_page.dart';

class RouteNames {
  static const String home = 'home';
  static const String dnsRecords = 'dnsRecords';
  static const String settings = 'settings';

  RouteNames._();
}

class RoutePaths {
  static const String home = '/';
  static const String dnsRecords = '/domains/:domainId/records';
  static const String settings = '/settings';

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
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );

  AppRouter._();
}