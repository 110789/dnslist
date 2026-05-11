import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import '../../utils/storage/local_storage.dart';
import '../../utils/network/api_client.dart';
import 'service_registry.dart';

class ThemeServiceImpl implements ThemeService {
  @override
  Color getDnsTypeColor(String type) => DnsDesignTokens.getDnsTypeColor(type);
  
  @override
  Color getStatusColor(String status) => DnsDesignTokens.getStatusColor(status);
  
  @override
  Color get successColor => DnsDesignTokens.success;
  
  @override
  Color get warningColor => DnsDesignTokens.warning;
  
  @override
  Color get errorColor => DnsDesignTokens.error;
  
  @override
  Color get infoColor => DnsDesignTokens.info;
  
  @override
  double get spacingXs => DnsSpacing.xs;
  
  @override
  double get spacingSm => DnsSpacing.sm;
  
  @override
  double get spacingMd => DnsSpacing.md;
  
  @override
  double get spacingLg => DnsSpacing.lg;
  
  @override
  double get radiusSm => DnsRadius.sm;
  
  @override
  double get radiusMd => DnsRadius.md;
  
  @override
  double get radiusLg => DnsRadius.lg;
}

class NetworkServiceImpl implements NetworkService {
  final Map<String, ApiClient> _clients = {};

  String getBaseUrl(String providerId) {
    return ServiceRegistry.instance.getProviderBaseUrl(providerId);
  }

  ApiClient _getClient(String providerId) {
    if (!_clients.containsKey(providerId)) {
      final baseUrl = getBaseUrl(providerId);
      _clients[providerId] = ApiClient(baseUrl: baseUrl);
    }
    return _clients[providerId]!;
  }

  @override
  Future<Map<String, dynamic>> get(String url, {Map<String, dynamic>? queryParameters, Map<String, String>? headers}) async {
    final client = _getClient(_extractProviderId(url));
    final response = await client.get(url, queryParameters: queryParameters, headers: headers);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> post(String url, {dynamic data, Map<String, String>? headers}) async {
    final client = _getClient(_extractProviderId(url));
    final response = await client.post(url, data: data, headers: headers);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> put(String url, {dynamic data, Map<String, String>? headers}) async {
    final client = _getClient(_extractProviderId(url));
    final response = await client.put(url, data: data, headers: headers);
    return response.data;
  }

  @override
  Future<Map<String, dynamic>> delete(String url, {Map<String, String>? headers}) async {
    final client = _getClient(_extractProviderId(url));
    final response = await client.delete(url, headers: headers);
    return response.data;
  }

  String _extractProviderId(String url) {
    if (url.contains('cloudflare')) return 'cloudflare';
    if (url.contains('dnshe')) return 'dnshe';
    if (url.contains('dnspod')) return 'dnspod';
    if (url.contains('cloudns')) return 'cloudns';
    if (url.contains('rainyun')) return 'rainyun';
    return '';
  }
}

class StorageServiceImpl implements StorageService {
  final LocalStorage _storage;

  StorageServiceImpl(this._storage);

  @override
  Future<void> set(String key, dynamic value) async {
    if (value is String) {
      await _storage.setString(key, value);
    } else if (value is bool) {
      await _storage.setBool(key, value);
    } else {
      await _storage.setString(key, value.toString());
    }
  }

  @override
  Future<dynamic> get(String key) async {
    return _storage.getString(key);
  }

  @override
  Future<void> remove(String key) async {
    await _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    await _storage.clear();
  }
}