import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/credential_state.dart';
import '../../services/credential_storage.dart';
import '../../services/credential_validation.dart';
import '../../services/domain_state.dart';
import '../../drivers/driver_factory.dart';
import '../../utils/toast_util.dart';
import '../../core/ui/md3_widgets.dart';
import '../../core/theme/design_system.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndRefresh();
    });
  }

  Future<void> _initializeAndRefresh() async {
    final credentialState = context.read<CredentialState>();
    final domainState = context.read<DomainState>();
    await credentialState.loadCredentials();
    if (mounted) {
      final selected = credentialState.selectedCredential;
      if (selected != null) {
        await domainState.loadDomains(selected.providerId, selected.credentials);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final credentialState = context.watch<CredentialState>();
    final domainState = context.watch<DomainState>();
    final selected = credentialState.selectedCredential;
    final hasCredentials = credentialState.hasCredentials;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(hasCredentials ? (selected?.providerName ?? 'DNS管理') : 'DNS管理'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
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
      drawer: _buildDrawer(context, credentialState, domainState),
      body: _buildBody(context, domainState, credentialState, hasCredentials),
      floatingActionButton: hasCredentials
          ? _buildFab(context, selected!.providerId)
          : null,
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

  Widget _buildBody(
    BuildContext context,
    DomainState state,
    CredentialState credentialState,
    bool hasCredentials,
  ) {
    if (!hasCredentials) return _buildEmptyCredentialState(context);

    if (state.isLoading && state.domains.isEmpty) return const DnsLoading();

    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ToastUtil.showError(
            context,
            state.error!,
            errorCode: state.errorCode != null ? double.tryParse(state.errorCode!) : null,
          );
        }
      });
      if (state.domains.isEmpty) {
        return DnsErrorState(
          message: state.error!,
          onRetry: () {
            final selected = credentialState.selectedCredential;
            if (selected != null) {
              state.refreshDomains(selected.providerId, selected.credentials);
            }
          },
        );
      }
    }

    if (state.domains.isEmpty) return _buildEmptyDomainState(context);

    final selected = credentialState.selectedCredential;
    final driver = selected != null ? DriverFactory.get(selected.providerId) : null;
    final supportsDelete = driver?.supportsDeleteDomain ?? false;
    final supportsRenew = driver?.supportsRenewDomain ?? false;

    return RefreshIndicator(
      onRefresh: () async {
        if (selected != null) {
          await state.refreshDomains(selected.providerId, selected.credentials);
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: DnsSpacing.sm),
        itemCount: state.domains.length,
        separatorBuilder: (_, __) => const DnsDivider(),
        itemBuilder: (listContext, index) {
          final domain = state.domains[index];
          return DnsDomainTile(
            domain: domain,
            supportsDelete: supportsDelete,
            supportsRenew: supportsRenew,
            onTap: () {
              final domainId = domain['id']?.toString() ?? '';
              final domainName = domain['name']?.toString() ?? '';
              if (domainId.isNotEmpty) {
                GoRouter.of(context).push(
                  '/domains/$domainId/records?name=${Uri.encodeComponent(domainName)}',
                );
              }
            },
            onDelete: () => _handleDeleteDomain(context, state, selected, domain),
            onRenew: () => _handleRenewDomain(context, state, selected, domain),
          );
        },
      ),
    );
  }

  Future<void> _handleDeleteDomain(
    BuildContext context,
    DomainState state,
    dynamic selected,
    Map<String, dynamic> domain,
  ) async {
    final domainName = domain['name']?.toString() ?? '';
    final domainId = domain['id']?.toString() ?? '';
    final confirm = await showDnsConfirmDialog(
      context,
      title: '删除域名',
      message: '确定要删除 "$domainName" 吗？此操作无法撤销。',
      confirmLabel: '删除',
      isDestructive: true,
    );

    if (confirm == true && selected != null) {
      final result = await state.deleteDomain(selected.providerId, domainId);
      if (context.mounted) {
        if (result['success']) {
          ToastUtil.showSuccess(context, '域名已删除');
        } else {
          ToastUtil.showError(
            context,
            result['error'] ?? '删除失败',
            errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null,
          );
          await state.refreshDomains(selected.providerId, selected.credentials);
        }
      }
    }
  }

  Future<void> _handleRenewDomain(
    BuildContext context,
    DomainState state,
    dynamic selected,
    Map<String, dynamic> domain,
  ) async {
    if (selected == null) return;
    final domainId = domain['id']?.toString() ?? '';
    final result = await state.renewDomain(selected.providerId, domainId);
    if (context.mounted) {
      if (result['success']) {
        final msg = result['remaining_days'] != null
            ? '续期成功，剩余 ${result['remaining_days']} 天'
            : '续期成功';
        ToastUtil.showSuccess(context, msg);
      } else {
        ToastUtil.showError(
          context,
          result['error'] ?? '续期失败',
          errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null,
        );
      }
    }
  }

  void _showAddDomainDialog(BuildContext context, String providerId) {
    final domainState = context.read<DomainState>();
    final isDnshe = providerId == 'dnshe';
    final subdomainController = TextEditingController();
    final rootDomainController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isDnshe ? '添加子域名' : '添加域名'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDnshe) ...[
                TextField(
                  controller: subdomainController,
                  decoration: const InputDecoration(
                    labelText: '子域名前缀',
                    hintText: '例如: myapp',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rootDomainController,
                  decoration: const InputDecoration(
                    labelText: '根域名',
                    hintText: '例如: example.com',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '将创建: {子域名}.{根域名}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else ...[
                TextField(
                  controller: rootDomainController,
                  decoration: const InputDecoration(
                    labelText: '域名',
                    hintText: '例如: example.com',
                  ),
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
            onPressed: () async {
              Navigator.pop(ctx);

              if (isDnshe && (subdomainController.text.isEmpty || rootDomainController.text.isEmpty)) {
                ToastUtil.showError(context, '请填写完整信息');
                return;
              }
              if (!isDnshe && rootDomainController.text.isEmpty) {
                ToastUtil.showError(context, '请填写域名');
                return;
              }

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
              if (!result['success'] && context.mounted) {
                ToastUtil.showError(
                  context,
                  result['error'] ?? '添加失败',
                  errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null,
                );
              } else {
                await domainState.loadDomains(
                  providerId,
                  context.read<CredentialState>().selectedCredential!.credentials,
                );
                if (context.mounted) ToastUtil.showSuccess(context, '添加成功');
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCredentialState(BuildContext context) {
    return DnsEmptyState(
      icon: Icons.key_off,
      title: '请先添加凭证',
      description: '凭证用于连接DNS服务商，管理您的域名和DNS记录',
      action: FilledButton.icon(
        onPressed: () => _showAddCredentialDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('添加凭证'),
      ),
    );
  }

  Widget _buildEmptyDomainState(BuildContext context) {
    return DnsEmptyState(
      icon: Icons.dns,
      title: '暂无域名',
      description: '暂无域名，请使用右下角按钮添加域名',
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    CredentialState credentialState,
    DomainState domainState,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(DnsRadius.md),
                  ),
                  child: const Icon(Icons.dns, size: 28, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'DNS管理工具',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  credentialState.credentials.isNotEmpty
                      ? '已添加 ${credentialState.credentials.length} 个凭证'
                      : '未添加凭证',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: credentialState.credentials.isEmpty
                ? _buildEmptyCredentialList(context)
                : _buildCredentialList(context, credentialState, domainState),
          ),
          const DnsDivider(),
          ListTile(
            leading: Icon(Icons.add, color: colorScheme.primary),
            title: Text('添加凭证', style: TextStyle(color: colorScheme.primary)),
            onTap: () {
              Navigator.pop(context);
              _showAddCredentialDialog(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyCredentialList(BuildContext context) {
    return DnsEmptyState(
      icon: Icons.key_off,
      title: '暂无凭证',
      description: '点击下方按钮添加',
    );
  }

  Widget _buildCredentialList(
    BuildContext context,
    CredentialState credentialState,
    DomainState domainState,
  ) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(vertical: DnsSpacing.sm),
      itemCount: credentialState.credentials.length,
      onReorder: (oldIndex, newIndex) {
        credentialState.reorderCredentials(oldIndex, newIndex);
      },
      itemBuilder: (ctx, index) {
        final credential = credentialState.credentials[index];
        final isSelected = credentialState.selectedCredentialId == credential.id;

        return _CredentialItem(
          key: ValueKey(credential.id),
          index: index,
          credential: credential,
          isSelected: isSelected,
          onTap: () {
            credentialState.selectCredential(credential.id);
            domainState.clear();
            domainState.loadDomains(credential.providerId, credential.credentials);
            Navigator.pop(ctx);
          },
          onLongPress: () {
            _showCredentialActionsSheet(ctx, credential, credentialState);
          },
        );
      },
    );
  }

  void _showCredentialActionsSheet(
    BuildContext context,
    CredentialModel credential,
    CredentialState credentialState,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑凭证'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditCredentialDialog(context, credential);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              title: Text('删除凭证', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteCredentialDialog(context, credential, credentialState);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddCredentialDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _CredentialDialog(
        title: '添加凭证',
        onSave: (credential) async {
          final credentialState = context.read<CredentialState>();
          await credentialState.addCredential(credential);
          if (context.mounted) {
            ToastUtil.showSuccess(context, '添加凭证成功');
            Navigator.pop(ctx);
          }
        },
      ),
    );
  }

  void _showEditCredentialDialog(BuildContext context, CredentialModel credential) {
    showDialog(
      context: context,
      builder: (ctx) => _CredentialDialog(
        title: '编辑凭证',
        credential: credential,
        onSave: (updatedCredential) async {
          final credentialState = context.read<CredentialState>();
          await credentialState.updateCredential(updatedCredential);
          if (context.mounted) {
            ToastUtil.showSuccess(context, '更新凭证成功');
            Navigator.pop(ctx);
          }
        },
      ),
    );
  }

  void _showDeleteCredentialDialog(
    BuildContext context,
    CredentialModel credential,
    CredentialState credentialState,
  ) async {
    final confirm = await showDnsConfirmDialog(
      context,
      title: '删除凭证',
      message: '确定要删除 "${credential.providerName}" 的凭证吗？',
      confirmLabel: '删除',
      isDestructive: true,
    );

    if (confirm == true && context.mounted) {
      await credentialState.removeCredential(credential.id);
      if (context.mounted) ToastUtil.showSuccess(context, '删除凭证成功');
    }
  }
}

class _CredentialItem extends StatelessWidget {
  final int index;
  final CredentialModel credential;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CredentialItem({
    super.key,
    required this.index,
    required this.credential,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DnsSpacing.md,
            vertical: DnsSpacing.sm + 4,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest,
                  border: isSelected
                      ? Border.all(color: colorScheme.primary, width: 2)
                      : null,
                ),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(width: DnsSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      credential.providerName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (credential.remark != null && credential.remark!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        credential.remark!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.drag_handle,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CredentialDialog extends StatefulWidget {
  final String title;
  final CredentialModel? credential;
  final Function(CredentialModel) onSave;

  const _CredentialDialog({
    required this.title,
    this.credential,
    required this.onSave,
  });

  @override
  State<_CredentialDialog> createState() => _CredentialDialogState();
}

class _CredentialDialogState extends State<_CredentialDialog> {
  String? _selectedProviderId;
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _remarkController = TextEditingController();
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    if (widget.credential != null) {
      _selectedProviderId = widget.credential!.providerId;
      _remarkController.text = widget.credential!.remark ?? '';
      for (final key in widget.credential!.credentials.keys) {
        _controllers[key] = TextEditingController(text: widget.credential!.credentials[key]);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drivers = DriverFactory.getAll();
    final isEditing = widget.credential != null;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isEditing)
              DropdownButtonFormField<String>(
                value: _selectedProviderId,
                decoration: const InputDecoration(labelText: '选择服务商'),
                items: drivers.map((d) => DropdownMenuItem(
                  value: d.providerId,
                  child: Text(d.providerName),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProviderId = value;
                    _controllers.clear();
                  });
                },
              ),
            if (isEditing) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(DnsRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(widget.credential!.providerName),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _remarkController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                hintText: '用于区分不同凭证',
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedProviderId != null) ..._buildCredentialFields(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _selectedProviderId != null && !_isValidating ? _saveCredential : null,
          child: _isValidating
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('保存'),
        ),
      ],
    );
  }

  List<Widget> _buildCredentialFields() {
    final driver = DriverFactory.get(_selectedProviderId!);
    if (driver == null) return [];

    final fields = driver.getCredentialFields();
    return fields.entries.map((entry) {
      final key = entry.key;
      final label = entry.value;
      _controllers[key] = _controllers[key] ?? TextEditingController();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: _controllers[key],
          decoration: InputDecoration(labelText: label),
          obscureText: key.toLowerCase().contains('secret'),
        ),
      );
    }).toList();
  }

  Future<void> _saveCredential() async {
    if (_selectedProviderId == null) return;

    final driver = DriverFactory.get(_selectedProviderId!);
    if (driver == null) return;

    final credentials = <String, String>{};
    for (final key in _controllers.keys) {
      final value = _controllers[key]?.text;
      if (value != null && value.isNotEmpty) {
        credentials[key] = value;
      }
    }

    if (credentials.isEmpty) {
      ToastUtil.showError(context, '请填写密钥信息', errorCode: 400);
      return;
    }

    setState(() {
      _isValidating = true;
    });

    final result = await CredentialValidationService.validateCredential(
      _selectedProviderId!,
      credentials,
    );

    if (!result['success']) {
      setState(() {
        _isValidating = false;
      });
      if (mounted) {
        ToastUtil.showError(
          context,
          result['error'] ?? '凭证校验失败',
          errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null,
        );
      }
      return;
    }

    final remark = _remarkController.text.trim();

    if (widget.credential != null) {
      final updatedCredential = widget.credential!.copyWith(
        providerId: _selectedProviderId!.toLowerCase(),
        providerName: driver.providerName,
        remark: remark.isEmpty ? null : remark,
        credentials: credentials,
      );
      await widget.onSave(updatedCredential);
    } else {
      final credential = CredentialModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        providerId: _selectedProviderId!.toLowerCase(),
        providerName: driver.providerName,
        remark: remark.isEmpty ? null : remark,
        credentials: credentials,
        createdAt: DateTime.now(),
      );
      await widget.onSave(credential);
    }
  }
}
