import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/credential_state.dart';
import '../../services/domain_state.dart';
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
      final credential = context.read<CredentialState>().selectedCredential;
      if (credential != null && mounted) {
        await context.read<DomainState>().refreshDnsRecordList(
          providerId: credential.providerId,
          domainId: widget.domainId,
          credentials: credential.credentials,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _autoLoadRecords() async {
    final credential = context.read<CredentialState>().selectedCredential;
    if (credential != null && mounted) {
      await context.read<DomainState>().refreshDnsRecordList(
        providerId: credential.providerId,
        domainId: widget.domainId,
        credentials: credential.credentials,
      );
    }
  }

  Future<void> _pullToRefresh() async {
    final credential = context.read<CredentialState>().selectedCredential;
    if (credential != null) {
      await context.read<DomainState>().refreshDnsRecordList(
        providerId: credential.providerId,
        domainId: widget.domainId,
        credentials: credential.credentials,
        isManual: true,
      );
    }
  }

  void _showAddRecordDialog(BuildContext context, String providerId) {
    final driver = DriverFactory.get(providerId);
    if (driver == null) return;
    final domainState = context.read<DomainState>();

    final nameController = TextEditingController();
    final contentController = TextEditingController();
    final priorityController = TextEditingController(text: '10');
    String selectedType = 'A';
    int ttl = 3600;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isOperating = domainState.isOperating;
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              StatefulBuilder(
                builder: (context, setBtnState) {
                  final isSubmitting = domainState.isOperating;
                  return FilledButton(
                    onPressed: isSubmitting ? null : () async {
                      if (contentController.text.isEmpty) {
                        ToastUtil.showError(context, '请填写记录值');
                        return;
                      }

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
                      if (result['success']) {
                        if (mounted) Navigator.pop(ctx);
                        if (context.mounted) ToastUtil.showSuccess(context, '记录添加成功');
                      } else {
                        if (mounted) {
                          ToastUtil.showError(
                            context,
                            result['error'] ?? '添加失败',
                            errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null,
                          );
                        }
                      }
                    },
                    child: domainState.isOperating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('添加'),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditRecordDialog(BuildContext context, String providerId, Map<String, dynamic> record) {
    final domainState = context.read<DomainState>();
    final nameController = TextEditingController(text: record['name'] ?? '');
    final contentController = TextEditingController(text: record['content'] ?? '');
    final priorityController = TextEditingController(text: (record['priority'] ?? 10).toString());
    String selectedType = record['type'] ?? 'A';
    int ttl = record['ttl'] ?? 3600;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isOperating = domainState.isOperating;
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
              StatefulBuilder(
                builder: (context, setBtnState) {
                  final isSubmitting = domainState.isOperating;
                  return FilledButton(
                    onPressed: isSubmitting ? null : () async {
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
                      if (result['success']) {
                        if (mounted) Navigator.pop(ctx);
                        if (context.mounted) ToastUtil.showSuccess(context, '记录已更新');
                      } else {
                        if (context.mounted) {
                          ToastUtil.showError(
                            context,
                            result['error'] ?? '更新失败',
                            errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null,
                          );
                        }
                      }
                    },
                    child: domainState.isOperating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('保存'),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteRecord(BuildContext context, String providerId, Map<String, dynamic> record) async {
    final name = record['name']?.toString() ?? '';
    final confirm = await showDnsConfirmDialog(
      context,
      title: '删除记录',
      message: '确定要删除 "$name" 吗？此操作无法撤销。',
      confirmLabel: '删除',
      isDestructive: true,
    );

    if (confirm == true && mounted) {
      final domainState = context.read<DomainState>();
      final result = await domainState.deleteDnsRecord(
        providerId,
        widget.domainId,
        record['id'].toString(),
        context.read<CredentialState>().selectedCredential!.credentials,
      );
      if (mounted) {
        if (result['success']) {
          ToastUtil.showSuccess(context, '记录已删除');
        } else {
          ToastUtil.showError(
            context,
            result['error'] ?? '删除失败',
            errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null,
          );
        }
      }
    }
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
    final domainState = context.watch<DomainState>();
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

  Widget _buildBody(DomainState state, List<Map<String, dynamic>> records, String providerId) {
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

    if (records.isEmpty) return _buildEmptyState();

    final showCenterLoading = state.showCenterLoading;

    return Stack(
      children: [
        RefreshIndicator(
          key: _refreshKey,
          onRefresh: _pullToRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: DnsSpacing.sm),
            itemCount: records.length,
            separatorBuilder: (_, __) => const DnsDivider(),
            itemBuilder: (context, index) {
              final record = records[index];
              return DnsDnsRecordTile(
                record: record,
                onEdit: state.isOperating ? null : () => _showEditRecordDialog(context, providerId, record),
                onDelete: state.isOperating ? null : () => _deleteRecord(context, providerId, record),
              );
            },
          ),
        ),
        if (showCenterLoading)
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

  Widget _buildEmptyState() {
    return const DnsEmptyState(
      icon: Icons.dns_outlined,
      title: '暂无DNS记录',
      description: '暂无DNS记录，请使用右下角按钮添加记录',
    );
  }
}