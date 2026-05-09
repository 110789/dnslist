import 'package:flutter/foundation.dart';
import '../drivers/driver_factory.dart';
import '../drivers/driver_manager.dart';

class DomainState extends ChangeNotifier {
  List<Map<String, dynamic>> _domains = [];
  Map<String, List<Map<String, dynamic>>> _dnsRecords = {};
  bool _isLoading = false;
  String? _error;
  String? _selectedDomainId;

  DomainState();

  List<Map<String, dynamic>> get domains => _domains;
  Map<String, List<Map<String, dynamic>>> get dnsRecords => _dnsRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedDomainId => _selectedDomainId;

  List<Map<String, dynamic>> get currentDnsRecords {
    if (_selectedDomainId == null) return [];
    return _dnsRecords[_selectedDomainId] ?? [];
  }

  Future<void> loadDomains(String providerId, Map<String, String> credentials) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        throw Exception('Provider not found: $providerId');
      }

      final valid = await driver.validateCredential(credentials);
      if (!valid) {
        throw Exception('凭证无效或权限不足，请检查 API Token 是否正确且具有 Zone:Read 权限');
      }

      final result = await driver.getDomains();
      
      if (result['error'] != null) {
        final errorCode = result['errorCode'];
        if (errorCode == 9109) {
          throw Exception('权限不足 (9109)：API Token 缺少访问域名的权限，请确保 Token 具有 Zone:Read 和 DNS:Read 权限');
        }
        throw Exception(result['error']);
      }
      
      _domains = List<Map<String, dynamic>>.from(result['domains'] ?? []);

      DriverManager().setCredential(providerId, credentials);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDnsRecords(String providerId, String domainId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        throw Exception('Provider not found');
      }

      final result = await driver.getDnsRecords(domainId);
      
      if (result['error'] != null) {
        final errorCode = result['errorCode'];
        if (errorCode == 9109) {
          throw Exception('权限不足 (9109)：API Token 缺少读取 DNS 记录的权限');
        }
        throw Exception(result['error']);
      }
      
      _dnsRecords[domainId] = List<Map<String, dynamic>>.from(result['records'] ?? []);
      _selectedDomainId = domainId;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDomain(String domainId) {
    _selectedDomainId = domainId;
    notifyListeners();
  }

  Future<Map<String, dynamic>> addDomain(String providerId, Map<String, dynamic> domainData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        throw Exception('Provider not found');
      }

      final result = await driver.createDomain(domainData);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'error': e.toString()};
    }
  }

  Future<void> deleteDomain(String providerId, String domainId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        throw Exception('Provider not found');
      }

      await driver.deleteDomain(domainId);
      _domains.removeWhere((d) => d['id'].toString() == domainId.toString());
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> renewDomain(String providerId, String domainId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        throw Exception('Provider not found');
      }

      final result = await driver.renewDomain(domainId);
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'error': e.toString()};
    }
  }

  void clear() {
    _domains = [];
    _dnsRecords = {};
    _selectedDomainId = null;
    _error = null;
    notifyListeners();
  }
}