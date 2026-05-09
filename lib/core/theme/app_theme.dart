import 'package:flutter/material.dart';

class AppTheme {
  static const _primarySeed = Color(0xFF2563EB);

  static ThemeData get md3Light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primarySeed,
      brightness: Brightness.light,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 2,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    dividerTheme: const DividerThemeData(
      space: 1,
      thickness: 1,
    ),
  );

  static ThemeData get md3Dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primarySeed,
      brightness: Brightness.dark,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 2,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    dividerTheme: const DividerThemeData(
      space: 1,
      thickness: 1,
    ),
  );

  static CupertinoThemeData get cupertinoLight => const CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFF2563EB),
    scaffoldBackgroundColor: Color(0xFFF8FAFC),
    barBackgroundColor: Color(0xFFFFFFFF),
    textTheme: CupertinoTextThemeData(
      primaryColor: Color(0xFF1E293B),
    ),
  );

  static CupertinoThemeData get cupertinoDark => const CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(0xFF3B82F6),
    scaffoldBackgroundColor: Color(0xFF0F172A),
    barBackgroundColor: Color(0xFF1E293B),
    textTheme: CupertinoTextThemeData(
      primaryColor: Color(0xFFF1F5F9),
    ),
  );
}

class AppColors {
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  static const dnsTypeA = Color(0xFF3B82F6);
  static const dnsTypeAAAA = Color(0xFF8B5CF6);
  static const dnsTypeCNAME = Color(0xFF10B981);
  static const dnsTypeMX = Color(0xFFF59E0B);
  static const dnsTypeTXT = Color(0xFF14B8A6);
  static const dnsTypeNS = Color(0xFF6366F1);
  static const dnsTypeSRV = Color(0xFFEC4899);

  static Color getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'A': return dnsTypeA;
      case 'AAAA': return dnsTypeAAAA;
      case 'CNAME': return dnsTypeCNAME;
      case 'MX': return dnsTypeMX;
      case 'TXT': return dnsTypeTXT;
      case 'NS': return dnsTypeNS;
      case 'SRV': return dnsTypeSRV;
      default: return Colors.grey;
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case '活跃': case 'active': return success;
      case '待处理': case 'pending': return warning;
      case '已过期': case 'expired': return error;
      case '已暂停': case 'suspended': return Colors.grey;
      case '已删除': case 'deleted': return error.withValues(alpha: 0.6);
      default: return Colors.grey;
    }
  }
}

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
}