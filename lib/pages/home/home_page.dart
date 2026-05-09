import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/credential_state.dart';
import '../../services/domain_state.dart';
import '../../drivers/driver_factory.dart';

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
      body: _buildBody(context, domainState, credentialState, hasCredentials),
      drawer: _buildDrawer(context, credentialState, domainState),
      floatingActionButton: hasCredentials ? _buildFab(context, selected!.providerId) : null,
    );
  }

  Widget? _buildFab(BuildContext context, String providerId) {
    final driver = DriverFactory.get(providerId);
    if (driver == null || !driver.supportsAddDomain) return null;

    return FloatingActionButton(
      onPressed: () => _showAddDomainDialog(context, providerId),
      child: const Icon(Icons.add),
    );
  }

  void _showAddDomainDialog(BuildContext context, String providerId) {
    final driver = DriverFactory.get(providerId);
    if (driver == null) return;

    final domainState = context.read<DomainState>();
    final isDnshe = providerId == 'dnshe';
    
    final subdomainController = TextEditingController();
    final rootDomainController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加域名'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDnshe) ...[
              TextField(
                controller: subdomainController,
                decoration: const InputDecoration(labelText: '子域名前缀'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: rootDomainController,
                decoration: const InputDecoration(labelText: '根域名'),
              ),
            ] else ...[
              TextField(
                controller: rootDomainController,
                decoration: const InputDecoration(labelText: '域名'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              Map<String, dynamic> domainData;
              if (isDnshe) {
                domainData = {
                  'subdomain': subdomainController.text,
                  'rootdomain': rootDomainController.text,
                };
              } else {
                domainData = {
                  'name': rootDomainController.text,
                  'type': 'full',
                };
              }

              final result = await domainState.addDomain(providerId, domainData);
              if (result['error'] != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('添加失败: ${result['error']}')),
                );
              } else {
                domainState.loadDomains(
                  providerId,
                  context.read<CredentialState>().selectedCredential!.credentials,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('添加成功')),
                  );
                }
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, DomainState state, CredentialState credentialState, bool hasCredentials) {
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

    final selected = credentialState.selectedCredential;
    final driver = selected != null ? DriverFactory.get(selected.providerId) : null;
    final supportsDelete = driver?.supportsDeleteDomain ?? false;
    final supportsRenew = driver?.supportsRenewDomain ?? false;

    return ListView.builder(
      itemCount: state.domains.length,
      itemBuilder: (context, index) {
        final domain = state.domains[index];
        final domainName = domain['name'] ?? 'Unknown';
        final domainId = domain['id']?.toString() ?? '';
        return ListTile(
          title: Text(domainName),
          subtitle: Text(domain['status'] ?? ''),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('删除域名'),
                    content: Text('确定要删除 $domainName 吗？'),
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
                if (confirm == true && selected != null) {
                  await state.deleteDomain(selected.providerId, domainId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('删除成功')),
                    );
                  }
                }
              } else if (value == 'renew') {
                if (selected != null) {
                  final result = await state.renewDomain(selected.providerId, domainId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['error'] ?? 
                          (result['remaining_days'] != null ? '续期成功，剩余 ${result['remaining_days']} 天' : '续期成功')),
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              if (supportsDelete)
                const PopupMenuItem(value: 'delete', child: Text('删除')),
              if (supportsRenew)
                const PopupMenuItem(value: 'renew', child: Text('续期')),
            ],
          ),
          onTap: () {
            if (domainId.isNotEmpty) {
              GoRouter.of(context).push(
                '/domains/$domainId/records?name=${Uri.encodeComponent(domainName)}',
              );
            }
          },
        );
      },
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
                  subtitle: Text(
                    c.remark != null && c.remark!.isNotEmpty
                        ? '${c.providerId} · ${c.remark}'
                        : c.providerId,
                    style: const TextStyle(fontSize: 12),
                  ),
                  selected: state.selectedCredentialId == c.id,
                  selectedTileColor: Colors.blue.withValues(alpha: 0.1),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                      GoRouter.of(context).push('/settings/credential/${c.id}/edit');
                    },
                  ),
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