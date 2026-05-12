import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class DriverConstants {
  static const int maxMessageLen = 200;
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
}

class DriverTtlTokens {
  static const Color backgroundColor = Color(0xFFE8F4FD);
  static const Color textColor = Color(0xFF64748B);
  static const double fontSize = 11;
  static const FontWeight fontWeight = FontWeight.w600;
  static const double horizontalPadding = 8;
  static const double verticalPadding = 3;
  static const double borderRadius = 4;

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
      padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: textColor),
      ),
    );
  }
}

class DriverUiTokens {
  static const Color proxiedColor = Color(0xFF3B82F6);
  static const double iconSize = 16;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double horizontalPadding = 16;
  static const double verticalPadding = 12;
  static const double avatarSize = 44;
  static const double avatarRadius = 22;

  static Widget buildPriorityTag(int priority) => Text(
    'P$priority',
    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: DriverColorTokens.dnsTypeMX),
  );

  static Widget buildProxiedIcon() => const Icon(Icons.cloud, size: iconSize, color: proxiedColor);

  static Widget buildDisabledTag() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(2),
    ),
    child: const Text('暂停', style: TextStyle(fontSize: 9, color: Colors.orange)),
  );

  static Widget buildDnsTypeAvatar(String type, Color typeColor) => Container(
    width: avatarSize,
    height: avatarSize,
    decoration: BoxDecoration(color: typeColor, borderRadius: BorderRadius.circular(avatarRadius)),
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

class DriverColorTokens {
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

class DioErrorParser {
  static Map<String, dynamic> parse(Object e) {
    if (e is! DioException) return {'error': 'Request failed', 'errorCode': 'UNKNOWN'};

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return {'error': 'Connection timeout', 'errorCode': 'TIMEOUT'};
      case DioExceptionType.receiveTimeout:
        return {'error': 'Response timeout', 'errorCode': 'TIMEOUT'};
      case DioExceptionType.connectionError:
        return {'error': 'Connection failed', 'errorCode': 'NETWORK'};
      case DioExceptionType.cancel:
        return {'error': 'Request cancelled', 'errorCode': 'CANCELLED'};
      default:
        return {'error': 'Request failed', 'errorCode': 'UNKNOWN'};
    }
  }

  static String truncateMessage(String message, {int maxLen = DriverConstants.maxMessageLen}) {
    if (message.length <= maxLen) return message;
    return message.substring(0, maxLen);
  }
}

class DriverResponseParser {
  static Map<String, dynamic> parseEmpty() => {'error': 'Empty response', 'errorCode': 'EMPTY'};
  static Map<String, dynamic> parseInvalid() => {'error': 'Invalid response', 'errorCode': 'INVALID'};

  static Map<String, dynamic> parseError(String message, String errorCode) {
    final truncated = message.length > DriverConstants.maxMessageLen
        ? message.substring(0, DriverConstants.maxMessageLen)
        : message;
    return {'error': truncated, 'errorCode': errorCode};
  }

  static Map<String, dynamic> parseException(Object e) {
    final result = DioErrorParser.parse(e);
    if (result['errorCode'] != 'UNKNOWN') return result;

    if (e is! DioException) return result;
    final responseData = e.response?.data;
    if (responseData != null) {
      if (responseData is Map) {
        final message = _extractMessage(responseData);
        if (message.isNotEmpty) {
          return {'error': message, 'errorCode': 'RESPONSE_ERROR'};
        }
      } else if (responseData is String) {
        return {'error': responseData, 'errorCode': 'RESPONSE_ERROR'};
      }
    }
    return result;
  }

  static String _extractMessage(Map data) {
    if (data.containsKey('message')) return data['message']?.toString() ?? '';
    if (data.containsKey('error')) return data['error']?.toString() ?? '';
    if (data.containsKey('msg')) return data['msg']?.toString() ?? '';
    if (data.containsKey('statusDescription')) return data['statusDescription']?.toString() ?? '';
    return '';
  }
}

dynamic parseJson(String jsonStr) {
  try {
    return jsonDecode(jsonStr);
  } catch (_) {
    return null;
  }
}