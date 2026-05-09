import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/credential_state.dart';
import '../../services/credential_storage.dart';
import '../../services/credential_validation.dart';
import '../../services/domain_state.dart';
import '../../drivers/driver_factory.dart';
import '../../utils/toast_util.dart';

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

  Widget _buildBody(BuildContext context, DomainState state, CredentialState credentialState, bool hasCredentials) {
    if (!hasCredentials) {
      return _buildEmptyCredentialState(context);
    }

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ToastUtil.showError(context, state.error!, errorCode: state.errorCode != null ? double.tryParse(state.errorCode!) : null);
        final currentDomains = state.domains;
        state.clear();
        if (currentDomains.isNotEmpty) {
          final selected = credentialState.selectedCredential;
          if (selected != null) {
            state.loadDomains(selected.providerId, selected.credentials);
          }
        }
      });
      if (state.domains.isNotEmpty) {
        return RefreshIndicator(
          onRefresh: () async {
            final selected = credentialState.selectedCredential;
            if (selected != null) {
              await state.loadDomains(selected.providerId, selected.credentials);
            }
          },
          child: ListView.builder(
            itemCount: state.domains.length,
            itemBuilder: (listContext, index) {
              final domain = state.domains[index];
              return _buildDomainItemWithContext(listContext, domain, state, credentialState);
            },
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    if (state.domains.isEmpty) {
      final selected = credentialState.selectedCredential;
      return _buildEmptyDomainState(context, selected?.providerId ?? '');
    }

    final selected = credentialState.selectedCredential;
    final driver = selected != null ? DriverFactory.get(selected.providerId) : null;
    final supportsDelete = driver?.supportsDeleteDomain ?? false;
    final supportsRenew = driver?.supportsRenewDomain ?? false;

return RefreshIndicator(
      onRefresh: () async {
        if (selected != null) {
          await state.loadDomains(selected.providerId, selected.credentials);
        }
      },
      child: ListView.builder(
        itemCount: state.domains.length,
        itemBuilder: (listContext, index) {
          final domain = state.domains[index];
          return _buildDomainItemWithContext(listContext, domain, state, credentialState);
        },
      ),
    );
  }

  Widget _buildDomainItemWithContext(
    BuildContext listContext,
    Map<String, dynamic> domain,
    DomainState state,
    CredentialState credentialState,
  ) {
    final domainName = domain['name'] ?? 'Unknown';
    final domainId = domain['id']?.toString() ?? '';
    final selected = credentialState.selectedCredential;
    final driver = selected != null ? DriverFactory.get(selected.providerId) : null;
    final supportsDelete = driver?.supportsDeleteDomain ?? false;
    final supportsRenew = driver?.supportsRenewDomain ?? false;

    return _buildDomainItem(listContext, domain, domainName, domainId, state, selected, supportsDelete, supportsRenew);
  }

  Widget _buildDomainItem(
    BuildContext? context,
    Map<String, dynamic> domain,
    String domainName,
    String domainId,
    DomainState state,
    dynamic selected,
    bool supportsDelete,
    bool supportsRenew,
  ) {
    final status = _buildDomainStatusText(domain);

    return ListTile(
      leading: Icon(
        Icons.language,
        color: Colors.blue.shade400,
      ),
      title: Text(
        domainName,
        style: const TextStyle(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: _getStatusColor(status),
        ),
        maxLines: 1,
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 20),
        onSelected: (value) => _handleDomainAction(context!, value, state, selected, domainName, domainId),
        itemBuilder: (popupContext) => [
          if (supportsDelete)
            const PopupMenuItem(value: 'delete', child: Text('删除')),
          if (supportsRenew)
            const PopupMenuItem(value: 'renew', child: Text('续期')),
        ],
      ),
      onTap: () {
        if (domainId.isNotEmpty) {
          GoRouter.of(context!).push(
            '/domains/$domainId/records?name=${Uri.encodeComponent(domainName)}',
          );
        }
      },
    );
  }

  String _buildDomainStatusText(Map<String, dynamic> domain) {
    final status = domain['status'] ?? '';
    final statusMap = {
      'active': '活跃',
      'pending': '待处理',
      'expired': '已过期',
      'suspended': '已暂停',
      'deleted': '已删除',
    };
    return statusMap[status.toString().toLowerCase()] ?? status;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '活跃':
        return Colors.green.shade600;
      case '待处理':
        return Colors.orange.shade600;
      case '已过期':
        return Colors.red.shade600;
      case '已暂停':
        return Colors.grey.shade600;
      case '已删除':
        return Colors.red.shade400;
      default:
        return Colors.grey.shade600;
    }
  }

  Future<void> _handleDomainAction(
    BuildContext context,
    String action,
    DomainState state,
    dynamic selected,
    String domainName,
    String domainId,
  ) async {
    if (action == 'delete') {
      await _deleteDomain(context, state, selected, domainName, domainId);
    } else if (action == 'renew') {
      await _renewDomain(context, state, selected, domainId);
    }
  }

  Future<void> _deleteDomain(
    BuildContext context,
    DomainState state,
    dynamic selected,
    String domainName,
    String domainId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除域名'),
        content: Text('确定要删除 "$domainName" 吗？此操作无法撤销。'),
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
      final result = await state.deleteDomain(selected.providerId, domainId);
      if (context.mounted) {
        if (result['success']) {
          ToastUtil.showSuccess(context, '域名已删除');
        } else {
          ToastUtil.showError(context, result['error'] ?? '删除失败', errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null);
        }
      }
    }
  }

  Future<void> _renewDomain(
    BuildContext context,
    DomainState state,
    dynamic selected,
    String domainId,
  ) async {
    if (selected == null) return;

    final result = await state.renewDomain(selected.providerId, domainId);
    if (context.mounted) {
      if (result['success']) {
        final msg = result['remaining_days'] != null
            ? '续期成功，剩余 ${result['remaining_days']} 天'
            : '续期成功';
        ToastUtil.showSuccess(context, msg);
      } else {
        ToastUtil.showError(context, result['error'] ?? '续期失败', errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null);
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
          ElevatedButton(
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
                ToastUtil.showError(context, result['error'] ?? '添加失败', errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null);
              } else {
                await domainState.loadDomains(
                  providerId,
                  context.read<CredentialState>().selectedCredential!.credentials,
                );
                if (context.mounted) {
                  ToastUtil.showSuccess(context, '添加成功');
                }
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCredentialState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.key_off, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              '请先添加凭证',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              '凭证用于连接DNS服务商，管理您的域名和DNS记录',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddCredentialDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('添加凭证'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDomainState(BuildContext context, String providerId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dns, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              '暂无域名',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              '暂无域名，请使用右下角按钮添加域名',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, CredentialState credentialState, DomainState domainState) {
    return Drawer(
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.dns, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  const Text('DNS管理工具', style: TextStyle(fontSize: 20, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(
                    credentialState.credentials.isNotEmpty
                        ? '已添加 ${credentialState.credentials.length} 个凭证'
                        : '未添加凭证',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: credentialState.credentials.isEmpty
                ? _buildEmptyCredentialList(context)
                : _buildCredentialList(context, credentialState, domainState),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('添加凭证'),
            onTap: () => _showAddCredentialDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCredentialList(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.key_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '暂无凭证\n点击下方按钮添加',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialList(BuildContext context, CredentialState credentialState, DomainState domainState) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: credentialState.credentials.length,
      onReorder: (oldIndex, newIndex) {
        credentialState.reorderCredentials(oldIndex, newIndex);
      },
      itemBuilder: (ctx, index) {
        final credential = credentialState.credentials[index];
        final isSelected = credentialState.selectedCredentialId == credential.id;

        return _CredentialListItem(
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
          onReorderStart: () {},
          onReorderEnd: (_) {},
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
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑凭证'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditCredentialDialog(context, credential);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除凭证', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteCredentialDialog(context, credential, credentialState);
              },
            ),
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
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除凭证'),
        content: Text('确定要删除 "${credential.providerName}" 的凭证吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await credentialState.removeCredential(credential.id);
              if (context.mounted) {
                ToastUtil.showSuccess(context, '删除凭证成功');
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CredentialListItem extends StatelessWidget {
  final int index;
  final CredentialModel credential;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onReorderStart;
  final void Function(int) onReorderEnd;

  const _CredentialListItem({
    super.key,
    required this.index,
    required this.credential,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onReorderStart,
    required this.onReorderEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => onReorderStart(),
              onHorizontalDragEnd: (_) => onReorderEnd(index),
              onLongPressStart: (_) => onLongPress(),
              child: ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Colors.green : null,
                ),
                title: Text(credential.providerName),
                subtitle: Text(
                  credential.remark != null && credential.remark!.isNotEmpty
                      ? credential.remark!
                      : credential.providerId,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: onTap,
              ),
            ),
          ),
          Listener(
            onPointerDown: (_) {},
            child: ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Icon(Icons.drag_handle, color: Colors.grey),
              ),
            ),
          ),
        ],
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud, size: 20),
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
        ElevatedButton(
          onPressed: _selectedProviderId != null && !_isValidating ? _saveCredential : null,
          child: _isValidating
              ? const SizedBox(
                  height: 20,
                  width: 20,
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
