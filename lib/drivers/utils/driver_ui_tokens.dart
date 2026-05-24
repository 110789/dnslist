import 'package:flutter/material.dart';

class DriverUiConstants {
  static const Color proxiedColor = Color(0xFF3B82F6);
  static const double iconSize = 16;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double horizontalPadding = 16;
  static const double verticalPadding = 12;
  static const double avatarSize = 44;
  static const double avatarRadius = 22;
}

class DriverTtlConstants {
  static const Color backgroundColor = Color(0xFFE8F4FD);
  static const Color textColor = Color(0xFF64748B);
  static const double fontSize = 11;
  static const FontWeight fontWeight = FontWeight.w600;
  static const double ttlHorizontalPadding = 8;
  static const double ttlVerticalPadding = 3;
  static const double borderRadius = 4;
}

class DriverColorConstants {
  static const Color dnsTypeA = Color(0xFF3B82F6);
  static const Color dnsTypeAAAA = Color(0xFF8B5CF6);
  static const Color dnsTypeCNAME = Color(0xFF10B981);
  static const Color dnsTypeMX = Color(0xFFF59E0B);
  static const Color dnsTypeTXT = Color(0xFF14B8A6);
  static const Color dnsTypeNS = Color(0xFF6366F1);
  static const Color dnsTypeSRV = Color(0xFFEC4899);
  static const Color dnsTypeCAA = Color(0xFF06B6D4);
  static const Color dnsTypeURL = Color(0xFFF97316);
  static const Color dnsTypeSPF = Color(0xFF84CC16);

  static Color getDnsTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'A': return dnsTypeA;
      case 'AAAA': return dnsTypeAAAA;
      case 'CNAME': return dnsTypeCNAME;
      case 'MX': return dnsTypeMX;
      case 'TXT': return dnsTypeTXT;
      case 'NS': return dnsTypeNS;
      case 'SRV': return dnsTypeSRV;
      case 'CAA': return dnsTypeCAA;
      case 'URL': return dnsTypeURL;
      case 'SPF': return dnsTypeSPF;
      default: return const Color(0xFF64748B);
    }
  }
}

class DriverUiTokens {
  static const double horizontalPadding = 16;
  static const double verticalPadding = 12;
  static const double spacing8 = 8;
  static const double spacing12 = 12;

  static Widget buildPriorityTag(int priority) => Text(
    'P$priority',
    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DriverColorConstants.dnsTypeMX),
  );

  static Widget buildProxiedIcon() => const Icon(Icons.cloud, size: DriverUiConstants.iconSize, color: DriverUiConstants.proxiedColor);

  static Widget buildDisabledTag() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(2),
    ),
    child: Text('暂停', style: const TextStyle(fontSize: 9, color: Colors.orange)),
  );

  static Widget buildDnsTypeAvatar(String type, Color typeColor) => Container(
    width: DriverUiConstants.avatarSize,
    height: DriverUiConstants.avatarSize,
    decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(DriverUiConstants.avatarRadius)),
    child: Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          type,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    ),
  );
}

class DriverTtlTokens {
  static Widget buildTtlTag(int ttl) {
    String label;
    if (ttl <= 0) {
      label = 'TTL: $ttl';
    } else if (ttl < 60) {
      label = 'TTL: ${ttl}s';
    } else if (ttl < 3600) {
      label = 'TTL: ${(ttl / 60).round()}m';
    } else if (ttl < 86400) {
      label = 'TTL: ${(ttl / 3600).round()}h';
    } else {
      label = 'TTL: ${(ttl / 86400).round()}d';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
      ),
    );
  }
}

class DriverColorTokens {
  static Color getDnsTypeColor(String type) => DriverColorConstants.getDnsTypeColor(type);
}