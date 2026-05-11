import 'package:flutter/foundation.dart';
import '../drivers/driver_factory.dart';
import '../drivers/driver_manager.dart';

class DomainState extends ChangeNotifier {
  List<Map<String, dynamic>> _domains = [];
  Map<String, List<Map<String, dynamic>>> _dnsRecords = {};
  bool _isLoading = false;
  String? _error;
  String? _errorCode;
  String? _selectedDomainId;

  DomainState();

  List<Map<String, dynamic>> get domains => _domains;
  Map<String, List<Map<String, dynamic>>> get dnsRecords => _dnsRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorCode => _errorCode;
  String? get selectedDomainId => _selectedDomainId;

  List<Map<String, dynamic>> get currentDnsRecords {
    if (_selectedDomainId == null) return [];
    return _dnsRecords[_selectedDomainId] ?? [];
  }

  Future<Map<String, dynamic>> loadDomains(String providerId, Map<String, String> credentials) async {
    _domains = [];
    _isLoading = true;
    _error = null;
    _errorCode = null;
    notifyListeners();

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        final result = <String, dynamic>{'success': false, 'error': 'Provider not found: $providerId', 'errorCode': 'PROVIDER_NOT_FOUND', 'statusCode': 404};
        _error = result['error'] as String;
        _errorCode = result['errorCode'] as String;
        _isLoading = false;
        notifyListeners();
        return result;
      }

      final valid = await driver.validateCredential(credentials);
      if (!valid) {
        final result = <String, dynamic>{'success': false, 'error': '凭证无效或权限不足', 'errorCode': 'AUTH_FAILED', 'statusCode': 401};
        _error = result['error'] as String;
        _errorCode = result['errorCode'] as String;
        _isLoading = false;
        notifyListeners();
        return result;
      }

      final result = await driver.getDomains();
      
      if (result['error'] != null) {
        final errorCode = result['errorCode'] ?? 'UNKNOWN';
        final errorMessage = result['error'] ?? '操作失败';
        _error = errorMessage;
        _errorCode = errorCode;
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'error': errorMessage, 'errorCode': errorCode, 'statusCode': result['statusCode']};
      }
      
      _domains = List<Map<String, dynamic>>.from(result['domains'] ?? []);
      DriverManager().setCredential(providerId, credentials);
      _isLoading = false;
      notifyListeners();
      return {'success': true, 'statusCode': result['statusCode'] ?? 'OK'};
    } catch (e) {
      _error = e.toString();
      _errorCode = 'EXCEPTION';
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  Future<Map<String, dynamic>> loadDnsRecords(String providerId, String domainId) async {
    _dnsRecords[domainId] = [];
    _isLoading = true;
    _error = null;
    _error = null;
    _errorCode = null;
    notifyListeners();

    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        final result = <String, dynamic>{'success': false, 'error': 'Provider not found', 'errorCode': 'PROVIDER_NOT_FOUND', 'statusCode': 404};
        _error = result['error'] as String;
        _errorCode = result['errorCode'] as String;
        _isLoading = false;
        notifyListeners();
        return result;
      }

      final result = await driver.getDnsRecords(domainId);
      
      if (result['error'] != null) {
        final errorCode = result['errorCode'] ?? 'UNKNOWN';
        final errorMessage = result['error'] ?? '操作失败';
        _error = errorMessage;
        _errorCode = errorCode;
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'error': errorMessage, 'errorCode': errorCode, 'statusCode': result['statusCode']};
      }
      
      _dnsRecords[domainId] = List<Map<String, dynamic>>.from(result['records'] ?? []);
      _selectedDomainId = domainId;
      _isLoading = false;
      notifyListeners();
      return {'success': true, 'statusCode': result['statusCode'] ?? 'OK'};
    } catch (e) {
      _error = e.toString();
      _errorCode = 'EXCEPTION';
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  void selectDomain(String domainId) {
    _selectedDomainId = domainId;
    notifyListeners();
  }

  Future<Map<String, dynamic>> addDomain(String providerId, Map<String, dynamic> domainData, Map<String, String> credentials) async {
    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        return {'success': false, 'error': 'Provider not found', 'errorCode': 'PROVIDER_NOT_FOUND', 'statusCode': 404};
      }

      final result = await driver.createDomain(domainData);
      
      if (result['error'] != null) {
        return {'success': false, 'error': result['error'], 'errorCode': result['errorCode'] ?? 'UNKNOWN', 'statusCode': result['statusCode']};
      }
      
      _domains = [];
      _isLoading = true;
      notifyListeners();
      
      final reloadResult = await driver.getDomains();
      _isLoading = false;
      
      if (reloadResult['success'] == true) {
        _domains = List<Map<String, dynamic>>.from(reloadResult['domains'] ?? []);
      } else {
        _domains = [];
      }
      notifyListeners();
      return {'success': true, 'statusCode': 'OK', 'data': result['data']};
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  Future<Map<String, dynamic>> deleteDomain(String providerId, String domainId) async {
    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        return {'success': false, 'error': 'Provider not found', 'errorCode': 'PROVIDER_NOT_FOUND', 'statusCode': 404};
      }

      final result = await driver.deleteDomain(domainId);

      if (result['success'] == true) {
        _domains = [];
        _isLoading = true;
        notifyListeners();
        
        final reloadResult = await driver.getDomains();
        _isLoading = false;
        
        if (reloadResult['success'] == true) {
          _domains = List<Map<String, dynamic>>.from(reloadResult['domains'] ?? []);
        } else {
          _domains = [];
        }
        notifyListeners();
        return {'success': true, 'statusCode': 'OK'};
      }

      return result;
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  Future<Map<String, dynamic>> refreshDomains(String providerId, Map<String, String> credentials) async {
    _domains = [];
    notifyListeners();
    return loadDomains(providerId, credentials);
  }

  Future<Map<String, dynamic>> renewDomain(String providerId, String domainId, Map<String, String> credentials) async {
    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        return {'success': false, 'error': 'Provider not found', 'errorCode': 'PROVIDER_NOT_FOUND', 'statusCode': 404};
      }

      final result = await driver.renewDomain(domainId);
      
      if (result['error'] != null) {
        return {'success': false, 'error': result['error'], 'errorCode': result['errorCode'] ?? 'UNKNOWN', 'statusCode': result['statusCode']};
      }
      
      _domains = [];
      _isLoading = true;
      notifyListeners();
      
      final reloadResult = await driver.getDomains();
      _isLoading = false;
      
      if (reloadResult['success'] == true) {
        _domains = List<Map<String, dynamic>>.from(reloadResult['domains'] ?? []);
      } else {
        _domains = [];
      }
      notifyListeners();
      return {'success': true, 'statusCode': 'OK', 'data': result['data']};
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  Future<Map<String, dynamic>> createDnsRecord(String providerId, String domainId, Map<String, dynamic> recordData) async {
    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        return {'success': false, 'error': 'Provider not found', 'errorCode': 'PROVIDER_NOT_FOUND', 'statusCode': 404};
      }

      final result = await driver.createDnsRecord(domainId, recordData);
      
      if (result['error'] != null) {
        return {'success': false, 'error': result['error'], 'errorCode': result['errorCode'] ?? 'UNKNOWN', 'statusCode': result['statusCode']};
      }
      
      _dnsRecords[domainId] = [];
      _isLoading = true;
      notifyListeners();
      
      final reloadResult = await driver.getDnsRecords(domainId);
      _isLoading = false;
      
      if (reloadResult['success'] == true) {
        _dnsRecords[domainId] = List<Map<String, dynamic>>.from(reloadResult['records'] ?? []);
      } else {
        _dnsRecords[domainId] = [];
      }
      notifyListeners();
      return {'success': true, 'statusCode': 'OK', 'data': result['data']};
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  Future<Map<String, dynamic>> updateDnsRecord(String providerId, String domainId, String recordId, Map<String, dynamic> recordData) async {
    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        return {'success': false, 'error': 'Provider not found', 'errorCode': 'PROVIDER_NOT_FOUND', 'statusCode': 404};
      }

      final result = await driver.updateDnsRecord(domainId, recordId, recordData);
      
      if (result['error'] != null) {
        return {'success': false, 'error': result['error'], 'errorCode': result['errorCode'] ?? 'UNKNOWN', 'statusCode': result['statusCode']};
      }
      
      _dnsRecords[domainId] = [];
      _isLoading = true;
      notifyListeners();
      
      final reloadResult = await driver.getDnsRecords(domainId);
      _isLoading = false;
      
      if (reloadResult['success'] == true) {
        _dnsRecords[domainId] = List<Map<String, dynamic>>.from(reloadResult['records'] ?? []);
      } else {
        _dnsRecords[domainId] = [];
      }
      notifyListeners();
      return {'success': true, 'statusCode': 'OK', 'data': result['data']};
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

Future<Map<String, dynamic>> deleteDnsRecord(String providerId, String domainId, String recordId) async {
    try {
      final driver = DriverFactory.get(providerId);
      if (driver == null) {
        return {'success': false, 'error': 'Provider not found', 'errorCode': 'PROVIDER_NOT_FOUND', 'statusCode': 404};
      }

      final result = await driver.deleteDnsRecord(domainId, recordId);
      
      if (result['success'] == true) {
        _dnsRecords[domainId] = [];
        _isLoading = true;
        notifyListeners();
        
        final reloadResult = await driver.getDnsRecords(domainId);
        _isLoading = false;
        
        if (reloadResult['success'] == true) {
          _dnsRecords[domainId] = List<Map<String, dynamic>>.from(reloadResult['records'] ?? []);
        } else {
          _dnsRecords[domainId] = [];
        }
        notifyListeners();
        return {'success': true, 'statusCode': 'OK'};
      }

      return result;
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  void clear() {
    _domains = [];
    _dnsRecords = {};
    _selectedDomainId = null;
    _error = null;
    _errorCode = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _errorCode = null;
    notifyListeners();
  }
}