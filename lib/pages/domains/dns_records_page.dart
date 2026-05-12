import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/credential_state.dart';
import '../../services/new_domain_state.dart';
import '../../services/refresh_helper.dart';
import '../../drivers/driver_factory.dart';
import '../../utils/toast_util.dart';
import '../../core/ui/md3_widgets.dart';
import '../../core/theme/design_system.dart';

class DnsRecordsPage extends StatefulWidget {
  final String domainId;
  final String domainName;

  const DnsRecordsPage({
    super.key,
    required this.domainId,
    required this.domainName,
  });

  @override
  State<DnsRecordsPage> createState() => _DnsRecordsPageState();
}

class _DnsRecordsPageState extends State<DnsRecordsPage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await RefreshHelper.refreshDnsRecordListPassive(
          context,
          domainId: widget.domainId,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _autoLoadRecords() async {
    await RefreshHelper.refreshDnsRecordListPassive(
      context,
      domainId: widget.domainId,
    );
  }

  Future<void> _pullToRefresh() async {
    await RefreshHelper.refreshDnsRecordListManual(
      context,
      domainId: widget.domainId,
    );
  }

  void _showAddRecordDialog(BuildContext context, String providerId) {
    final driver = DriverFactory.get(providerId);
    if (driver == null) return;

    final domainState = context.read<NewDomainState>();
    final credentialState = context.read<CredentialState>();
    final credentials = credentialState.selectedCredential?.credentials ?? {};

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
      if (driver.supportsProxy) {
        proxied = false;
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
                    decoration: const InputDecoration(labelText: '记录类型'),
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
                  if (selectedType == 'MX' || selectedType == 'SRV') ...[
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        labelText: selectedType == 'MX' ? '优先级' : '权重',
                        hintText: '数值越小优先级越高',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => priorityValue = v,
                    ),
                  ],
                  if (driver.supportsProxy && (selectedType == 'A' || selectedType == 'AAAA' || selectedType == 'CNAME')) ...[
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('代理（Proxied）'),
                      subtitle: const Text('启用代理加速'),
                      value: proxied,
                      onChanged: (v) => setDialogState(() => proxied = v),
                    ),
                  ],
                  if (driver.supportsRecordLine()) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: fieldValues['line'] ?? 'DEFAULT',
                      decoration: const InputDecoration(labelText: '记录线路'),
                      items: const [
                        DropdownMenuItem(value: 'DEFAULT', child: Text('默认')),
                        DropdownMenuItem(value: 'LTEL', child: Text('电信')),
                        DropdownMenuItem(value: 'LCNC', child: Text('联通')),
                        DropdownMenuItem(value: 'LMOB', child: Text('移动')),
                      ],
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
                      child: Text('请填写必填项', style: TextStyle(color: Theme.of(dialogContext).colorScheme.error, fontSize: 12)),
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
                  bool hasEmpty = false;
                  for (final field in fields) {
                    if (field.required && (fieldValues[field.key]?.isEmpty ?? true)) {
                      hasEmpty = true;
                      break;
                    }
                  }

                  final contentKey = providerId == 'cloudns' ? 'record' :
                                   providerId == 'dnshe' ? 'record' :
                                   providerId == 'rainyun' ? 'value' : 'content';
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

                  final result = await domainState.createDnsRecord(
                    providerId,
                    widget.domainId,
                    recordData,
                    credentials,
                  );

                  if (dialogContext.mounted) {
                    if (result['success']) {
                      Navigator.pop(dialogContext);
                      ToastUtil.showSuccess(context, '记录添加成功');
                    } else {
                      setDialogState(() => isSubmitting = false);
                      ToastUtil.showError(
                        context,
                        result['error'] ?? '',
                        errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null,
                      );
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

  void _showEditRecordDialog(BuildContext context, String providerId, Map<String, dynamic> record) {
    final driver = DriverFactory.get(providerId);
    if (driver == null) return;

    final domainState = context.read<NewDomainState>();
    final credentialState = context.read<CredentialState>();
    final credentials = credentialState.selectedCredential?.credentials ?? {};

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
      if (driver.supportsProxy) {
        proxied = record['proxied'] == true;
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
                    decoration: const InputDecoration(labelText: '记录类型'),
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
                  if (selectedType == 'MX' || selectedType == 'SRV') ...[
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        labelText: selectedType == 'MX' ? '优先级' : '权重',
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                        text: record['priority']?.toString() ??
                              record['mx']?.toString() ??
                              '10',
                      ),
                      onChanged: (v) => fieldValues['priority'] = v,
                    ),
                  ],
                  if (driver.supportsProxy && (selectedType == 'A' || selectedType == 'AAAA' || selectedType == 'CNAME')) ...[
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('代理（Proxied）'),
                      subtitle: const Text('启用代理加速'),
                      value: proxied,
                      onChanged: (v) => setDialogState(() => proxied = v),
                    ),
                  ],
                  if (driver.supportsRecordLine()) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: fieldValues['line'] ?? record['line']?.toString() ?? 'DEFAULT',
                      decoration: const InputDecoration(labelText: '记录线路'),
                      items: const [
                        DropdownMenuItem(value: 'DEFAULT', child: Text('默认')),
                        DropdownMenuItem(value: 'LTEL', child: Text('电信')),
                        DropdownMenuItem(value: 'LCNC', child: Text('联通')),
                        DropdownMenuItem(value: 'LMOB', child: Text('移动')),
                      ],
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
                child: const Text('取消'),
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

                  final result = await domainState.updateDnsRecord(
                    providerId,
                    widget.domainId,
                    record['id'].toString(),
                    recordData,
                    credentials,
                  );

                  if (dialogContext.mounted) {
                    if (result['success']) {
                      Navigator.pop(dialogContext);
                      ToastUtil.showSuccess(context, '记录已更新');
                    } else {
                      setDialogState(() => isSubmitting = false);
                      ToastUtil.showError(
                        context,
                        result['error'] ?? '更新失败',
                        errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null,
                      );
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

  void _deleteRecord(BuildContext context, String providerId, Map<String, dynamic> record) {
    final name = record['name']?.toString() ?? '';
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('删除记录'),
            content: Text('确定要删除 "$name" 吗？此操作无法撤销。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('取消'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  foregroundColor: Theme.of(dialogContext).colorScheme.onError,
                ),
                onPressed: isDeleting ? null : () async {
                  setDialogState(() => isDeleting = true);
                  final domainState = context.read<NewDomainState>();
                  final result = await domainState.deleteDnsRecord(
                    providerId,
                    widget.domainId,
                    record['id'].toString(),
                    context.read<CredentialState>().selectedCredential!.credentials,
                  );
                  if (dialogContext.mounted) {
                    if (result['success']) {
                      Navigator.pop(dialogContext);
                      ToastUtil.showSuccess(context, '记录已删除');
                    } else {
                      setDialogState(() => isDeleting = false);
                      ToastUtil.showError(
                        context,
                        result['error'] ?? '删除失败',
                        errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null,
                      );
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

  @override
  Widget build(BuildContext context) {
    final credentialState = context.watch<CredentialState>();
    final domainState = context.watch<NewDomainState>();
    final records = domainState.dnsRecords[widget.domainId] ?? [];
    final providerId = credentialState.selectedCredential?.providerId ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.domainName),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _autoLoadRecords,
          ),
        ],
      ),
      body: _buildBody(domainState, records, providerId),
      floatingActionButton: providerId.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddRecordDialog(context, providerId),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(NewDomainState state, List<Map<String, dynamic>> records, String providerId) {
    if (state.isManualRefreshing) {
      return RefreshIndicator(
        key: _refreshKey,
        onRefresh: _pullToRefresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: DnsSpacing.sm),
          itemCount: 0,
          separatorBuilder: (_, __) => const DnsDivider(),
          itemBuilder: (_, __) => const SizedBox.shrink(),
        ),
      );
    }

    if (state.isLoading && records.isEmpty) return const DnsLoading();

    if (state.error != null) {
      final hasError = state.error != null;
      if (hasError && records.isEmpty) {
        return DnsErrorState(
          message: state.error!,
          onRetry: _autoLoadRecords,
        );
      }
    }

    final isLoading = state.loadingState == LoadingState.loading;

    if (isLoading && records.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final showCenterLoading = state.showCenterLoading;
    if (showCenterLoading) {
      return Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      );
    }

    if (records.isEmpty) {
      return Stack(
        children: [
          RefreshIndicator(
            key: _refreshKey,
            onRefresh: _pullToRefresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: DnsSpacing.sm),
              itemCount: 0,
              separatorBuilder: (_, __) => const DnsDivider(),
              itemBuilder: (_, __) => const SizedBox.shrink(),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: _buildEmptyState(),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _pullToRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: DnsSpacing.sm),
        itemCount: records.length,
        separatorBuilder: (_, __) => const DnsDivider(),
        itemBuilder: (context, index) {
          final record = records[index];
          return DnsDnsRecordTile(
            record: record,
            onEdit: state.isOperating ? null : () => _showEditRecordDialog(context, providerId, record),
            onDelete: state.isOperating ? () {} : () => _deleteRecord(context, providerId, record),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const DnsEmptyState(
      icon: Icons.dns_outlined,
      title: '暂无DNS记录',
      description: '暂无DNS记录，请使用右下角按钮添加记录',
    );
  }
}
