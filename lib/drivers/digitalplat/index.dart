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

class DigitalplatDriver implements DriverInterface {
  Dio? _client;
  // ignore: unused_field
  String? _apiToken;
  DigitalplatZone? _zone;
  // ignore: unused_field
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
      case 'AUTHENTICATION_FAILED':
        return '无效的 API 密钥';
      case 'rate_limit_exceeded':
        return '请求过于频繁';
      case 'TIMEOUT':
        return '连接超时';
      case 'NETWORK_ERROR':
        return '网络连接失败';
      case 'FORBIDDEN':
        return '访问被拒绝';
      case 'NOT_FOUND':
        return '接口不存在';
      case 'SERVER_ERROR':
        return '服务器错误';
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

      final response = await _client!.get('/domains');
      
      if (response.statusCode == 401) {
        _resetClient();
        return {'success': false, 'error': 'Invalid API Token', 'errorCode': 'AUTHENTICATION_FAILED'};
      }

      if (response.data == null) {
        _resetClient();
        return {'success': false, 'error': 'Empty response from server', 'errorCode': 'EMPTY_RESPONSE'};
      }

      final result = DigitalplatParser.parseResponse(response.data);
      if (result['success'] == true) {
        _zone = DigitalplatZone(_client!);
        _dns = DigitalplatDns(_client!);
        return {'success': true, 'errorCode': 'OK'};
      }

      _resetClient();
      final errorMsg = result['error']?.toString() ?? 'Unknown error';
      final errorCode = result['errorCode']?.toString() ?? 'UNKNOWN';
      return {'success': false, 'error': errorMsg, 'errorCode': errorCode};
    } on DioException catch (e) {
      _resetClient();
      return _handleDioError(e);
    } catch (e) {
      _resetClient();
      return {'success': false, 'error': e.toString(), 'errorCode': 'EXCEPTION'};
    }
  }

  Map<String, dynamic> _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return {'success': false, 'error': 'Connection timeout', 'errorCode': 'TIMEOUT'};
      case DioExceptionType.connectionError:
        return {'success': false, 'error': 'Connection failed. Please check network.', 'errorCode': 'NETWORK_ERROR'};
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return {'success': false, 'error': 'Invalid API Token', 'errorCode': 'AUTHENTICATION_FAILED'};
        } else if (statusCode == 403) {
          return {'success': false, 'error': 'Access forbidden', 'errorCode': 'FORBIDDEN'};
        } else if (statusCode == 404) {
          return {'success': false, 'error': 'API endpoint not found', 'errorCode': 'NOT_FOUND'};
        } else if (statusCode != null && statusCode >= 500) {
          return {'success': false, 'error': 'Server error', 'errorCode': 'SERVER_ERROR'};
        }
        return {'success': false, 'error': 'Request failed', 'errorCode': 'BAD_RESPONSE'};
      case DioExceptionType.cancel:
        return {'success': false, 'error': 'Request cancelled', 'errorCode': 'CANCELLED'};
      default:
        return {'success': false, 'error': e.message ?? 'Unknown error', 'errorCode': 'UNKNOWN'};
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
    return {
      'records': [],
      'pagination': {},
      'error': 'DigitalPlat 不支持 DNS 记录管理',
      'errorCode': 'NOT_SUPPORTED',
      'success': false,
    };
  }

  @override
  Future<Map<String, dynamic>> createDnsRecord(
    String domainId,
    Map<String, dynamic> recordData,
  ) async {
    return {'error': 'DigitalPlat 不支持 DNS 记录管理', 'errorCode': 'NOT_SUPPORTED', 'success': false};
  }

  @override
  Future<Map<String, dynamic>> updateDnsRecord(
    String domainId,
    String recordId,
    Map<String, dynamic> recordData,
  ) async {
    return {'error': 'DigitalPlat 不支持 DNS 记录管理', 'errorCode': 'NOT_SUPPORTED', 'success': false};
  }

  @override
  Future<Map<String, dynamic>> deleteDnsRecord(String domainId, String recordId) async {
    return {'success': false, 'error': 'DigitalPlat 不支持 DNS 记录管理', 'errorCode': 'NOT_SUPPORTED'};
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
  }) {
    final nameservers = domainData['nameservers'] as List? ?? [];
    final nameserversStr = nameservers.isNotEmpty 
        ? nameservers.join(', ') 
        : '无';

    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DriverUiTokens.horizontalPadding,
          vertical: DriverUiTokens.verticalPadding,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    domainData['domain']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'DNS: ',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Expanded(
                        child: Text(
                          nameserversStr,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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