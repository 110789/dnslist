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

    if (!credentialState.hasCredentials) {
      return Scaffold(
        appBar: AppBar(title: const Text('DNS管理')),
        body: const Center(
          child: Text('请先添加凭证'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(selected?.providerName ?? 'DNS管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (selected != null) {
                domainState.loadDomains(selected.providerId, selected.credentials);
              }
            },
          ),
        ],
      ),
      body: _buildBody(context, domainState),
      drawer: _buildDrawer(context, credentialState, domainState),
    );
  }

  Widget _buildBody(BuildContext context, DomainState state) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('凭证管理', style: TextStyle(fontSize: 24, color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  state.credentials.isNotEmpty
                      ? '已添加 ${state.credentials.length} 个凭证'
                      : '未添加凭证',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ...state.credentials.map((c) => ListTile(
                leading: Icon(
                  state.selectedCredentialId == c.id ? Icons.check_circle : Icons.circle_outlined,
                ),
                title: Text(c.providerName),
                subtitle: Text(c.providerId),
                selected: state.selectedCredentialId == c.id,
                onTap: () {
                  state.selectCredential(c.id);
                  domainState.clear();
                  domainState.loadDomains(c.providerId, c.credentials);
                  Navigator.pop(context);
                },
              )),
          const Divider(),
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