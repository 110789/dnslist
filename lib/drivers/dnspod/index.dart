export 'core.dart';
export 'signer.dart';
export 'parser.dart';
export 'zone.dart';
export 'dns.dart';

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../interfaces/driver_interface.dart';
import '../../utils/driver/driver_utils.dart';
import 'core.dart';
import 'signer.dart';
import 'parser.dart';
import 'zone.dart';
import 'dns.dart';

class DnspodDriver implements DriverInterface {
  Dio? _client;
  String? _secretId;
  String? _secretKey;
  DnspodZone? _zone;
  DnspodDns? _dns;

  @override
  String get providerId => DnspodCore.providerId;

  @override
  String get providerName => DnspodCore.providerName;

  @override
  String get providerIcon => DnspodCore.providerIcon;

  @override
  String mapErrorCode(String code) => '';

  @override
  String getAddDomainTitle() => '添加域名';

  @override
  List<AddDomainField> getAddDomainFields() => [
    const AddDomainField(key: 'domain', label: '域名', hintText: '例如: example.com', description: '输入主域名，如 dnspod.cn'),
  ];

  @override
  Map<String, dynamic> prepareDomainData(Map<String, dynamic> input) => {
    'domain': input['domain'] ?? input['name'] ?? '',
  };

  @override
  Future<Map<String, dynamic>> validateCredential(Map<String, String> credentials) async {
    final secretId = credentials['secretId'];
    final secretKey = credentials['secretKey'];
    if (secretId == null || secretId.isEmpty || secretKey == null || secretKey.isEmpty) {
      return {'success': false, 'error': 'SecretId or SecretKey cannot be empty', 'errorCode': 'INVALID_CREDENTIAL'};
    }

    try {
      _secretId = secretId;
      _secretKey = secretKey;
      _client = DnspodCore.createClient();

      final result = await _callApi('DescribeUserDetail', {});
      if (result['success'] == true) {
        _zone = DnspodZone(_client!, _secretId!, _secretKey!);
        _dns = DnspodDns(_client!, _secretId!, _secretKey!);
        return {'success': true};
      }

      _resetClient();
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    } catch (e) {
      _resetClient();
      final result = DnspodParser.parseException(e, e is DioException ? e : null);
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    }
  }

  Future<Map<String, dynamic>> _callApi(String action, Map<String, dynamic> params) async {
    if (_secretId == null || _secretKey == null) {
      return {'success': false, 'error': 'Not initialized', 'errorCode': 'AUTH_REQUIRED'};
    }

    final headers = buildDnspodHeaders(
      secretId: _secretId!,
      secretKey: _secretKey!,
      action: action,
      payload: params,
    );
    _client!.options.headers.addAll(headers);

    try {
      final response = await _client!.post('', data: params);
      if (response.data == null) {
        return {'success': false, 'error': 'Empty response', 'errorCode': 'EMPTY_RESPONSE'};
      }

      final respData = response.data;
      if (respData is! Map) {
        try {
          final parsed = respData is String ? _tryParseJson(respData.toString()) : respData;
          if (parsed is Map) {
            final parsedResult = DnspodParser.parseResponse(parsed);
            if (parsedResult['success'] == true) {
              return parsedResult;
            }
            return {'success': false, 'error': parsedResult['error'], 'errorCode': parsedResult['errorCode']};
          }
        } catch (_) {}
        return {'success': false, 'error': 'Invalid response', 'errorCode': 'PARSE_ERROR'};
      }

      final result = DnspodParser.parseResponse(respData);
      if (result['success'] == true) {
        return result;
      }
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    } on DioException catch (e) {
      final result = DnspodParser.parseException(e, e);
      return {'success': false, 'error': result['error'], 'errorCode': result['errorCode']};
    } catch (e) {
      return {'success': false, 'error': 'Operation failed', 'errorCode': 'UNKNOWN'};
    }
  }

  dynamic _tryParseJson(String jsonStr) {
    try {
      return jsonDecode(jsonStr);
    } catch (_) {
      return null;
    }
  }

  void _resetClient() {
    _secretId = null;
    _secretKey = null;
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
      return {'domains': [], 'pagination': {}, 'error': 'Not initialized', 'errorCode': 'AUTH_REQUIRED', 'success': false};
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
      return {'records': [], 'pagination': {}, 'error': 'Not initialized', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    return _dns!.getRecords(domainId, page: page, pageSize: pageSize, filters: filters);
  }

  @override
  Future<Map<String, dynamic>> createDnsRecord(
    String domainId,
    Map<String, dynamic> recordData,
  ) async {
    if (_dns == null) {
      return {'error': 'Not initialized', 'errorCode': 'AUTH_REQUIRED', 'success': false};
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
      return {'error': 'Not initialized', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    return _dns!.updateRecord(domainId, recordId, recordData);
  }

  @override
  Future<Map<String, dynamic>> deleteDnsRecord(String domainId, String recordId) async {
    if (_dns == null) {
      return {'success': false, 'error': 'Not initialized', 'errorCode': 'AUTH_REQUIRED'};
    }
    return _dns!.deleteRecord(domainId, recordId);
  }

  @override
  Future<Map<String, dynamic>> createDomain(Map<String, dynamic> domainData) async {
    if (_zone == null) {
      return {'error': 'Not initialized', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    return _zone!.create(domainData);
  }

  @override
  Future<Map<String, dynamic>> deleteDomain(String domainId) async {
    if (_zone == null) {
      return {'error': 'Not initialized', 'errorCode': 'AUTH_REQUIRED', 'success': false};
    }
    return _zone!.delete(domainId);
  }

  @override
  Future<Map<String, dynamic>> renewDomain(String domainId) async {
    if (_zone == null) {
      return {'error': 'Not initialized', 'errorCode': 'AUTH_REQUIRED', 'success': false};
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
    final name = recordData['name']?.toString() ?? recordData['sub_domain']?.toString() ?? '';
    final type = recordData['type']?.toString() ?? recordData['record_type']?.toString() ?? 'A';
    final content = recordData['content']?.toString() ?? recordData['value']?.toString() ?? '';
    final ttl = recordData['ttl'] as int? ?? 600;
    final priority = recordData['priority'] ?? recordData['mx'];
    final enabled = recordData['enabled'] == true || recordData['status']?.toString()?.toLowerCase() == 'active';
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
                    if (priority != null && priority > 0) ...[
                      const SizedBox(width: 4),
                      DriverUiTokens.buildPriorityTag(priority as int),
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
  Map<String, String> getCredentialFields() => {'secretId': 'SecretId', 'secretKey': 'SecretKey'};

  @override
  List<String> getSupportedRecordTypes() => ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'NS', 'SRV', 'CAA', 'URL', 'SPF'];
}