import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/credential_state.dart';
import '../../services/new_domain_state.dart';
import '../../core/refresh/refresh_helper.dart';
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

    final nameController = TextEditingController();
    final contentController = TextEditingController();
    final priorityController = TextEditingController(text: '10');
    String selectedType = 'A';
    int ttl = 3600;
    bool isSubmitting = false;
    bool hasError = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final bool canSubmit = !isSubmitting && !hasError;

          return AlertDialog(
            title: const Text('添加DNS记录'),
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
                    onChanged: (v) => setDialogState(() => selectedType = v!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: '记录名称',
                      hintText: selectedType == 'MX' || selectedType == 'SRV'
                          ? '例如: mail' : '例如: www 或 @',
                    ),
                    onChanged: (_) {
                      if (hasError) setDialogState(() => hasError = false);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(
                      labelText: _getContentLabel(selectedType),
                      hintText: _getContentHint(selectedType),
                    ),
                    keyboardType: _getContentKeyboardType(selectedType),
                    onChanged: (_) {
                      if (hasError) setDialogState(() => hasError = false);
                    },
                  ),
                  if (selectedType == 'MX' || selectedType == 'SRV') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: priorityController,
                      decoration: InputDecoration(
                        labelText: selectedType == 'MX' ? '优先级' : '权重',
                        hintText: '数值越小优先级越高',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(text: ttl.toString()),
                    decoration: const InputDecoration(
                      labelText: 'TTL (秒)',
                      hintText: '3600 = 1小时',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => ttl = int.tryParse(v) ?? 3600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TTL: 3600建议用于频繁变更的记录',
                    style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                      color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('请填写记录值', style: TextStyle(color: Theme.of(dialogContext).colorScheme.error, fontSize: 12)),
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
                onPressed: canSubmit ? () async {
                  if (contentController.text.isEmpty) {
                    setDialogState(() => hasError = true);
                    return;
                  }

                  setDialogState(() { isSubmitting = true; hasError = false; });

                  final recordData = <String, dynamic>{
                    'type': selectedType,
                    'name': nameController.text,
                    'content': contentController.text,
                    'ttl': ttl,
                  };

                  if (selectedType == 'MX' || selectedType == 'SRV') {
                    recordData['priority'] = int.tryParse(priorityController.text) ?? 10;
                  }

                  final result = await domainState.createDnsRecord(
                    providerId,
                    widget.domainId,
                    recordData,
                    context.read<CredentialState>().selectedCredential!.credentials,
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
                } : null,
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
    final domainState = context.read<NewDomainState>();
    final nameController = TextEditingController(text: record['name'] ?? '');
    final contentController = TextEditingController(text: record['content'] ?? '');
    final priorityController = TextEditingController(text: (record['priority'] ?? 10).toString());
    String selectedType = record['type'] ?? 'A';
    int ttl = record['ttl'] ?? 3600;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('编辑DNS记录'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: '记录类型'),
                    items: ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'SRV'].map((t) =>
                      DropdownMenuItem(value: t, child: Text(t))
                    ).toList(),
                    onChanged: (v) => setDialogState(() => selectedType = v!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '记录名称'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(
                      labelText: _getContentLabel(selectedType),
                      hintText: _getContentHint(selectedType),
                    ),
                    keyboardType: _getContentKeyboardType(selectedType),
                  ),
                  if (selectedType == 'MX' || selectedType == 'SRV') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: priorityController,
                      decoration: InputDecoration(
                        labelText: selectedType == 'MX' ? '优先级' : '权重',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(text: ttl.toString()),
                    decoration: const InputDecoration(
                      labelText: 'TTL (秒)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => ttl = int.tryParse(v) ?? 3600,
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
                  setDialogState(() => isSubmitting = true);

                  final recordData = <String, dynamic>{
                    'type': selectedType,
                    'name': nameController.text,
                    'content': contentController.text,
                    'ttl': ttl,
                  };

                  if (selectedType == 'MX' || selectedType == 'SRV') {
                    recordData['priority'] = int.tryParse(priorityController.text) ?? 10;
                  }

                  final result = await domainState.updateDnsRecord(
                    providerId,
                    widget.domainId,
                    record['id'].toString(),
                    recordData,
                    context.read<CredentialState>().selectedCredential!.credentials,
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

  String _getContentLabel(String type) {
    switch (type) {
      case 'A': return 'IPv4地址';
      case 'AAAA': return 'IPv6地址';
      case 'CNAME': return '目标域名';
      case 'MX': return '邮件服务器';
      case 'TXT': return '记录值';
      default: return '记录值';
    }
  }

  String _getContentHint(String type) {
    switch (type) {
      case 'A': return '例如: 192.168.1.1';
      case 'AAAA': return '例如: 2001:db8::1';
      case 'CNAME': return '例如: example.com';
      case 'MX': return '例如: mail.example.com';
      case 'TXT': return '例如: v=spf1 include:_spf.example.com ~all';
      default: return '';
    }
  }

  TextInputType _getContentKeyboardType(String type) {
    switch (type) {
      case 'A': return TextInputType.number;
      default: return TextInputType.text;
    }
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