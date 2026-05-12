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
  // ignore: unused_field
  String? _apiKey;
  // ignore: unused_field
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
      final result = DnsheParser.parseException(e is DioException ? e : DioException(requestOptions: RequestOptions(path: '')));
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
    int pageSize = 100,
    Map<String, String>? filters,
  }) async {
    if (_dns == null) {
      return {'records': [], 'pagination': {}, 'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }
    final subdomainId = int.tryParse(domainId) ?? 0;
    return _dns!.getRecords(subdomainId: subdomainId, page: page, pageSize: pageSize);
  }

  @override
  Future<Map<String, dynamic>> createDnsRecord(
    String domainId,
    Map<String, dynamic> recordData,
  ) async {
    if (_dns == null) {
      return {'error': '', 'errorCode': 'NOT_INITIALIZED', 'success': false};
    }
    final subdomainId = int.tryParse(domainId) ?? 0;
    final dataWithSubdomainId = Map<String, dynamic>.from(recordData);
    dataWithSubdomainId['subdomain_id'] = subdomainId;
    return _dns!.createRecord(dataWithSubdomainId);
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
    final dataWithId = Map<String, dynamic>.from(recordData);
    final recordIdInt = int.tryParse(recordId);
    if (recordIdInt != null) {
      dataWithId['id'] = recordIdInt;
    } else {
      dataWithId['record_id'] = recordId;
    }
    return _dns!.updateRecord(dataWithId);
  }

  @override
  Future<Map<String, dynamic>> deleteDnsRecord(String domainId, String recordId) async {
    if (_dns == null) {
      return {'success': false, 'error': '', 'errorCode': 'NOT_INITIALIZED'};
    }
    final data = <String, dynamic>{};
    final recordIdInt = int.tryParse(recordId);
    if (recordIdInt != null) {
      data['id'] = recordIdInt;
    } else {
      data['record_id'] = recordId;
    }
    return _dns!.deleteRecord(data);
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
    final ttl = recordData['ttl'] as int? ?? 600;
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
                    Flexible(child: Text(name.isEmpty ? '@' : name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
  List<String> getSupportedRecordTypes() => ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'SRV', 'NS', 'CAA'];

  @override
  String getAddRecordTitle() => '添加DNS记录';

  @override
  String getEditRecordTitle() => '编辑DNS记录';

  @override
  bool supportsRecordLine() => false;

  @override
  List<DnsRecordField> getEditRecordFields(Map<String, dynamic> recordData) {
    final recordType = recordData['type']?.toString() ?? 'A';
    return getEditRecordFieldsForType(recordData, recordType);
  }

  @override
  List<DnsRecordField> getAddRecordFields() {
    return getAddRecordFieldsForType('A');
  }

  List<DnsRecordField> getAddRecordFieldsForType(String recordType) {
    final fields = <DnsRecordField>[
      const DnsRecordField(
        key: 'name',
        label: '记录名称',
        hintText: '例如: www 或留空',
      ),
      DnsRecordField(
        key: 'content',
        label: '记录值',
        hintText: _getContentHintForType(recordType),
      ),
      const DnsRecordField(
        key: 'ttl',
        label: 'TTL (秒)',
        hintText: '600 = 10分钟 (默认600)',
        keyboardType: TextInputType.number,
        initialValue: '600',
      ),
    ];

    if (recordType == 'MX' || recordType == 'SRV') {
      fields.insert(2, const DnsRecordField(
        key: 'priority',
        label: '优先级',
        hintText: '数值越小优先级越高',
        keyboardType: TextInputType.number,
        initialValue: '10',
      ));
    }

    if (recordType == 'SRV') {
      fields.insert(3, const DnsRecordField(
        key: 'port',
        label: '端口',
        hintText: '例如: 443',
        keyboardType: TextInputType.number,
        initialValue: '443',
      ));
      fields.insert(4, const DnsRecordField(
        key: 'weight',
        label: '权重',
        hintText: '负载均衡权重',
        keyboardType: TextInputType.number,
        initialValue: '1',
      ));
    }

    return fields;
  }

  List<DnsRecordField> getEditRecordFieldsForType(Map<String, dynamic> recordData, String recordType) {
    final fields = <DnsRecordField>[
      DnsRecordField(
        key: 'name',
        label: '记录名称',
        hintText: '例如: www 或留空',
        initialValue: recordData['name']?.toString() ?? '',
      ),
      DnsRecordField(
        key: 'content',
        label: '记录值',
        hintText: _getContentHintForType(recordType),
        initialValue: recordData['content']?.toString() ?? '',
      ),
      DnsRecordField(
        key: 'ttl',
        label: 'TTL (秒)',
        hintText: '600 = 10分钟 (默认600)',
        keyboardType: TextInputType.number,
        initialValue: (recordData['ttl'] ?? 600).toString(),
      ),
    ];

    if (recordType == 'MX' || recordType == 'SRV') {
      fields.insert(2, DnsRecordField(
        key: 'priority',
        label: '优先级',
        hintText: '数值越小优先级越高',
        keyboardType: TextInputType.number,
        initialValue: (recordData['priority'] ?? 10).toString(),
      ));
    }

    if (recordType == 'SRV') {
      fields.insert(3, DnsRecordField(
        key: 'port',
        label: '端口',
        hintText: '例如: 443',
        keyboardType: TextInputType.number,
        initialValue: (recordData['port'] ?? 443).toString(),
      ));
      fields.insert(4, DnsRecordField(
        key: 'weight',
        label: '权重',
        hintText: '负载均衡权重',
        keyboardType: TextInputType.number,
        initialValue: (recordData['weight'] ?? 1).toString(),
      ));
    }

    return fields;
  }

  String _getContentHintForType(String recordType) {
    switch (recordType) {
      case 'A':
        return '例如: 192.168.1.1';
      case 'AAAA':
        return '例如: 2001:0db8:85a3::8a2e:0370:7334';
      case 'CNAME':
        return '例如: example.com';
      case 'MX':
        return '例如: mail.example.com';
      case 'TXT':
        return '例如: v=spf1 include:_spf.example.com ~all';
      case 'SRV':
        return '例如: target.example.com';
      case 'NS':
        return '例如: ns1.example.com';
      case 'CAA':
        return '例如: 0 issue letsencrypt.org';
      default:
        return '记录值';
    }
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
      'ttl': int.tryParse(fieldValues['ttl'] ?? '600') ?? 600,
    };

    if (recordType == 'MX' || recordType == 'SRV') {
      data['priority'] = int.tryParse(fieldValues['priority'] ?? '10') ?? 10;
    }

    if (recordType == 'SRV') {
      final port = int.tryParse(fieldValues['port'] ?? '443') ?? 443;
      final weight = int.tryParse(fieldValues['weight'] ?? '1') ?? 1;
      data['port'] = port;
      data['weight'] = weight;
      if (data['content'] != null && data['content'].toString().isNotEmpty) {
        data['content'] = '${port} ${weight} 0 ${data['content']}';
      }
    }

    return data;
  }

  Map<String, dynamic> prepareRecordDataForSubmit({
    required Map<String, String> fieldValues,
    required String recordType,
  }) {
    final data = <String, dynamic>{
      'type': recordType,
      'name': fieldValues['name'] ?? '',
      'content': fieldValues['content'] ?? '',
      'ttl': int.tryParse(fieldValues['ttl'] ?? '600') ?? 600,
    };

    if (recordType == 'MX' || recordType == 'SRV') {
      data['priority'] = int.tryParse(fieldValues['priority'] ?? '10') ?? 10;
    }

    if (recordType == 'SRV') {
      final port = int.tryParse(fieldValues['port'] ?? '443') ?? 443;
      final weight = int.tryParse(fieldValues['weight'] ?? '1') ?? 1;
      data['port'] = port;
      data['weight'] = weight;
      if (data['content'] != null && data['content'].toString().isNotEmpty) {
        data['content'] = '${port} ${weight} 0 ${data['content']}';
      }
    }

    return data;
  }

  void showAddRecordDialog(
    BuildContext context, {
    required String domainId,
    required Future<Map<String, dynamic>> Function(Map<String, dynamic> recordData) onSubmit,
  }) {
    String selectedType = 'A';
    final fieldControllers = <String, TextEditingController>{};
    final fieldValues = <String, String>{};
    bool isSubmitting = false;
    bool hasError = false;
    String? errorMessage;

    void initControllers(List<DnsRecordField> fields) {
      fieldControllers.clear();
      fieldValues.clear();
      for (final field in fields) {
        fieldControllers[field.key] = TextEditingController(text: field.initialValue ?? '');
        fieldValues[field.key] = field.initialValue ?? '';
      }
    }

    initControllers(getAddRecordFieldsForType(selectedType));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final fields = getAddRecordFieldsForType(selectedType);
          final colorScheme = Theme.of(dialogContext).colorScheme;

          return AlertDialog(
            title: Text(getAddRecordTitle()),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: '记录类型'),
                    items: getSupportedRecordTypes().map((t) =>
                      DropdownMenuItem(value: t, child: Text(t))
                    ).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        initControllers(getAddRecordFieldsForType(v));
                        setDialogState(() => selectedType = v);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ...fields.map((field) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: fieldControllers[field.key],
                        decoration: InputDecoration(
                          labelText: field.label,
                          hintText: field.hintText,
                        ),
                        keyboardType: field.keyboardType,
                        onChanged: (v) => fieldValues[field.key] = v,
                      ),
                    );
                  }),
                  if (hasError && errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: colorScheme.error, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: isSubmitting ? null : () async {
                  final content = fieldValues['content'] ?? '';
                  if (content.isEmpty) {
                    setDialogState(() {
                      hasError = true;
                      errorMessage = '记录值不能为空';
                    });
                    return;
                  }

                  setDialogState(() {
                    isSubmitting = true;
                    hasError = false;
                    errorMessage = null;
                  });

                  final recordData = prepareRecordDataForSubmit(
                    fieldValues: fieldValues,
                    recordType: selectedType,
                  );

                  final result = await onSubmit(recordData);

                  if (dialogContext.mounted) {
                    if (result['success'] == true) {
                      Navigator.pop(dialogContext);
                    } else {
                      setDialogState(() {
                        isSubmitting = false;
                        hasError = true;
                        errorMessage = result['error']?.toString() ?? '添加失败';
                      });
                    }
                  }
                },
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('添加'),
              ),
            ],
          );
        },
      ),
    );
  }

void showEditRecordDialog(
    BuildContext context,
    Map<String, dynamic> record, {
    required Future<Map<String, dynamic>> Function(Map<String, dynamic> recordData) onSubmit,
  }) {
    String selectedType = record['type']?.toString() ?? 'A';
    final fieldControllers = <String, TextEditingController>{};
    final fieldValues = <String, String>{};
    bool isSubmitting = false;
    bool hasError = false;
    String? errorMessage;

    void initControllers(List<DnsRecordField> fields) {
      fieldControllers.clear();
      fieldValues.clear();
      for (final field in fields) {
        fieldControllers[field.key] = TextEditingController(text: field.initialValue ?? '');
        fieldValues[field.key] = field.initialValue ?? '';
      }
    }

    initControllers(getEditRecordFieldsForType(record, selectedType));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final fields = getEditRecordFieldsForType(record, selectedType);
          final colorScheme = Theme.of(dialogContext).colorScheme;

          return AlertDialog(
            title: Text(getEditRecordTitle()),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: '记录类型'),
                    items: getSupportedRecordTypes().map((t) =>
                      DropdownMenuItem(value: t, child: Text(t))
                    ).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        initControllers(getEditRecordFieldsForType(record, v));
                        setDialogState(() => selectedType = v);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ...fields.where((f) => f.key != 'line').map((field) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: fieldControllers[field.key],
                        decoration: InputDecoration(
                          labelText: field.label,
                          hintText: field.hintText,
                        ),
                        keyboardType: field.keyboardType,
                        onChanged: (v) => fieldValues[field.key] = v,
                      ),
                    );
                  }),
                  if (hasError && errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: colorScheme.error, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: isSubmitting ? null : () async {
                  final content = fieldValues['content'] ?? '';
                  if (content.isEmpty) {
                    setDialogState(() {
                      hasError = true;
                      errorMessage = '记录值不能为空';
                    });
                    return;
                  }

                  setDialogState(() {
                    isSubmitting = true;
                    hasError = false;
                    errorMessage = null;
                  });

                  final recordData = prepareRecordDataForSubmit(
                    fieldValues: fieldValues,
                    recordType: selectedType,
                  );

                  final result = await onSubmit(recordData);

                  if (dialogContext.mounted) {
                    if (result['success'] == true) {
                      Navigator.pop(dialogContext);
                    } else {
                      setDialogState(() {
                        isSubmitting = false;
                        hasError = true;
                        errorMessage = result['error']?.toString() ?? '保存失败';
                      });
                    }
                  }
                },
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('保存'),
              ),
            ],
          );
        },
      ),
);
  }

  void showDeleteConfirmDialog(
    BuildContext context,
    Map<String, dynamic> record, {
    required Future<Map<String, dynamic>> Function() onConfirm,
  }) {
    final name = record['name']?.toString() ?? '';
    bool isDeleting = false;
    bool hasError = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final colorScheme = Theme.of(dialogContext).colorScheme;

          return AlertDialog(
            title: const Text('删除记录'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('确定要删除 "$name" 吗？此操作无法撤销。'),
                if (hasError && errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: TextStyle(color: colorScheme.error, fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('取消'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
                onPressed: isDeleting ? null : () async {
                  setDialogState(() {
                    isDeleting = true;
                    hasError = false;
                    errorMessage = null;
                  });

                  final result = await onConfirm();

                  if (dialogContext.mounted) {
                    if (result['success'] == true) {
                      Navigator.pop(dialogContext);
                    } else {
                      setDialogState(() {
                        isDeleting = false;
                        hasError = true;
                        errorMessage = result['error']?.toString() ?? '删除失败';
                      });
                    }
                  }
                },
                child: isDeleting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('删除'),
              ),
            ],
          );
        },
      ),
    );
  }
}