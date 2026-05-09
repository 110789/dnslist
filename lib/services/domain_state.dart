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
        throw Exception('Invalid credentials');
      }

      final result = await driver.getDomains();
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

  void clear() {
    _domains = [];
    _dnsRecords = {};
    _selectedDomainId = null;
    _error = null;
    notifyListeners();
  }
}