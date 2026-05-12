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

class DnsheDriver implements DriverInterface {
  Dio? _client;
  String? _apiKey;
  String? _apiSecret;
  DnsheZone? _zone;
  DnsheDns? _dns;

  @override
  String get providerId => DnsheCore.providerId;

  @override
  String get providerName => DnsheCore.providerName;

  @override
  String get providerIcon => DnsheCore.providerIcon;

  @override
  String mapErrorCode(String code) => '';

  @override
  String getAddDomainTitle() => '添加子域名';

  @override
  List<AddDomainField> getAddDomainFields() => [
    const AddDomainField(key: 'subdomain', label: '子域名前缀', hintText: '例如: myapp'),
    const AddDomainField(key: 'rootdomain', label: '根域名', hintText: '例如: example.com', description: '将创建: {子域名}.{根域名}'),
  ];

  @override
  Map<String, dynamic> prepareDomainData(Map<String, dynamic> input) => {
    'subdomain': input['subdomain'] ?? '',
    'rootdomain': input['rootdomain'] ?? '',
  };

  @override
  Future<Map<String, dynamic>> validateCredential(Map<String, String> credentials) async {
    final apiKey = credentials['apiKey'];
    final apiSecret = credentials['apiSecret'];
    if (apiKey == null || apiKey.isEmpty || apiSecret == null || apiSecret.isEmpty) {
      return {'success': false, 'error': 'API Key or API Secret cannot be empty', 'errorCode': 'INVALID_CREDENTIAL'};
    }

    try {
      _apiKey = apiKey;
      _apiSecret = apiSecret;
      _client = DnsheCore.createClient(apiKey, apiSecret);

      final response = await _client!.get('', queryParameters: {'m': 'domain_hub', 'endpoint': 'quota'});

      if (response.data == null) {
        _resetClient();
        return {'success': false, 'error': 'Empty response from server', 'errorCode': 'EMPTY_RESPONSE'};
      }

      final result = DnsheParser.parseResponse(response.data);
      if (result['success'] == true) {
        _zone = DnsheZone(_client!);
        _dns = DnsheDns(_client!);
        return {'success': true};
      }

      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    } catch (e) {
      final result = DnsheParser.parseException(e, e is DioException ? e : null);
      _resetClient();
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    }
  }

  void _resetClient() {
    _apiKey = null;
    _apiSecret = null;
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
      return {'subdomains': [], 'domains': [], 'pagination': {}, 'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }
    return _zone!.getList(page: page, pageSize: pageSize, filters: filters);
  }

  @override
  Future<Map<String, dynamic>> getDnsRecords(
    String domainId, {
    int page = 1,
    int pageSize = 20,
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
  bool get supportsRenewDomain => true;

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
    final name = recordData['name']?.toString() ?? '';
    final type = recordData['type']?.toString() ?? 'A';
    final content = recordData['content']?.toString() ?? '';
    final ttl = recordData['ttl'] as int? ?? 3600;
    final proxied = recordData['proxied'] == true;
    final priority = recordData['priority'];
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
                    Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (priority != null) ...[
                      const SizedBox(width: 4),
                      DriverUiTokens.buildPriorityTag(priority as int),
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
          if (proxied) ...[
            const SizedBox(width: 4),
            DriverUiTokens.buildProxiedIcon(),
          ],
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
        if (supportsRenew) const PopupMenuItem(value: 'renew', child: Text('续期')),
        if (supportsDelete) const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Color(0xFFEF4444)))),
      ],
    ).then((value) {
      if (value == 'delete') onDelete();
      if (value == 'renew') onRenew();
    });
  }

  @override
  Map<String, String> getCredentialFields() => {'apiKey': 'API Key', 'apiSecret': 'API Secret'};

  @override
  List<String> getSupportedRecordTypes() => ['A', 'AAAA', 'CNAME', 'MX', 'TXT'];

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
        key: 'name',
        label: '记录名称',
        hintText: '例如: www 或 @',
      ),
      const DnsRecordField(
        key: 'content',
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
        key: 'name',
        label: '记录名称',
        hintText: '例如: www 或 @',
        initialValue: recordData['name']?.toString() ?? '',
      ),
      DnsRecordField(
        key: 'content',
        label: '记录值',
        hintText: '例如: 192.168.1.1',
        initialValue: recordData['content']?.toString() ?? '',
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
      'name': fieldValues['name'] ?? '',
      'content': fieldValues['content'] ?? '',
      'ttl': int.tryParse(fieldValues['ttl'] ?? '3600') ?? 3600,
    };

    if (recordType == 'MX' || recordType == 'SRV') {
      data['priority'] = int.tryParse(fieldValues['priority'] ?? '10') ?? 10;
    }

    return data;
  }
}