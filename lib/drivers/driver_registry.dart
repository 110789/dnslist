import 'driver_factory.dart';
import 'cloudflare/index.dart';
import 'dnshe/index.dart';
import 'dnspod/index.dart';
import 'cloudns/index.dart';
import 'rainyun/index.dart';
import 'dart:developer' as developer;

class DriverRegistry {
  static bool _registered = false;

  static void registerAll() {
    if (_registered) return;
    try {
      DriverFactory.register(CloudflareDriver());
      developer.log('CloudflareDriver registered', name: 'DriverRegistry');
    } catch (e) {
      developer.log('CloudflareDriver registration failed: $e', name: 'DriverRegistry', error: e);
    }
    try {
      DriverFactory.register(DnsheDriver());
      developer.log('DnsheDriver registered', name: 'DriverRegistry');
    } catch (e) {
      developer.log('DnsheDriver registration failed: $e', name: 'DriverRegistry', error: e);
    }
    try {
      DriverFactory.register(DnspodDriver());
      developer.log('DnspodDriver registered', name: 'DriverRegistry');
    } catch (e) {
      developer.log('DnspodDriver registration failed: $e', name: 'DriverRegistry', error: e);
    }
    try {
      DriverFactory.register(ClouDNSDriver());
      developer.log('ClouDNSDriver registered', name: 'DriverRegistry');
    } catch (e) {
      developer.log('ClouDNSDriver registration failed: $e', name: 'DriverRegistry', error: e);
    }
    try {
      DriverFactory.register(RainyunDriver());
      developer.log('RainyunDriver registered', name: 'DriverRegistry');
    } catch (e) {
      developer.log('RainyunDriver registration failed: $e', name: 'DriverRegistry', error: e);
    }
    _registered = true;
  }

  static Future<void> initialize() async {
    registerAll();
    await DriverFactory.initialize();
  }

  DriverRegistry._();
}