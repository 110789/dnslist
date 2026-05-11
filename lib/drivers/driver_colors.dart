import 'package:flutter/material.dart' show Color, Colors;

class DriverColorUtils {
  static Color getDnsTypeColor(String type) {
    const colorMap = {
      'A': Color(0xFF3B82F6),
      'AAAA': Color(0xFF8B5CF6),
      'CNAME': Color(0xFF10B981),
      'MX': Color(0xFFF59E0B),
      'TXT': Color(0xFF14B8A6),
      'NS': Color(0xFF6366F1),
      'SRV': Color(0xFFEC4899),
      'CAA': Color(0xFFEC4899),
    };
    return colorMap[type.toUpperCase()] ?? const Color(0xFF64748B);
  }

  static Color getStatusColor(String status) {
    const colorMap = {
      'active': Color(0xFF10B981),
      '活跃': Color(0xFF10B981),
      'pending': Color(0xFFF59E0B),
      '待处理': Color(0xFFF59E0B),
      'expired': Color(0xFFEF4444),
      '已过期': Color(0xFFEF4444),
      'suspended': Color(0xFF64748B),
      '已暂停': Color(0xFF64748B),
      'deleted': Color(0xFF94A3B8),
      '已删除': Color(0xFF94A3B8),
    };
    return colorMap[status.toLowerCase()] ?? const Color(0xFF64748B);
  }

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color dnsTypeA = Color(0xFF3B82F6);
  static const Color dnsTypeAAAA = Color(0xFF8B5CF6);
  static const Color dnsTypeCNAME = Color(0xFF10B981);
  static const Color dnsTypeMX = Color(0xFFF59E0B);
  static const Color dnsTypeTXT = Color(0xFF14B8A6);
  static const Color dnsTypeNS = Color(0xFF6366F1);
  static const Color dnsTypeSRV = Color(0xFFEC4899);
  static const Color dnsTypeCAA = Color(0xFFEC4899);
}