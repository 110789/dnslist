import 'package:flutter/material.dart';
import 'package:dlist/generated/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../pages/home/home_page.dart';
import '../../pages/domains/dns_records_page.dart';
import '../../pages/settings/settings_page.dart';
import '../../pages/settings/about_page.dart';
import '../../pages/settings/licenses_page.dart';
import '../../pages/logcat/logcat_page.dart';
import '../../pages/settings/language_page.dart';

class RouteNames {
  static const String home = 'home';
  static const String dnsRecords = 'dnsRecords';
  static const String settings = 'settings';
  static const String about = 'about';
  static const String licenses = 'licenses';
  static const String logcat = 'logcat';
  static const String language = 'language';

  RouteNames._();
}

class RoutePaths {
  static const String home = '/';
  static const String dnsRecords = '/domains/:domainId/records';
  static const String settings = '/settings';
  static const String about = '/settings/about';
  static const String licenses = '/settings/licenses';
  static const String logcat = '/settings/logcat';
  static const String language = '/settings/language';

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
          final defaultTitle = AppLocalizations.of(context)?.appNavTitle ?? 'DNS Manager';
          final domainName = state.uri.queryParameters['name'] ?? defaultTitle;
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
      GoRoute(
        path: RoutePaths.about,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: RoutePaths.licenses,
        builder: (context, state) => const LicensesPage(),
      ),
      GoRoute(
        path: RoutePaths.logcat,
        builder: (context, state) => const LogcatPage(),
      ),
      GoRoute(
        path: RoutePaths.language,
        builder: (context, state) => const LanguagePage(),
      ),
    ],
  );

  AppRouter._();
}