import 'package:dio/dio.dart';
import 'package:flutter/material.dart' show Color;

class DriverConstants {
  static const int maxMessageLen = 200;
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

class DriverColorTokens {
  static const Color dnsTypeA = Color(0xFF3B82F6);
  static const Color dnsTypeAAAA = Color(0xFF8B5CF6);
  static const Color dnsTypeCNAME = Color(0xFF10B981);
  static const Color dnsTypeMX = Color(0xFFF59E0B);
  static const Color dnsTypeTXT = Color(0xFF14B8A6);
  static const Color dnsTypeNS = Color(0xFF6366F1);
  static const Color dnsTypeSRV = Color(0xFFEC4899);

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
}