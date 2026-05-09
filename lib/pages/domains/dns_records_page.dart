import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/credential_state.dart';
import '../../services/domain_state.dart';

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

  @override
  Widget build(BuildContext context) {
    final domainState = context.watch<DomainState>();
    final records = domainState.dnsRecords[widget.domainId] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.domainName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final credential = context.read<CredentialState>().selectedCredential;
              if (credential != null) {
                domainState.loadDnsRecords(credential.providerId, widget.domainId);
              }
            },
          ),
        ],
      ),
      body: _buildBody(domainState, records),
    );
  }

  Widget _buildBody(DomainState state, List<Map<String, dynamic>> records) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!, style: const TextStyle(color: Colors.red)),
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
        );
      },
    );
  }
}