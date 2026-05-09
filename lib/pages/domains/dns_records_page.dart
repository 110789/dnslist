import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/credential_state.dart';
import '../../services/domain_state.dart';
import '../../drivers/driver_factory.dart';
import '../../utils/toast_util.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecords();
    });
  }

  void _loadRecords() {
    final credential = context.read<CredentialState>().selectedCredential;
    if (credential != null) {
      context.read<DomainState>().loadDnsRecords(credential.providerId, widget.domainId);
    }
  }

  Future<void> _refreshRecords() async {
    final credential = context.read<CredentialState>().selectedCredential;
    if (credential != null) {
      await context.read<DomainState>().loadDnsRecords(credential.providerId, widget.domainId);
    }
  }

  void _showAddRecordDialog(BuildContext context, String providerId) {
    final credential = context.read<CredentialState>().selectedCredential;
    if (credential == null) return;

    final driver = DriverFactory.get(providerId);
    if (driver == null) return;

    final nameController = TextEditingController();
    final contentController = TextEditingController();
    final priorityController = TextEditingController(text: '10');
    String selectedType = 'A';
    int ttl = 3600;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                        ? '例如: mail'
                        : '例如: www 或 @',
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);

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

                final domainState = context.read<DomainState>();
                final result = await domainState.createDnsRecord(
                  providerId,
                  widget.domainId,
                  recordData,
                );
                if (mounted) {
                  if (result['success']) {
                    ToastUtil.showSuccess(context, '记录添加成功');
                  } else {
                    ToastUtil.showError(context, result['error'] ?? '添加失败', errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null);
                  }
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  String _getContentLabel(String type) {
    switch (type) {
      case 'A':
        return 'IPv4地址';
      case 'AAAA':
        return 'IPv6地址';
      case 'CNAME':
        return '目标域名';
      case 'MX':
        return '邮件服务器';
      case 'TXT':
        return '记录值';
      default:
        return '记录值';
    }
  }

  String _getContentHint(String type) {
    switch (type) {
      case 'A':
        return '例如: 192.168.1.1';
      case 'AAAA':
        return '例如: 2001:db8::1';
      case 'CNAME':
        return '例如: example.com';
      case 'MX':
        return '例如: mail.example.com';
      case 'TXT':
        return '例如: v=spf1 include:_spf.example.com ~all';
      default:
        return '';
    }
  }

  TextInputType _getContentKeyboardType(String type) {
    switch (type) {
      case 'A':
        return TextInputType.number;
      case 'AAAA':
        return TextInputType.text;
      case 'MX':
      case 'SRV':
        return TextInputType.text;
      default:
        return TextInputType.text;
    }
  }

  void _showEditRecordDialog(BuildContext context, String providerId, Map<String, dynamic> record) {
    final nameController = TextEditingController(text: record['name'] ?? '');
    final contentController = TextEditingController(text: record['content'] ?? '');
    final priorityController = TextEditingController(text: (record['priority'] ?? 10).toString());
    String selectedType = record['type'] ?? 'A';
    int ttl = record['ttl'] ?? 3600;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);

                final recordData = <String, dynamic>{
                  'type': selectedType,
                  'name': nameController.text,
                  'content': contentController.text,
                  'ttl': ttl,
                };

                if (selectedType == 'MX' || selectedType == 'SRV') {
                  recordData['priority'] = int.tryParse(priorityController.text) ?? 10;
                }

                final domainState = context.read<DomainState>();
                final result = await domainState.updateDnsRecord(
                  providerId,
                  widget.domainId,
                  record['id'].toString(),
                  recordData,
                );
                if (mounted) {
                  if (result['success']) {
                    ToastUtil.showSuccess(context, '记录已更新');
                  } else {
                    ToastUtil.showError(context, result['error'] ?? '更新失败', errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null);
                  }
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRecord(BuildContext context, String providerId, Map<String, dynamic> record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除记录'),
        content: Text('确定要删除 "${record['name']}" 吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final domainState = context.read<DomainState>();
      final result = await domainState.deleteDnsRecord(
        providerId,
        widget.domainId,
        record['id'].toString(),
      );
      if (mounted) {
        if (result['success']) {
          ToastUtil.showSuccess(context, '记录已删除');
        } else {
          ToastUtil.showError(context, result['error'] ?? '删除失败', errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final credentialState = context.watch<CredentialState>();
    final domainState = context.watch<DomainState>();
    final records = domainState.dnsRecords[widget.domainId] ?? [];
    final providerId = credentialState.selectedCredential?.providerId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.domainName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRecords,
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
    if (state.isLoading && records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && records.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ToastUtil.showError(context, state.error!, errorCode: state.errorCode != null ? double.tryParse(state.errorCode!) : null);
        state.clear();
      });
      return const Center(child: CircularProgressIndicator());
    }

    if (records.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshRecords,
      child: ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return _buildRecordItem(context, providerId, record);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dns_outlined, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              '暂无DNS记录',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              '暂无DNS记录，请使用右下角按钮添加记录',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordItem(BuildContext context, String providerId, Map<String, dynamic> record) {
    final recordName = record['name'] ?? '';
    final recordType = record['type'] ?? '';
    final recordContent = record['content'] ?? '';

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getTypeColor(recordType).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          recordType,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _getTypeColor(recordType),
          ),
        ),
      ),
      title: Text(
        recordName,
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              recordContent,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (record['proxied'] == true) ...[
            const SizedBox(width: 8),
            Icon(Icons.cloud, size: 14, color: Colors.orange.shade400),
          ],
        ],
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 20),
        onSelected: (value) {
          if (value == 'edit') {
            _showEditRecordDialog(context, providerId, record);
          } else if (value == 'delete') {
            _deleteRecord(context, providerId, record);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'edit', child: Text('编辑')),
          const PopupMenuItem(
            value: 'delete',
            child: Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'A':
        return Colors.blue;
      case 'AAAA':
        return Colors.purple;
      case 'CNAME':
        return Colors.green;
      case 'MX':
        return Colors.orange;
      case 'TXT':
        return Colors.teal;
      case 'NS':
        return Colors.indigo;
      case 'SRV':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
