import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
          await state.refreshDomains(selected.providerId, selected.credentials);
          if (context.mounted) ToastUtil.showSuccess(context, '域名已删除');
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
      surfaceTintColor: colorScheme.surfaceTint,
      child: Column(
        children: [
          _DrawerHeader(
            credentialCount: credentialState.credentials.length,
          ),
          Expanded(
            child: credentialState.credentials.isEmpty
                ? _buildEmptyCredentialList(context)
                : _buildCredentialList(context, credentialState, domainState),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  _showAddCredentialDialog(context);
                },
                icon: const Icon(Icons.add),
                label: const Text('添加凭证'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCredentialList(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DnsSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.key_off,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无凭证',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '点击下方按钮添加',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialList(
    BuildContext context,
    CredentialState credentialState,
    DomainState domainState,
  ) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: credentialState.credentials.length,
      onReorder: (oldIndex, newIndex) {
        credentialState.reorderCredentials(oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (ctx, child) {
            final animValue = Curves.easeInOut.transform(animation.value);
            final scale = 1.0 + (animValue * 0.04);
            final shadowAlpha = animValue * 0.2;
            return Transform.scale(scale: scale, child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(DnsRadius.lg),
              elevation: 8,
              shadowColor: Theme.of(ctx).colorScheme.shadow.withValues(alpha: shadowAlpha),
              child: child,
            ));
          },
          child: child,
        );
      },
      itemBuilder: (ctx, index) {
        final credential = credentialState.credentials[index];
        final isSelected = credentialState.selectedCredentialId == credential.id;

        return _CredentialCard(
          key: ValueKey(credential.id),
          index: index,
          totalCount: credentialState.credentials.length,
          credential: credential,
          isSelected: isSelected,
          onTap: () {
            credentialState.selectCredential(credential.id);
            domainState.clear();
            domainState.loadDomains(credential.providerId, credential.credentials);
            Navigator.pop(ctx);
          },
          onLongPress: () {
            _showCredentialBottomSheet(ctx, credential, credentialState);
          },
        );
      },
    );
  }

  void _showCredentialBottomSheet(
    BuildContext context,
    CredentialModel credential,
    CredentialState credentialState,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: false,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(DnsSpacing.md, DnsSpacing.lg, DnsSpacing.md, DnsSpacing.md),
              child: Text(
                credential.providerName,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Theme.of(ctx).colorScheme.primary),
              title: const Text('编辑凭证'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditCredentialDialog(context, credential);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(ctx).colorScheme.error),
              title: Text('删除凭证', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                _showDeleteCredentialDialog(context, credential, credentialState);
              },
            ),
            const SizedBox(height: DnsSpacing.md),
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
            final newSelected = credentialState.selectedCredential;
            if (newSelected != null) {
              context.read<DomainState>().clear();
              context.read<DomainState>().loadDomains(
                newSelected.providerId,
                newSelected.credentials,
              );
            }
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

class _DrawerHeader extends StatelessWidget {
  final int credentialCount;

  const _DrawerHeader({required this.credentialCount});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        DnsSpacing.md,
        DnsSpacing.md + MediaQuery.of(context).padding.top,
        DnsSpacing.sm,
        DnsSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(DnsRadius.md),
            ),
            child: Icon(Icons.dns, size: 24, color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: DnsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DNS管理工具',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  credentialCount > 0
                      ? '$credentialCount 个凭证'
                      : '未添加凭证',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialCard extends StatefulWidget {
  final int index;
  final int totalCount;
  final CredentialModel credential;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CredentialCard({
    super.key,
    required this.index,
    required this.totalCount,
    required this.credential,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_CredentialCard> createState() => _CredentialCardState();
}

class _CredentialCardState extends State<_CredentialCard> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ReorderableDragStartListener(
      index: widget.index,
      child: _DragAwareCredentialCard(
        credential: widget.credential,
        isSelected: widget.isSelected,
        isDragging: _isDragging,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onDragStart: () => setState(() => _isDragging = true),
        onDragEnd: () => setState(() => _isDragging = false),
      ),
    );
  }
}

class _DragAwareCredentialCard extends StatelessWidget {
  final CredentialModel credential;
  final bool isSelected;
  final bool isDragging;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDragStart;
  final VoidCallback onDragEnd;

  const _DragAwareCredentialCard({
    required this.credential,
    required this.isSelected,
    required this.isDragging,
    required this.onTap,
    required this.onLongPress,
    required this.onDragStart,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedScale(
      scale: isDragging ? 1.03 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(DnsRadius.lg),
          border: Border.all(
            color: isDragging
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isDragging ? 2 : 1,
          ),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.04),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  )
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(DnsRadius.lg),
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(DnsRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(DnsSpacing.md),
              child: Row(
                children: [
                  _buildProviderIcon(colorScheme),
                  const SizedBox(width: DnsSpacing.md),
                  Expanded(child: _buildInfo(colorScheme)),
                  _buildDragHandle(colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderIcon(ColorScheme colorScheme) {
    final driver = DriverFactory.get(credential.providerId);
    final iconPath = driver?.providerIcon ?? '';

    Widget iconWidget;
    if (iconPath.endsWith('.svg')) {
      iconWidget = SvgPicture.asset(
        iconPath,
        width: 32,
        height: 32,
      );
    } else {
      iconWidget = Image.asset(
        iconPath,
        width: 32,
        height: 32,
        errorBuilder: (_, __, ___) => Icon(
          Icons.language,
          size: 28,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: ClipOval(
        child: SizedBox(
          width: 36,
          height: 36,
          child: iconWidget,
        ),
      ),
    );
  }

  Widget _buildLeadingIndicator(ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.12)
            : colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Icon(
        isSelected ? Icons.check : Icons.circle_outlined,
        size: 18,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildInfo(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          credential.providerName,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (credential.remark != null && credential.remark!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            credential.remark!,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildDragHandle(ColorScheme colorScheme) {
    return Listener(
      onPointerDown: (_) => onDragStart(),
      onPointerUp: (_) => onDragEnd(),
      onPointerCancel: (_) => onDragEnd(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(DnsRadius.sm),
        ),
        child: Icon(
          Icons.drag_indicator,
          size: 18,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isEditing) ...[
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(DnsRadius.md),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String>(
                  value: _selectedProviderId,
                  decoration: InputDecoration(
                    labelText: '选择服务商',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: false,
                  ),
                  isExpanded: true,
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
              ),
              const SizedBox(height: 12),
            ],
            if (isEditing) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(DnsRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(widget.credential!.providerName),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _remarkController,
              decoration: InputDecoration(
                labelText: '备注（可选）',
                hintText: '用于区分不同凭证',
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedProviderId != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildCredentialFields(),
              ),
            ],
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

  Widget _buildCredentialFields() {
    final driver = DriverFactory.get(_selectedProviderId!);
    if (driver == null) return const SizedBox.shrink();

    final fields = driver.getCredentialFields();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: fields.entries.map((entry) {
        final key = entry.key;
        final label = entry.value;
        _controllers[key] = _controllers[key] ?? TextEditingController();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _controllers[key],
            decoration: InputDecoration(labelText: label),
            obscureText: key.toLowerCase().contains('secret'),
          ),
        );
      }).toList(),
    );
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
