import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/credential_state.dart';
import '../../services/domain_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final credentialState = context.watch<CredentialState>();
    final domainState = context.watch<DomainState>();
    final selected = credentialState.selectedCredential;

    final hasCredentials = credentialState.hasCredentials;

    return Scaffold(
      appBar: AppBar(
        title: Text(hasCredentials ? (selected?.providerName ?? 'DNS管理') : 'DNS管理'),
        actions: hasCredentials
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    if (selected != null) {
                      domainState.loadDomains(selected.providerId, selected.credentials);
                    }
                  },
                ),
              ]
            : null,
      ),
      body: _buildBody(context, domainState, hasCredentials),
      drawer: _buildDrawer(context, credentialState, domainState),
    );
  }

  Widget _buildBody(BuildContext context, DomainState state, bool hasCredentials) {
    if (!hasCredentials) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.key_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('请先添加凭证', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Text('点击右上角菜单或下方按钮添加'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => GoRouter.of(context).push('/settings/credential/add'),
              icon: const Icon(Icons.add),
              label: const Text('添加凭证'),
            ),
          ],
        ),
      );
    }

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
              onPressed: () => state.clear(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state.domains.isEmpty) {
      return const Center(child: Text('暂无域名'));
    }

    return ListView.builder(
      itemCount: state.domains.length,
      itemBuilder: (context, index) {
        final domain = state.domains[index];
        return ListTile(
          title: Text(domain['name'] ?? 'Unknown'),
          subtitle: Text(domain['status'] ?? ''),
          onTap: () {
            final credential = context.read<CredentialState>().selectedCredential;
            if (credential != null) {
              state.loadDnsRecords(credential.providerId, domain['id']);
              _showDnsRecords(context, domain['name']);
            }
          },
        );
      },
    );
  }

  void _showDnsRecords(BuildContext context, String domainName) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Consumer<DomainState>(
        builder: (context, state, _) {
          final records = state.currentDnsRecords;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('$domainName - DNS记录', style: Theme.of(context).textTheme.titleLarge),
              ),
              Expanded(
                child: records.isEmpty
                    ? const Center(child: Text('暂无记录'))
                    : ListView.builder(
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return ListTile(
                            title: Text(record['name'] ?? ''),
                            subtitle: Text('${record['type']} - ${record['content']}'),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, CredentialState state, DomainState domainState) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.dns, size: 48, color: Colors.white),
                const SizedBox(height: 8),
                const Text('DNS管理工具', style: TextStyle(fontSize: 20, color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  state.credentials.isNotEmpty
                      ? '已添加 ${state.credentials.length} 个凭证'
                      : '未添加凭证',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          if (state.credentials.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('服务商凭证', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),
            ...state.credentials.map((c) => ListTile(
                  leading: Icon(
                    state.selectedCredentialId == c.id ? Icons.check_circle : Icons.circle_outlined,
                    color: state.selectedCredentialId == c.id ? Colors.green : null,
                  ),
                  title: Text(c.providerName),
                  subtitle: Text(c.providerId, style: const TextStyle(fontSize: 12)),
                  selected: state.selectedCredentialId == c.id,
                  selectedTileColor: Colors.blue.withValues(alpha: 0.1),
                  onTap: () {
                    state.selectCredential(c.id);
                    domainState.clear();
                    domainState.loadDomains(c.providerId, c.credentials);
                    Navigator.pop(context);
                  },
                )),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('添加凭证'),
            onTap: () {
              Navigator.pop(context);
              GoRouter.of(context).push('/settings/credential/add');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () {
              Navigator.pop(context);
              GoRouter.of(context).push('/settings');
            },
          ),
        ],
      ),
    );
  }
}