import 'driver_factory.dart';
import 'cloudflare/cloudflare_driver.dart';
import 'dnshe/dnshe_driver.dart';
import 'dnspod/dnspod_driver.dart';

class DriverRegistry {
  static bool _registered = false;

  static void registerAll() {
    if (_registered) return;
    DriverFactory.register(CloudflareDriver());
    DriverFactory.register(DnsheDriver());
    DriverFactory.register(DnspodDriver());
    _registered = true;
  }

  static Future<void> initialize() async {
    registerAll();
    await DriverFactory.initialize();
  }

  DriverRegistry._();
}