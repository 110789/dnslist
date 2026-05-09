import 'package:flutter/material.dart';

class DesignSystem {
  static const primaryLight = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF3B82F6);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  static const textPrimaryLight = Color(0xFF1E293B);
  static const textSecondaryLight = Color(0xFF64748B);
  static const textTertiaryLight = Color(0xFF94A3B8);
  static const textPrimaryDark = Color(0xFFF1F5F9);
  static const textSecondaryDark = Color(0xFF94A3B8);
  static const textTertiaryDark = Color(0xFF64748B);

  static const bgPrimaryLight = Color(0xFFFFFFFF);
  static const bgSecondaryLight = Color(0xFFF8FAFC);
  static const bgTertiaryLight = Color(0xFFF1F5F9);
  static const bgPrimaryDark = Color(0xFF0F172A);
  static const bgSecondaryDark = Color(0xFF1E293B);
  static const bgTertiaryDark = Color(0xFF334155);

  static const borderLight = Color(0xFFE2E8F0);
  static const borderDark = Color(0xFF334155);

  static const dnsTypeColors = DnsColors();
  static const typographyLight = TypographyLight();
  static const typographyDark = TypographyDark();
  static const spacing = Spacing();
  static const radius = RadiusSize();
  static const elevation = ElevationSize();
}

class DnsColors {
  const DnsColors();

  static const Color a = Color(0xFF3B82F6);
  static const Color aaaa = Color(0xFF8B5CF6);
  static const Color cname = Color(0xFF10B981);
  static const Color mx = Color(0xFFF59E0B);
  static const Color txt = Color(0xFF14B8A6);
  static const Color ns = Color(0xFF6366F1);
  static const Color srv = Color(0xFFEC4899);
  static const Color other = Color(0xFF64748B);

  Color getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'A': return a;
      case 'AAAA': return aaaa;
      case 'CNAME': return cname;
      case 'MX': return mx;
      case 'TXT': return txt;
      case 'NS': return ns;
      case 'SRV': return srv;
      default: return other;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case '活跃':
      case 'active':
        return DesignSystem.success;
      case '待处理':
      case 'pending':
        return DesignSystem.warning;
      case '已过期':
      case 'expired':
        return DesignSystem.error;
      case '已暂停':
      case 'suspended':
        return const Color(0xFF64748B);
      case '已删除':
      case 'deleted':
        return DesignSystem.error.withValues(alpha: 0.6);
      default:
        return const Color(0xFF64748B);
    }
  }
}

class TypographyLight {
  const TypographyLight();

  TextStyle get displayLarge => const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: DesignSystem.textPrimaryLight);
  TextStyle get displayMedium => const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.25, color: DesignSystem.textPrimaryLight);
  TextStyle get headlineLarge => const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: DesignSystem.textPrimaryLight);
  TextStyle get headlineMedium => const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: DesignSystem.textPrimaryLight);
  TextStyle get titleLarge => const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: DesignSystem.textPrimaryLight);
  TextStyle get titleMedium => const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: DesignSystem.textPrimaryLight);
  TextStyle get bodyLarge => const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: DesignSystem.textPrimaryLight);
  TextStyle get bodyMedium => const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: DesignSystem.textSecondaryLight);
  TextStyle get bodySmall => const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: DesignSystem.textTertiaryLight);
  TextStyle get labelLarge => const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: DesignSystem.textPrimaryLight);
  TextStyle get labelMedium => const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: DesignSystem.textSecondaryLight);
  TextStyle get labelSmall => const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: DesignSystem.textTertiaryLight);
}

class TypographyDark {
  const TypographyDark();

  TextStyle get displayLarge => const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: DesignSystem.textPrimaryDark);
  TextStyle get displayMedium => const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.25, color: DesignSystem.textPrimaryDark);
  TextStyle get headlineLarge => const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: DesignSystem.textPrimaryDark);
  TextStyle get headlineMedium => const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: DesignSystem.textPrimaryDark);
  TextStyle get titleLarge => const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: DesignSystem.textPrimaryDark);
  TextStyle get titleMedium => const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: DesignSystem.textPrimaryDark);
  TextStyle get bodyLarge => const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: DesignSystem.textPrimaryDark);
  TextStyle get bodyMedium => const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: DesignSystem.textSecondaryDark);
  TextStyle get bodySmall => const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: DesignSystem.textTertiaryDark);
  TextStyle get labelLarge => const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: DesignSystem.textPrimaryDark);
  TextStyle get labelMedium => const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: DesignSystem.textSecondaryDark);
  TextStyle get labelSmall => const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: DesignSystem.textTertiaryDark);
}

class Spacing {
  const Spacing();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  EdgeInsets get paddingXs => const EdgeInsets.all(xs);
  EdgeInsets get paddingSm => const EdgeInsets.all(sm);
  EdgeInsets get paddingMd => const EdgeInsets.all(md);
  EdgeInsets get paddingLg => const EdgeInsets.all(lg);
  EdgeInsets get paddingXl => const EdgeInsets.all(xl);
  EdgeInsets get horizontalSm => const EdgeInsets.symmetric(horizontal: sm);
  EdgeInsets get horizontalMd => const EdgeInsets.symmetric(horizontal: md);
  EdgeInsets get horizontalLg => const EdgeInsets.symmetric(horizontal: lg);
  EdgeInsets get verticalSm => const EdgeInsets.symmetric(vertical: sm);
  EdgeInsets get verticalMd => const EdgeInsets.symmetric(vertical: md);
  EdgeInsets get verticalLg => const EdgeInsets.symmetric(vertical: lg);
  EdgeInsets get screenPadding => const EdgeInsets.symmetric(horizontal: md, vertical: sm);
}

class RadiusSize {
  const RadiusSize();

  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;

  BorderRadius get radiusXs => BorderRadius.circular(xs);
  BorderRadius get radiusSm => BorderRadius.circular(sm);
  BorderRadius get radiusMd => BorderRadius.circular(md);
  BorderRadius get radiusLg => BorderRadius.circular(lg);
  BorderRadius get radiusXl => BorderRadius.circular(xl);
  BorderRadius get radiusXxl => BorderRadius.circular(xxl);
  BorderRadius get radiusFull => BorderRadius.circular(full);
}

class ElevationSize {
  const ElevationSize();

  static const double none = 0.0;
  static const double xs = 1.0;
  static const double sm = 2.0;
  static const double md = 4.0;
  static const double lg = 8.0;
  static const double xl = 12.0;

  BoxShadow get shadowNone => const BoxShadow(color: Colors.transparent);
  BoxShadow get shadowXs => BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1));
  BoxShadow get shadowSm => BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2));
  BoxShadow get shadowMd => BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4));
  BoxShadow get shadowLg => BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 8));
  BoxShadow get shadowXl => BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 12));
}