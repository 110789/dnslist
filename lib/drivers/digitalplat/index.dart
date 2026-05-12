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

class DigitalplatDriver implements DriverInterface {
  Dio? _client;
  String? _apiToken;
  DigitalplatZone? _zone;
  DigitalplatDns? _dns;

  @override
  String get providerId => DigitalplatCore.providerId;

  @override
  String get providerName => DigitalplatCore.providerName;

  @override
  String get providerIcon => DigitalplatCore.providerIcon;

  @override
  String mapErrorCode(String code) {
    switch (code) {
      case 'domain_taken':
        return '域名已被占用';
      case 'invalid_slot_type':
        return '无效的 slot_type 值';
      case 'nameserver_required':
        return '需要提供名称服务器';
      case 'invalid_domain':
        return '无效的域名格式';
      case 'authentication_failed':
        return '无效的 API 密钥';
      case 'rate_limit_exceeded':
        return '请求过于频繁';
      default:
        return code;
    }
  }

  @override
  String getAddDomainTitle() => '注册域名';

  @override
  List<AddDomainField> getAddDomainFields() => [
    const AddDomainField(
      key: 'domain',
      label: '域名',
      hintText: '例如: example.us.kg',
      description: '输入要注册的域名',
    ),
    const AddDomainField(
      key: 'slot_type',
      label: '类型',
      hintText: 'free',
      description: '类型: free, paid, subscription',
    ),
  ];

  @override
  Map<String, dynamic> prepareDomainData(Map<String, dynamic> input) => {
    'domain': input['domain'] ?? input['name'] ?? '',
    'slot_type': input['slot_type'] ?? 'free',
    'nameservers': input['nameservers'] ?? [],
  };

  @override
  Future<Map<String, dynamic>> validateCredential(Map<String, String> credentials) async {
    final apiToken = credentials['apiToken'];
    if (apiToken == null || apiToken.isEmpty) {
      return {'success': false, 'error': 'API Token cannot be empty', 'errorCode': 'EMPTY_TOKEN'};
    }

    try {
      _apiToken = apiToken;
      _client = DigitalplatCore.createClient(apiToken);

      final response = await _client!.get('/me');
      if (response.data == null) {
        _resetClient();
        return {'success': false, 'error': 'Empty response from server', 'errorCode': 'EMPTY_RESPONSE'};
      }

      final result = DigitalplatParser.parseResponse(response.data);
      if (result['success'] == true) {
        _zone = DigitalplatZone(_client!);
        _dns = DigitalplatDns(_client!);
        return {'success': true};
      }

      _resetClient();
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    } catch (e) {
      final result = DigitalplatParser.parseException(e, e is DioException ? e : null);
      _resetClient();
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    }
  }

  void _resetClient() {
    _apiToken = null;
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
      return {'domains': [], 'pagination': {}, 'error': 'Not initialized', 'errorCode': 'NOT_INITIALIZED', 'success': false};
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
      return {'records': [], 'pagination': {}, 'error': 'Not initialized', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }
    return _dns!.getRecords(domainId, page: page, pageSize: pageSize, filters: filters);
  }

  @override
  Future<Map<String, dynamic>> createDnsRecord(
    String domainId,
    Map<String, dynamic> recordData,
  ) async {
    if (_dns == null) {
      return {'error': 'Not initialized', 'errorCode': 'NOT_INITIALIZED', 'success': false};
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
      return {'error': 'Not initialized', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }
    return _dns!.updateRecord(domainId, recordId, recordData);
  }

  @override
  Future<Map<String, dynamic>> deleteDnsRecord(String domainId, String recordId) async {
    if (_dns == null) {
      return {'success': false, 'error': 'Not initialized', 'errorCode': 'NOT_INITIALIZED'};
    }
    return _dns!.deleteRecord(domainId, recordId);
  }

  @override
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData) async {
    if (_zone == null) {
      return {'error': 'Not initialized', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }
    return _zone!.create(domainData);
  }

  @override
  Future<Map<String, dynamic>> deleteDomain(String domainId) async {
    if (_zone == null) {
      return {'error': 'Not initialized', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }
    return _zone!.delete(domainId);
  }

  @override
  Future<Map<String, dynamic>> renewDomain(String domainId) async {
    if (_zone == null) {
      return {'error': 'Not initialized', 'errorCode': 'NOT_INITIALIZED', 'success': false};
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
  bool get supportsShowNameServers => true;

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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DriverUiTokens.horizontalPadding,
        vertical: DriverUiTokens.verticalPadding,
      ),
      child: Row(
        children: [
          DriverUiTokens.buildDnsTypeAvatar('N', const Color(0xFF64748B)),
          const SizedBox(width: DriverUiTokens.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'DigitalPlat 不支持 DNS 记录管理',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ],
            ),
          ),
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
        if (supportsShowNameServers) const PopupMenuItem(value: 'nameservers', child: Text('NS节点')),
        if (supportsDelete) const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Color(0xFFEF4444)))),
      ],
    ).then((value) {
      if (value == 'delete') onDelete();
      if (value == 'nameservers') onShowNameServers();
    });
  }

  @override
  Map<String, String> getCredentialFields() => {'apiToken': 'API Token'};

  @override
  List<String> getSupportedRecordTypes() => [];

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
        key: 'note',
        label: '提示',
        hintText: 'DigitalPlat 不支持 DNS 记录管理',
      ),
    ];
  }

  @override
  List<DnsRecordField> getEditRecordFields(Map<String, dynamic> recordData) {
    return [
      const DnsRecordField(
        key: 'note',
        label: '提示',
        hintText: 'DigitalPlat 不支持 DNS 记录管理',
      ),
    ];
  }

  @override
  Map<String, dynamic> prepareRecordData({
    required Map<String, String> fieldValues,
    required String recordType,
    bool isEdit = false,
  }) {
    return {
      'error': 'DigitalPlat 不支持 DNS 记录管理',
      'errorCode': 'NOT_SUPPORTED',
    };
  }
}