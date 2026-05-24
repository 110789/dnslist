export 'core.dart';
export 'parser.dart';
export 'zone.dart';
export 'dns.dart';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../interfaces/driver_interface.dart';
import '../utils/driver_ui_tokens.dart';
import 'core.dart';
import 'parser.dart';
import 'zone.dart';
import 'dns.dart';

class ClouDNSDriver implements DriverInterface {
  Dio? _client;
  int? _authId;
  String? _authPassword;
  CloudnsZone? _zone;
  CloudnsDns? _dns;

  @override
  String get providerId => CloudnsCore.providerId;

  @override
  String get providerName => CloudnsCore.providerName;

  @override
  String get providerIcon => CloudnsCore.providerIcon;

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
    final authIdStr = credentials['authId'];
    final authPassword = credentials['authPassword'];
    if (authIdStr == null || authPassword == null || authIdStr.isEmpty || authPassword.isEmpty) {
      return {'success': false, 'error': 'Auth ID or password cannot be empty', 'errorCode': 'INVALID_CREDENTIAL'};
    }

    final authId = int.tryParse(authIdStr);
    if (authId == null) {
      return {'success': false, 'error': 'Invalid auth ID format', 'errorCode': 'INVALID_CREDENTIAL'};
    }

    try {
      _authId = authId;
      _authPassword = authPassword;
      _client = CloudnsCore.createClient();

      final response = await _client!.get('/get-balance.json', queryParameters: {
        'auth-id': authId,
        'auth-password': authPassword,
      });

      final result = CloudnsParser.parseResponse(response.data);
      if (result['success'] == true) {
        _zone = CloudnsZone(_client!, _authId!, _authPassword!);
        _dns = CloudnsDns(_client!, _authId!, _authPassword!);
        return {'success': true};
      }

      _resetClient();
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    } catch (e) {
      final result = CloudnsParser.parseException(e, e is DioException ? e : null);
      _resetClient();
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    }
  }

  void _resetClient() {
    _authId = null;
    _authPassword = null;
    _client = null;
    _zone = null;
    _dns = null;
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
  bool get supportsAddDomain => true;

  @override
  bool get supportsDeleteDomain => true;

  @override
  bool get supportsRenewDomain => false;

  @override
  bool get supportsShowNameServers => false;

  @override
  bool get supportsProxy => false;

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
    final name = recordData['host']?.toString() ?? '';
    final type = recordData['type']?.toString() ?? 'A';
    final content = recordData['record']?.toString() ?? recordData['content']?.toString() ?? '';
    final ttl = recordData['ttl'] as int? ?? 3600;
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
                Text(name.isEmpty ? '@' : name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(content, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: DriverUiTokens.spacing8),
          DriverTtlTokens.buildTtlTag(ttl),
        ],
      ),
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
  }) {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + renderBox.size.width / 2,
        offset.dy + renderBox.size.height / 2,
        offset.dx + renderBox.size.width,
        offset.dy + renderBox.size.height,
      ),
      items: [
        if (supportsDelete) const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Color(0xFFEF4444)))),
      ],
    ).then((value) {
      if (value == 'delete') onDelete();
    });
  }

  @override
  Map<String, String> getCredentialFields() => {'authId': 'Auth ID', 'authPassword': 'Auth Password'};

  @override
  List<String> getSupportedRecordTypes() => ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SRV', 'SPF', 'CAA'];

  @override
  String getAddRecordTitle() => '添加DNS记录';

  @override
  String getEditRecordTitle() => '编辑DNS记录';

  @override
  bool supportsRecordLine() => false;

  @override
  List<DnsRecordField> getAddRecordFields() {
    return [
      const DnsRecordField(
        key: 'host',
        label: '主机记录',
        hintText: '例如: www 或 @',
      ),
      const DnsRecordField(
        key: 'record',
        label: '记录值',
        hintText: '例如: 192.168.1.1',
      ),
      const DnsRecordField(
        key: 'ttl',
        label: 'TTL (秒)',
        hintText: '3600 = 1小时',
        keyboardType: TextInputType.number,
        initialValue: '3600',
      ),
    ];
  }

  @override
  List<DnsRecordField> getEditRecordFields(Map<String, dynamic> recordData) {
    return [
      DnsRecordField(
        key: 'host',
        label: '主机记录',
        hintText: '例如: www 或 @',
        initialValue: recordData['host']?.toString() ?? '',
      ),
      DnsRecordField(
        key: 'record',
        label: '记录值',
        hintText: '例如: 192.168.1.1',
        initialValue: recordData['record']?.toString() ?? recordData['content']?.toString() ?? '',
      ),
      DnsRecordField(
        key: 'ttl',
        label: 'TTL (秒)',
        hintText: '3600 = 1小时',
        keyboardType: TextInputType.number,
        initialValue: (recordData['ttl'] ?? 3600).toString(),
      ),
    ];
  }

  @override
  Map<String, dynamic> prepareRecordData({
    required Map<String, String> fieldValues,
    required String recordType,
    bool isEdit = false,
  }) {
    final data = <String, dynamic>{
      'type': recordType,
      'host': fieldValues['host'] ?? '',
      'record': fieldValues['record'] ?? '',
      'ttl': int.tryParse(fieldValues['ttl'] ?? '3600') ?? 3600,
    };

    if (recordType == 'MX' || recordType == 'SRV') {
      data['priority'] = int.tryParse(fieldValues['priority'] ?? '10') ?? 10;
    }

    return data;
  }
}