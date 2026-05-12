export 'core.dart';
export 'parser.dart';
export 'zone.dart';
export 'dns.dart';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../interfaces/driver_interface.dart';
import '../../utils/driver/driver_utils.dart';
import 'core.dart';
import 'parser.dart';
import 'zone.dart';
import 'dns.dart';

class RainyunDriver implements DriverInterface {
  Dio? _client;
  String? _apiKey;
  RainyunZone? _zone;
  RainyunDns? _dns;

  @override
  String get providerId => RainyunCore.providerId;

  @override
  String get providerName => RainyunCore.providerName;

  @override
  String get providerIcon => RainyunCore.providerIcon;

  @override
  String mapErrorCode(String code) => '';

  @override
  String getAddDomainTitle() => '添加域名';

  @override
  List<AddDomainField> getAddDomainFields() => [
    const AddDomainField(key: 'domain', label: '域名', hintText: '例如: example.com', description: '输入要添加的域名'),
  ];

  @override
  Map<String, dynamic> prepareDomainData(Map<String, dynamic> input) => {
    'domain': input['domain'] ?? input['name'] ?? '',
  };

  @override
  Future<Map<String, dynamic>> validateCredential(Map<String, String> credentials) async {
    final apiKey = credentials['apiKey'];
    if (apiKey == null || apiKey.isEmpty) {
      return {'success': false, 'error': 'API Key cannot be empty', 'errorCode': 'INVALID_CREDENTIAL'};
    }

    try {
      final dio = RainyunCore.createTestClient(apiKey);
      final response = await dio.get('/product/');

      if (response.data == null) {
        return {'success': false, 'error': 'Empty response from server', 'errorCode': 'EMPTY_RESPONSE'};
      }

      final result = RainyunParser.parseResponse(response.data);
      if (result['success'] == true) {
        _apiKey = apiKey;
        _client = RainyunCore.createClient(apiKey);
        _zone = RainyunZone(_client!);
        _dns = RainyunDns(_client!);
        return {'success': true};
      }

      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    } catch (e) {
      final result = RainyunParser.parseException(e, e is DioException ? e : null);
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    }
  }

  @override
  Future<Map<String, dynamic>> getDomains({
    int page = 1,
    int pageSize = 20,
    Map<String, String>? filters,
  }) async {
    if (_zone == null) {
      return {'domains': [], 'pagination': {}, 'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }
    return _zone!.getList(page: page, pageSize: pageSize, filters: filters);
  }

  @override
  Future<Map<String, dynamic>> getDnsRecords(
    String domainId, {
    int page = 1,
    int pageSize = 50,
    Map<String, String>? filters,
  }) async {
    if (_dns == null) {
      return {'records': [], 'pagination': {}, 'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }
    return _dns!.getRecords(domainId, page: page, pageSize: pageSize, filters: filters);
  }

  @override
  Future<Map<String, dynamic>> createDnsRecord(
    String domainId,
    Map<String, dynamic> recordData,
  ) async {
    if (_dns == null) {
      return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }
    return _dns!.createRecord(domainId, recordData);
  }

  @override
  Future<Map<String, dynamic>> updateDnsRecord(
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
  ) async {
    if (_dns == null) {
      return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }
    return _dns!.updateRecord(domainId, recordId, recordData);
  }

  @override
  Future<Map<String, dynamic>> deleteDnsRecord(String domainId, String recordId) async {
    if (_dns == null) {
      return {'success': false, 'error': '', 'errorCode': 'NOT_INITIALIZED'};
    }
    return _dns!.deleteRecord(domainId, recordId);
  }

  @override
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData) async {
    if (_zone == null) {
      return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }
    return _zone!.create(domainData);
  }

  @override
  Future<Map<String, dynamic>> deleteDomain(String domainId) async {
    if (_zone == null) {
      return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }
    return _zone!.delete(domainId);
  }

  @override
  Future<Map<String, dynamic>> renewDomain(String domainId) async {
    if (_zone == null) {
      return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }
    return _zone!.renew(domainId);
  }

  @override
  bool get supportsAddDomain => false;

  @override
  bool get supportsDeleteDomain => false;

  @override
  bool get supportsRenewDomain => false;

  @override
  bool get supportsShowNameServers => false;

  @override
  Widget buildDomainListItem(
    Map<String, dynamic> domainData, {
    required VoidCallback onTap,
    required VoidCallback onDelete,
    required VoidCallback onRenew,
    required bool supportsDelete,
    required bool supportsRenew,
  }) => const SizedBox.shrink();

  @override
  Widget buildDnsRecordListItem(Map<String, dynamic> recordData) {
    final name = recordData['host']?.toString() ?? recordData['name']?.toString() ?? '';
    final type = recordData['type']?.toString() ?? recordData['record_type']?.toString() ?? 'A';
    final content = recordData['value']?.toString() ?? recordData['content']?.toString() ?? '';
    final ttl = recordData['ttl'] as int? ?? 600;
    final level = recordData['level'] as int? ?? recordData['priority'] as int? ?? 1;
    final line = recordData['line']?.toString() ?? 'DEFAULT';
    final enabled = recordData['enabled'] == true || recordData['status']?.toString() == 'enabled';
    final typeColor = DriverColorTokens.getDnsTypeColor(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DriverUiTokens.horizontalPadding, vertical: DriverUiTokens.verticalPadding),
      child: Row(
        children: [
          DriverUiTokens.buildDnsTypeAvatar(type, typeColor),
          const SizedBox(width: DriverUiTokens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(name.isEmpty ? '@' : name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (type == 'MX' || type == 'SRV') ...[
                      const SizedBox(width: 4),
                      DriverUiTokens.buildPriorityTag(level),
                    ],
                    if (!enabled) ...[
                      const SizedBox(width: 4),
                      DriverUiTokens.buildDisabledTag(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(content, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: DriverUiTokens.spacing8),
          DriverTtlTokens.buildTtlTag(ttl),
          if (line != 'DEFAULT') ...[
            const SizedBox(width: 4),
            _buildLineTag(line),
          ],
        ],
      ),
    );
  }

  Widget _buildLineTag(String line) {
    String label;
    switch (line) {
      case 'LTEL': label = '电信'; break;
      case 'LCNC': label = '联通'; break;
      case 'LMOB': label = '移动'; break;
      case 'LEDU': label = '教育'; break;
      case 'LSEO': label = '搜索'; break;
      case 'LFOR': label = '国外'; break;
      default: label = line;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(label, style: const TextStyle(fontSize: 9, color: Colors.blue)),
    );
  }

  @override
  void showDomainListItemMenu(
    BuildContext context,
    Map<String, dynamic> domainData, {
    required VoidCallback onDelete,
    required VoidCallback onRenew,
    required VoidCallback onShowNameServers,
    required bool supportsDelete,
    required bool supportsRenew,
    required bool supportsShowNameServers,
  }) {}

  @override
  Map<String, String> getCredentialFields() => {'apiKey': 'API Key'};

  @override
  List<String> getSupportedRecordTypes() => ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'SRV'];
}