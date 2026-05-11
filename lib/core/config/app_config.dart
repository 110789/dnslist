class AppConfig {
  static const String appName = 'DNS管理工具';
  static const String appVersion = '1.0.0';

  static const String cloudflareBaseUrl = 'https://api.cloudflare.com/client/v4';
  static const String dnsheBaseUrl = 'https://api005.dnshe.com/index.php';
  static const String dnspodBaseUrl = 'https://dnspod.tencentcloudapi.com';
  static const String cloudnsBaseUrl = 'https://api.cloudns.net';

  static const int defaultPageSize = 20;
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  AppConfig._();
}