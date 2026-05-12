import 'package:flutter/material.dart';

class DnsDesignTokens {
  static const Color primarySeed = Color(0xFF2563EB);
  static const Color primarySeedDark = Color(0xFF3B82F6);

  static const Color dnsTypeA = Color(0xFF3B82F6);
  static const Color dnsTypeAAAA = Color(0xFF8B5CF6);
  static const Color dnsTypeCNAME = Color(0xFF10B981);
  static const Color dnsTypeMX = Color(0xFFF59E0B);
  static const Color dnsTypeTXT = Color(0xFF14B8A6);
  static const Color dnsTypeNS = Color(0xFF6366F1);
  static const Color dnsTypeSRV = Color(0xFFEC4899);

  static const Color statusActive = Color(0xFF10B981);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusExpired = Color(0xFFEF4444);
  static const Color statusSuspended = Color(0xFF64748B);
  static const Color statusDeleted = Color(0xFF94A3B8);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static Color getDnsTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'A': return dnsTypeA;
      case 'AAAA': return dnsTypeAAAA;
      case 'CNAME': return dnsTypeCNAME;
      case 'MX': return dnsTypeMX;
      case 'TXT': return dnsTypeTXT;
      case 'NS': return dnsTypeNS;
      case 'SRV': return dnsTypeSRV;
      default: return const Color(0xFF64748B);
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case '活跃': case 'active': return statusActive;
      case '待处理': case 'pending': return statusPending;
      case '已过期': case 'expired': return statusExpired;
      case '已暂停': case 'suspended': return statusSuspended;
      case '已删除': case 'deleted': return statusDeleted;
      default: return statusSuspended;
    }
  }

  static const lightSurface = Color(0xFFFAFAFA);
  static const lightSurfaceContainer = Color(0xFFF5F5F5);
  static const lightSurfaceContainerHigh = Color(0xFFEEEEEE);
  static const lightOnSurface = Color(0xFF1A1A1A);
  static const lightOnSurfaceVariant = Color(0xFF666666);
  static const lightOutline = Color(0xFFE0E0E0);
  static const lightOutlineVariant = Color(0xFFEEEEEE);

  static const darkSurface = Color(0xFF1A1C20);
  static const darkSurfaceContainer = Color(0xFF22252A);
  static const darkSurfaceContainerHigh = Color(0xFF2A2E35);
  static const darkOnSurface = Color(0xFFE8EAED);
  static const darkOnSurfaceVariant = Color(0xFF9AA0A6);
  static const darkOutline = Color(0xFF3C4043);
  static const darkOutlineVariant = Color(0xFF2F3338);

  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 28.0;

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;
}

class DnsTypography {
  static const String fontFamily = 'Roboto';

  static TextStyle displayLarge({required Color color}) => TextStyle(
    fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5,
    color: color, fontFamily: fontFamily,
  );
  static TextStyle headlineLarge({required Color color}) => TextStyle(
    fontSize: 24, fontWeight: FontWeight.w600, color: color, fontFamily: fontFamily,
  );
  static TextStyle headlineMedium({required Color color}) => TextStyle(
    fontSize: 20, fontWeight: FontWeight.w600, color: color, fontFamily: fontFamily,
  );
  static TextStyle titleLarge({required Color color}) => TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600, color: color, fontFamily: fontFamily,
  );
  static TextStyle titleMedium({required Color color}) => TextStyle(
    fontSize: 16, fontWeight: FontWeight.w500, color: color, fontFamily: fontFamily,
  );
  static TextStyle bodyLarge({required Color color}) => TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400, color: color, fontFamily: fontFamily,
  );
  static TextStyle bodyMedium({required Color color}) => TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: color, fontFamily: fontFamily,
  );
  static TextStyle bodySmall({required Color color}) => TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: color, fontFamily: fontFamily,
  );
  static TextStyle labelLarge({required Color color}) => TextStyle(
    fontSize: 14, fontWeight: FontWeight.w500, color: color, fontFamily: fontFamily,
  );
  static TextStyle labelMedium({required Color color}) => TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500, color: color, fontFamily: fontFamily,
  );
  static TextStyle labelSmall({required Color color}) => TextStyle(
    fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5,
    color: color, fontFamily: fontFamily,
  );
}

class DnsSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class DnsRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 28.0;
  static const double full = 999.0;
}

class DnsElevation {
  static const double level0 = 0.0;
  static const double level1 = 1.0;
  static const double level2 = 3.0;
  static const double level3 = 6.0;
  static const double level4 = 8.0;
  static const double level5 = 12.0;
}

class DesignSystem {
  static final tokens = DnsDesignTokens();
  static final typography = DnsTypography();
  static final spacing = DnsSpacing();
  static final radius = DnsRadius();
  static final elevation = DnsElevation();
}
