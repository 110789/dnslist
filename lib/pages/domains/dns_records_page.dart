import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/credential_state.dart';
import '../../services/domain_state.dart';
import '../../drivers/driver_factory.dart';

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
      final credential = context.read<CredentialState>().selectedCredential;
      if (credential != null) {
        context.read<DomainState>().loadDnsRecords(credential.providerId, widget.domainId);
      }
    });
  }

  void _showResultSnackBar(BuildContext context, bool success, String? message, String? statusCode) {
    final content = statusCode != null 
        ? '${message ?? (success ? '操作成功' : '操作失败')}\n状态码: $statusCode'
        : (message ?? (success ? '操作成功' : '操作失败'));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(content),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAddRecordDialog(BuildContext context, String providerId) {
    final credential = context.read<CredentialState>().selectedCredential;
    if (credential == null) return;
    
    final driver = DriverFactory.get(providerId);
    if (driver == null) return;

    final nameController = TextEditingController();
    final contentController = TextEditingController();
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
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: '记录类型'),
                  items: driver.getSupportedRecordTypes().map((t) => 
                    DropdownMenuItem(value: t, child: Text(t))
                  ).toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '记录名称'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: '记录值'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: ttl.toString()),
                  decoration: const InputDecoration(labelText: 'TTL (秒)'),
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
                final recordData = {
                  'name': nameController.text,
                  'type': selectedType,
                  'content': contentController.text,
                  'ttl': ttl,
                };
                final domainState = context.read<DomainState>();
                final result = await domainState.createDnsRecord(
                  providerId,
                  widget.domainId,
                  recordData,
                );
                if (mounted) {
                  _showResultSnackBar(context, result['success'], result['error'], result['errorCode']);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRecordDialog(BuildContext context, String providerId, Map<String, dynamic> record) {
    final credential = context.read<CredentialState>().selectedCredential;
    if (credential == null) return;

    final nameController = TextEditingController(text: record['name'] ?? '');
    final contentController = TextEditingController(text: record['content'] ?? '');
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
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: '记录类型'),
                  items: ['A', 'AAAA', 'CNAME', 'MX', 'TXT'].map((t) => 
                    DropdownMenuItem(value: t, child: Text(t))
                  ).toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '记录名称'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: '记录值'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: ttl.toString()),
                  decoration: const InputDecoration(labelText: 'TTL (秒)'),
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
                final recordData = {
                  'name': nameController.text,
                  'type': selectedType,
                  'content': contentController.text,
                  'ttl': ttl,
                };
                final domainState = context.read<DomainState>();
                final result = await domainState.updateDnsRecord(
                  providerId,
                  widget.domainId,
                  record['id'].toString(),
                  recordData,
                );
                if (mounted) {
                  _showResultSnackBar(context, result['success'], result['error'], result['errorCode']);
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
        content: Text('确定要删除 ${record['name']} 吗？'),
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
        _showResultSnackBar(context, result['success'], result['error'], result['errorCode']);
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
            onPressed: () {
              final credential = credentialState.selectedCredential;
              if (credential != null) {
                domainState.loadDnsRecords(credential.providerId, widget.domainId);
              }
            },
          ),
        ],
      ),
      body: _buildBody(domainState, records, providerId),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordDialog(context, providerId),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(DomainState state, List<Map<String, dynamic>> records, String providerId) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(state.error!, style: const TextStyle(color: Colors.red)),
                  if (state.errorCode != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '状态码: ${state.errorCode}',
                      style: TextStyle(color: Colors.red.shade300, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final credential = context.read<CredentialState>().selectedCredential;
                if (credential != null) {
                  state.loadDnsRecords(credential.providerId, widget.domainId);
                }
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (records.isEmpty) {
      return const Center(child: Text('暂无DNS记录'));
    }

    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return ListTile(
          title: Text(record['name'] ?? ''),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('类型: ${record['type']}'),
              Text('值: ${record['content']}'),
              if (record['ttl'] != null) Text('TTL: ${record['ttl']}'),
            ],
          ),
          isThreeLine: true,
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditRecordDialog(context, providerId, record);
              } else if (value == 'delete') {
                _deleteRecord(context, providerId, record);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('编辑')),
              const PopupMenuItem(value: 'delete', child: Text('删除')),
            ],
          ),
        );
      },
    );
  }
}