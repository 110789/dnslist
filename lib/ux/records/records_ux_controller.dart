import 'package:flutter/material.dart';
import '../../core/refresh/refresh_core.dart';
import '../../drivers/driver_factory.dart';
import '../../drivers/interfaces/record_dialog_capability.dart';
import '../../services/credential_state.dart';
import '../../services/new_domain_state.dart';
import '../../utils/toast_util.dart';
import 'records_ux_state.dart';

class RecordsUxController {
  final BuildContext context;
  final RecordsUxState recordsState;
  final CredentialState credentialState;
  final NewDomainState domainStateService;
  final String domainId;
  final String domainName;

  RecordsUxController({
    required this.context,
    required this.recordsState,
    required this.credentialState,
    required this.domainStateService,
    required this.domainId,
    required this.domainName,
  });

  String? get _providerId => credentialState.selectedCredential?.providerId;
  Map<String, String> get _credentials => credentialState.selectedCredential?.credentials ?? {};

  Future<void> initialize() async {
    recordsState.setLoading(true);
    await _refreshRecordList();
  }

  Future<void> refreshManual() async {
    final providerId = _providerId;
    if (providerId == null) return;

    recordsState.setRefreshing(true);
    final result = await domainStateService.refreshDnsRecordList(
      providerId: providerId,
      domainId: domainId,
      credentials: _credentials,
      triggerType: RefreshTriggerType.manual,
    );

    _handleRefreshResult(result);
  }

  Future<void> refreshPassive() async {
    final providerId = _providerId;
    if (providerId == null) return;

    recordsState.setLoading(true);
    final result = await domainStateService.refreshDnsRecordList(
      providerId: providerId,
      domainId: domainId,
      credentials: _credentials,
      triggerType: RefreshTriggerType.passive,
    );

    _handleRefreshResult(result);
  }

  Future<void> _refreshRecordList() async {
    final providerId = _providerId;
    if (providerId == null) {
      recordsState.setLoading(false);
      return;
    }

    final result = await domainStateService.refreshDnsRecordList(
      providerId: providerId,
      domainId: domainId,
      credentials: _credentials,
      triggerType: RefreshTriggerType.passive,
    );

    _handleRefreshResult(result);
  }

  void _handleRefreshResult(dynamic result) {
    if (result.success) {
      final records = (result.data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      recordsState.setRecords(records.cast<Map<String, dynamic>>());
      recordsState.clearError();
    } else {
      recordsState.setError(result.error, result.errorCode);
    }
    recordsState.setLoading(false);
    recordsState.setRefreshing(false);
  }

  void showAddRecordDialog() {
    final providerId = _providerId;
    if (providerId == null) return;

    final driver = DriverFactory.get(providerId);
    if (driver == null) return;

    if (driver is RecordDialogCapability) {
      (driver as RecordDialogCapability).showAddRecordDialog(
        context,
        onSubmit: (recordData) async {
          final result = await domainStateService.createDnsRecord(
            providerId,
            domainId,
            recordData,
            _credentials,
          );
          if (result['success'] == true && context.mounted) {
            ToastUtil.showSuccess(context, _getLocalizedString('record_added'));
          }
          return result;
        },
      );
      return;
    }

    String selectedType = driver.getSupportedRecordTypes().first;
    final fieldControllers = <String, TextEditingController>{};
    final fieldValues = <String, String>{};
    bool proxied = false;
    String? priorityValue;
    bool isSubmitting = false;
    bool hasError = false;

    void initControllers() {
      for (final field in driver.getAddRecordFields()) {
        fieldControllers[field.key] = TextEditingController(text: field.initialValue ?? '');
        fieldValues[field.key] = field.initialValue ?? '';
      }
    }

    initControllers();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final fields = driver.getAddRecordFields();

          return AlertDialog(
            title: Text(driver.getAddRecordTitle()),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(labelText: _getLocalizedString('record_type')),
                    items: driver.getSupportedRecordTypes().map((t) =>
                      DropdownMenuItem(value: t, child: Text(t))
                    ).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedType = v);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ...fields.map((field) => Padding(
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
                  )),
                  if (selectedType == 'MX' || selectedType == 'SRV') ...[
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        labelText: selectedType == 'MX' ? _getLocalizedString('priority') : _getLocalizedString('weight'),
                        hintText: _getLocalizedString('priority_hint'),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => priorityValue = v,
                    ),
                  ],
                  if (driver.supportsProxy && (selectedType == 'A' || selectedType == 'AAAA' || selectedType == 'CNAME')) ...[
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_getLocalizedString('proxied')),
                      subtitle: Text(_getLocalizedString('proxied_hint')),
                      value: proxied,
                      onChanged: (v) => setDialogState(() => proxied = v),
                    ),
                  ],
                  if (driver.supportsRecordLine()) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: fieldValues['line'] ?? 'DEFAULT',
                      decoration: InputDecoration(labelText: _getLocalizedString('record_line')),
                      items: _getRecordLineOptions(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => fieldValues['line'] = v);
                        }
                      },
                    ),
                  ],
                  if (hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_getLocalizedString('fill_required'), style: TextStyle(
                        color: Theme.of(dialogContext).colorScheme.error, fontSize: 12,
                      )),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(_getLocalizedString('cancel')),
              ),
              FilledButton(
                onPressed: isSubmitting ? null : () async {
                  bool hasEmpty = false;
                  for (final field in fields) {
                    if (field.required && (fieldValues[field.key]?.isEmpty ?? true)) {
                      hasEmpty = true;
                      break;
                    }
                  }

                  final contentKey = fieldValues.keys.any((k) => k == 'value' || k == 'content' || k == 'record')
                      ? (fieldValues.containsKey('value') ? 'value' : (fieldValues.containsKey('content') ? 'content' : 'record'))
                      : 'content';
                  if (fieldValues[contentKey]?.isEmpty ?? true) {
                    hasEmpty = true;
                  }

                  if (hasEmpty) {
                    setDialogState(() => hasError = true);
                    return;
                  }

                  setDialogState(() { isSubmitting = true; hasError = false; });

                  if (driver.supportsProxy) {
                    fieldValues['proxied'] = proxied.toString();
                  }
                  if (priorityValue != null) {
                    fieldValues['priority'] = priorityValue!;
                  }

                  final recordData = driver.prepareRecordData(
                    fieldValues: fieldValues,
                    recordType: selectedType,
                    isEdit: false,
                  );

                  final result = await domainStateService.createDnsRecord(
                    providerId,
                    domainId,
                    recordData,
                    _credentials,
                  );

                  if (dialogContext.mounted) {
                    if (result['success'] == true) {
                      Navigator.pop(dialogContext);
                      ToastUtil.showSuccess(context, _getLocalizedString('record_added'));
                    } else {
                      setDialogState(() => isSubmitting = false);
                      ToastUtil.showError(
                        context,
                        result['error'] ?? '',
                        errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode'].toString()) : null,
                      );
                    }
                  }
                },
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_getLocalizedString('add')),
              ),
            ],
          );
        },
      ),
    );
  }

  void showEditRecordDialog(Map<String, dynamic> record) {
    final providerId = _providerId;
    if (providerId == null) return;

    final driver = DriverFactory.get(providerId);
    if (driver == null) return;

    if (driver is RecordDialogCapability) {
      (driver as RecordDialogCapability).showEditRecordDialog(
        context,
        record,
        onSubmit: (recordData) async {
          final result = await domainStateService.updateDnsRecord(
            providerId,
            domainId,
            record['id'].toString(),
            recordData,
            _credentials,
          );
          if (result['success'] == true && context.mounted) {
            ToastUtil.showSuccess(context, _getLocalizedString('record_updated'));
          }
          return result;
        },
      );
      return;
    }

    String selectedType = record['type']?.toString() ?? 'A';
    final fieldControllers = <String, TextEditingController>{};
    final fieldValues = <String, String>{};
    bool proxied = record['proxied'] == true;
    bool isSubmitting = false;

    void initControllers() {
      for (final field in driver.getEditRecordFields(record)) {
        fieldControllers[field.key] = TextEditingController(text: field.initialValue ?? '');
        fieldValues[field.key] = field.initialValue ?? '';
      }
    }

    initControllers();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final fields = driver.getEditRecordFields(record);

          return AlertDialog(
            title: Text(driver.getEditRecordTitle()),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(labelText: _getLocalizedString('record_type')),
                    items: driver.getSupportedRecordTypes().map((t) =>
                      DropdownMenuItem(value: t, child: Text(t))
                    ).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedType = v);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ...fields.where((f) => f.key != 'line').map((field) => Padding(
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
                  )),
                  if (selectedType == 'MX' || selectedType == 'SRV') ...[
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        labelText: selectedType == 'MX' ? _getLocalizedString('priority') : _getLocalizedString('weight'),
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                        text: record['priority']?.toString() ?? record['mx']?.toString() ?? '10',
                      ),
                      onChanged: (v) => fieldValues['priority'] = v,
                    ),
                  ],
                  if (driver.supportsProxy && (selectedType == 'A' || selectedType == 'AAAA' || selectedType == 'CNAME')) ...[
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_getLocalizedString('proxied')),
                      subtitle: Text(_getLocalizedString('proxied_hint')),
                      value: proxied,
                      onChanged: (v) => setDialogState(() => proxied = v),
                    ),
                  ],
                  if (driver.supportsRecordLine()) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: fieldValues['line'] ?? record['line']?.toString() ?? 'DEFAULT',
                      decoration: InputDecoration(labelText: _getLocalizedString('record_line')),
                      items: _getRecordLineOptions(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => fieldValues['line'] = v);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(_getLocalizedString('cancel')),
              ),
              FilledButton(
                onPressed: isSubmitting ? null : () async {
                  setDialogState(() => isSubmitting = true);

                  if (driver.supportsProxy) {
                    fieldValues['proxied'] = proxied.toString();
                  }

                  final recordData = driver.prepareRecordData(
                    fieldValues: fieldValues,
                    recordType: selectedType,
                    isEdit: true,
                  );

                  final result = await domainStateService.updateDnsRecord(
                    providerId,
                    domainId,
                    record['id'].toString(),
                    recordData,
                    _credentials,
                  );

                  if (dialogContext.mounted) {
                    if (result['success'] == true) {
                      Navigator.pop(dialogContext);
                      ToastUtil.showSuccess(context, _getLocalizedString('record_updated'));
                    } else {
                      setDialogState(() => isSubmitting = false);
                      ToastUtil.showError(
                        context,
                        result['error'] ?? '',
                        errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode'].toString()) : null,
                      );
                    }
                  }
                },
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_getLocalizedString('save')),
              ),
            ],
          );
        },
      ),
    );
  }

  void showDeleteRecordDialog(Map<String, dynamic> record) {
    final providerId = _providerId;
    if (providerId == null) return;

    final name = record['name']?.toString() ?? '';
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(_getLocalizedString('delete_record_title')),
            content: Text(_getLocalizedString('delete_record_message', name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(_getLocalizedString('cancel')),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  foregroundColor: Theme.of(dialogContext).colorScheme.onError,
                ),
                onPressed: isDeleting ? null : () async {
                  setDialogState(() => isDeleting = true);
                  final result = await domainStateService.deleteDnsRecord(
                    providerId,
                    domainId,
                    record['id'].toString(),
                    _credentials,
                  );
                  if (dialogContext.mounted) {
                    if (result['success'] == true) {
                      Navigator.pop(dialogContext);
                      ToastUtil.showSuccess(context, _getLocalizedString('record_deleted'));
                    } else {
                      setDialogState(() => isDeleting = false);
                      ToastUtil.showError(
                        context,
                        result['error'] ?? '',
                        errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode'].toString()) : null,
                      );
                    }
                  }
                },
                child: isDeleting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_getLocalizedString('delete')),
              ),
            ],
          );
        },
      ),
    );
  }

  List<DropdownMenuItem<String>> _getRecordLineOptions() {
    return const [
      DropdownMenuItem(value: 'DEFAULT', child: Text('默认')),
      DropdownMenuItem(value: 'LTEL', child: Text('电信')),
      DropdownMenuItem(value: 'LCNC', child: Text('联通')),
      DropdownMenuItem(value: 'LMOB', child: Text('移动')),
    ];
  }

  String _getLocalizedString(String key, [String? arg]) {
    final strings = {
      'record_type': '记录类型',
      'priority': '优先级',
      'weight': '权重',
      'priority_hint': '数值越小优先级越高',
      'proxied': '代理（Proxied）',
      'proxied_hint': '启用代理加速',
      'record_line': '记录线路',
      'fill_required': '请填写必填项',
      'record_added': '记录添加成功',
      'record_updated': '记录已更新',
      'record_deleted': '记录已删除',
      'delete_record_title': '删除记录',
      'delete_record_message': '确定要删除 "%s" 吗？此操作无法撤销。',
      'cancel': '取消',
      'add': '添加',
      'save': '保存',
      'delete': '删除',
    };

    var text = strings[key] ?? key;
    if (arg != null) {
      text = text.replaceAll('%s', arg);
    }
    return text;
  }
}