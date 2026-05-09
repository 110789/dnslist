import 'package:go_router/go_router.dart';

class RouteNames {
  static const String home = 'home';
  static const String domains = 'domains';
  static const String domainDetail = 'domainDetail';
  static const String dnsRecords = 'dnsRecords';
  static const String settings = 'settings';
  static const String addCredential = 'addCredential';
  static const String editCredential = 'editCredential';

  RouteNames._();
}

class RoutePaths {
  static const String home = '/';
  static const String domains = '/domains';
  static const String domainDetail = '/domains/:domainId';
  static const String dnsRecords = '/domains/:domainId/records';
  static const String settings = '/settings';
  static const String addCredential = '/settings/credential/add';
  static const String editCredential = '/settings/credential/:providerId/edit';

  RoutePaths._();
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.home,
    routes: [],
  );

  AppRouter._();
}