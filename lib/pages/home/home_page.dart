import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dp/generated/l10n/app_localizations.dart';
import '../../services/credential_state.dart';
import '../../services/credential_storage.dart';
import '../../services/credential_validation.dart';
import '../../services/new_domain_state.dart';
import '../../services/refresh_helper.dart';
import '../../drivers/driver_factory.dart';
import '../../core/localization/driver_localizations.dart';
import '../../utils/toast_util.dart';
import '../../core/ui/md3_widgets.dart';
import '../../core/theme/design_system.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final credentialState = context.read<CredentialState>();
      await credentialState.init();
      if (mounted) {
        if (credentialState.hasSelected) {
          final selected = credentialState.selectedCredential;
          if (selected != null) {
            await RefreshHelper.refreshDomainListPassiveWithCredential(
              context,
              providerId: selected.providerId,
              credentials: selected.credentials,
            );
          }
        } else {
          await RefreshHelper.refreshDomainListPassive(context);
        }
      }
    });
  }

  Future<void> _pullToRefresh() async {
    await RefreshHelper.refreshDomainListManual(context);
  }

  @override
  Widget build(BuildContext context) {
    final credentialState = context.watch<CredentialState>();
    final domainState = context.watch<NewDomainState>();
    final selected = credentialState.selectedCredential;
    final hasCredentials = credentialState.hasCredentials;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(hasCredentials ? (selected?.providerName ?? AppLocalizations.of(context)!.appNavTitle) : AppLocalizations.of(context)!.appNavTitle),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: hasCredentials
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    await RefreshHelper.refreshDomainListPassive(context);
                  },
                ),
              ]
            : null,
      ),
      drawer: _buildDrawer(context, credentialState, domainState),
      body: _buildBody(context, domainState, credentialState, hasCredentials),
      floatingActionButton:
          hasCredentials ? _buildFab(context, selected!.providerId) : null,
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
    NewDomainState state,
    CredentialState credentialState,
    bool hasCredentials,
  ) {
    if (!hasCredentials) return _buildEmptyCredentialState(context);

    if (state.isManualRefreshing) {
      return RefreshIndicator(
        key: _refreshKey,
        onRefresh: _pullToRefresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: DnsSpacing.sm),
          itemCount: 0,
          separatorBuilder: (_, __) => const DnsDivider(),
          itemBuilder: (_, __) => const SizedBox.shrink(),
        ),
      );
    }

    if (state.isLoading && state.domains.isEmpty) {
      return const DnsLoading();
    }

    if (state.error != null && state.domains.isEmpty) {
      return DnsErrorState(
        message: state.error!,
        onRetry: () {
          final selected = credentialState.selectedCredential;
          if (selected != null) {
            RefreshHelper.refreshDomainListPassiveWithCredential(
              context,
              providerId: selected.providerId,
              credentials: selected.credentials,
            );
          }
        },
      );
    }

    final isLoading = state.loadingState == LoadingState.loading;
    if (isLoading && state.domains.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final showCenterLoading = state.showCenterLoading;
    if (showCenterLoading) {
      return Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      );
    }

    if (state.domains.isEmpty) {
      return Stack(
        children: [
          RefreshIndicator(
            key: _refreshKey,
            onRefresh: _pullToRefresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: DnsSpacing.sm),
              itemCount: 0,
              separatorBuilder: (_, __) => const DnsDivider(),
              itemBuilder: (_, __) => const SizedBox.shrink(),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: _buildEmptyDomainState(context),
            ),
          ),
        ],
      );
    }

    final selected = credentialState.selectedCredential;
    final driver = selected != null ? DriverFactory.get(selected.providerId) : null;
    final supportsDelete = driver?.supportsDeleteDomain ?? false;
    final supportsRenew = driver?.supportsRenewDomain ?? false;
    final supportsShowNameServers = driver?.supportsShowNameServers ?? false;

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _pullToRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: DnsSpacing.sm),
        itemCount: state.domains.length,
        separatorBuilder: (_, __) => const DnsDivider(),
        itemBuilder: (listContext, index) {
          final domain = state.domains[index];
          return _DomainListItem(
            key: ValueKey(domain['id']?.toString() ?? index),
            domain: domain,
            supportsDelete: supportsDelete,
            supportsRenew: supportsRenew,
            supportsShowNameServers: supportsShowNameServers,
            onTap: () {
              final domainId = domain['id']?.toString() ?? '';
              final domainName = domain['name']?.toString() ?? '';
              if (domainId.isNotEmpty) {
                GoRouter.of(context).push(
                  '/domains/$domainId/records?name=${Uri.encodeComponent(domainName)}',
                );
              }
            },
            onDelete: state.isOperating ? () {} : () => _handleDeleteDomain(context, state, selected, domain),
            onRenew: state.isOperating ? () {} : () => _handleRenewDomain(context, state, selected, domain),
          );
        },
      ),
    );
  }

  void _handleDeleteDomain(BuildContext context, NewDomainState state, dynamic selected, Map<String, dynamic> domain) {
    final domainName = domain['name']?.toString() ?? '';
    final domainId = domain['id']?.toString() ?? '';
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l10n.domainDeleteTitle),
            content: Text(l10n.domainDeleteConfirm(domainName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  foregroundColor: Theme.of(dialogContext).colorScheme.onError,
                ),
                onPressed: isDeleting
                    ? null
                    : () async {
                        if (selected == null) return;
                        setDialogState(() => isDeleting = true);
                        final result = await state.deleteDomain(
                          selected.providerId,
                          domainId,
                          selected.credentials,
                        );
                        if (dialogContext.mounted) {
                          final driver = DriverFactory.get(selected.providerId);
                          final errorMsg = result['error']?.toString() ?? '';
                          if (result['success'] == true) {
                            Navigator.pop(dialogContext);
                            ToastUtil.showSuccess(context, AppLocalizations.of(context)!.toastDomainDeleted);
                          } else {
                            Navigator.pop(dialogContext);
                            ToastUtil.showError(context, errorMsg ?? '', errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode'].toString()) : null);
                          }
                        }
                      },
                      child: isDeleting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(AppLocalizations.of(context)!.commonDelete),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleRenewDomain(BuildContext context, NewDomainState state, dynamic selected, Map<String, dynamic> domain) {
    final domainName = domain['name']?.toString() ?? '';
    final domainId = domain['id']?.toString() ?? '';
    bool isRenewing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l10n.domainRenewTitle),
            content: Text(l10n.domainRenewConfirm(domainName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: isRenewing
                    ? null
                    : () async {
                        setDialogState(() => isRenewing = true);
                        final result = await state.renewDomain(
                          selected.providerId,
                          domainId,
                          selected.credentials,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          if (result['success'] == true) {
                            final msg = result['remaining_days'] != null
                                ? l10n.toastDomainRenewed(result['remaining_days'])
                                : l10n.toastDomainRenewedSimple;
                            ToastUtil.showSuccess(context, msg);
                          } else {
                            final driver = DriverFactory.get(selected.providerId);
                            final errorMsg = result['error']?.toString() ?? '';
                            ToastUtil.showError(context, errorMsg ?? '', errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode'].toString()) : null);
                          }
                        }
                      },
                child: isRenewing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10n.commonRenew),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddDomainDialog(BuildContext context, String providerId) {
    final driver = DriverFactory.get(providerId);
    if (driver == null) return;
    final domainState = context.read<NewDomainState>();
    final fields = driver.getAddDomainFields();
    final controllers = <String, TextEditingController>{};
    for (final field in fields) {
      controllers[field.key] = TextEditingController();
    }
    bool isSubmitting = false;
    bool hasError = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final bool canSubmit = !isSubmitting && !hasError;

          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(DriverLocalizations.addDomainTitle(context, driver)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...fields.map((field) {
                    final label = DriverLocalizations.fieldLabel(l10n, driver.providerId, field.key, field.label);
                    final hintText = DriverLocalizations.fieldHint(l10n, driver.providerId, field.key, field.hintText);
                    final description = field.description != null
                        ? DriverLocalizations.fieldDesc(l10n, driver.providerId, field.key, field.description!)
                        : null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: controllers[field.key],
                          decoration: InputDecoration(labelText: label, hintText: hintText),
                          onChanged: (_) {
                            if (hasError) setDialogState(() => hasError = false);
                          },
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                              color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                  if (hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, size: 16, color: Theme.of(dialogContext).colorScheme.error),
                          const SizedBox(width: 4),
                          Text(
                            l10n.domainAddDialogRequired,
                            style: TextStyle(
                              color: Theme.of(dialogContext).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: canSubmit
                    ? () async {
                        final inputData = <String, dynamic>{};
                        bool hasEmpty = false;
                        for (final field in fields) {
                          final value = controllers[field.key]?.text ?? '';
                          inputData[field.key] = value;
                          if (field.required && value.isEmpty) hasEmpty = true;
                        }
                        if (hasEmpty) {
                          setDialogState(() => hasError = true);
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          hasError = false;
                        });
                        final domainData = driver.prepareDomainData(inputData);
                        final result = await domainState.addDomain(
                          providerId,
                          domainData,
                          context.read<CredentialState>().selectedCredential!.credentials,
                        );
                        if (dialogContext.mounted) {
                          final errorMsg = result['error']?.toString() ?? '';
                          if (result['success'] == true) {
                            Navigator.pop(dialogContext);
                            ToastUtil.showSuccess(context, l10n.toastDomainAdded);
                          } else {
                            Navigator.pop(dialogContext);
                            ToastUtil.showError(context, errorMsg ?? '', errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode'].toString()) : null);
                          }
                        }
                      }
                    : null,
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10n.commonAdd),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCredentialState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DnsEmptyState(
      icon: Icons.key_off,
      title: l10n.credentialEmptyTitle,
      description: l10n.credentialEmptyDesc,
      action: FilledButton.icon(
        onPressed: () => _showAddCredentialDialog(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.credentialAdd),
      ),
    );
  }

  Widget _buildEmptyDomainState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DnsEmptyState(
      icon: Icons.dns,
      title: l10n.domainEmptyTitle,
      description: l10n.domainEmptyDesc,
    );
  }

  Widget _buildDrawer(BuildContext context, CredentialState credentialState, NewDomainState domainState) {
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
      surfaceTintColor: colorScheme.surfaceTint,
      child: Column(
        children: [
          _DrawerHeader(credentialCount: credentialState.credentials.length),
          Expanded(
            child: credentialState.credentials.isEmpty
                ? _buildEmptyCredentialList(context)
                : _buildCredentialList(context, credentialState, domainState),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showAddCredentialDialog(context),
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.credentialAdd),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: _DrawerSettingsEntry(onTap: () {
              Navigator.pop(context);
              GoRouter.of(context).push('/settings');
            }),
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
              AppLocalizations.of(context)!.credentialEmptyListTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.credentialEmptyListDesc,
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

  Widget _buildCredentialList(BuildContext context, CredentialState credentialState, NewDomainState domainState) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      itemCount: credentialState.credentials.length,
      onReorder: (oldIndex, newIndex) => credentialState.reorderCredentials(oldIndex, newIndex),
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (ctx, child) {
            final animValue = Curves.easeInOut.transform(animation.value);
            final scale = 1.0 + (animValue * 0.04);
            final shadowAlpha = animValue * 0.2;
            return Transform.scale(
              scale: scale,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(DnsRadius.lg),
                elevation: 8,
                shadowColor: Theme.of(ctx).colorScheme.shadow.withValues(alpha: shadowAlpha),
                child: child,
              ),
            );
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
          credential: credential,
          isSelected: isSelected,
          onTap: () => _showCredentialBottomSheet(ctx, credential, credentialState, domainState),
        );
      },
    );
  }

  void _showCredentialBottomSheet(
    BuildContext ctx,
    CredentialModel credential,
    CredentialState credentialState,
    NewDomainState domainState,
  ) {
    DnsBottomSheet.show(
      context: ctx,
      title: credential.providerName,
      children: [
        ListTile(
          leading: Icon(Icons.check_circle, color: Theme.of(ctx).colorScheme.primary),
          title: Text(AppLocalizations.of(ctx)!.credentialSelect),
          onTap: () async {
            Navigator.pop(ctx);
            credentialState.selectCredential(credential.id);
            await RefreshHelper.refreshDomainListPassiveWithCredential(
              context,
              providerId: credential.providerId,
              credentials: credential.credentials,
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.edit, color: Theme.of(ctx).colorScheme.primary),
          title: Text(AppLocalizations.of(ctx)!.credentialEdit),
          onTap: () {
            Navigator.pop(ctx);
            _showEditCredentialDialog(context, credential);
          },
        ),
        ListTile(
          leading: Icon(Icons.delete, color: Theme.of(ctx).colorScheme.error),
          title: Text(AppLocalizations.of(ctx)!.credentialDelete, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          onTap: () {
            Navigator.pop(ctx);
            _showDeleteCredentialDialog(context, credential, credentialState);
          },
        ),
      ],
    );
  }

  void _showAddCredentialDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _CredentialDialog(
        title: AppLocalizations.of(context)!.credentialDialogTitle,
        onSave: (credential) async {
          final credentialState = context.read<CredentialState>();
          await credentialState.addCredential(credential);
          ToastUtil.showSuccess(context, AppLocalizations.of(context)!.toastCredentialAdded);
          Navigator.pop(ctx);
          await Future.delayed(const Duration(milliseconds: 300));
          if (context.mounted) {
            final newSelected = credentialState.selectedCredential;
            if (newSelected != null) {
              RefreshHelper.refreshDomainListPassiveWithCredential(
                context,
                providerId: newSelected.providerId,
                credentials: newSelected.credentials,
              );
            }
          }
        },
      ),
    );
  }

  void _showEditCredentialDialog(BuildContext context, CredentialModel credential) {
    showDialog(
      context: context,
      builder: (ctx) => _CredentialDialog(
        title: AppLocalizations.of(context)!.credentialDialogEditTitle,
        credential: credential,
        onSave: (updatedCredential) async {
          final credentialState = context.read<CredentialState>();
          final selected = credentialState.selectedCredential;
          await credentialState.updateCredential(updatedCredential);
          ToastUtil.showSuccess(context, AppLocalizations.of(context)!.toastCredentialUpdated);
          Navigator.pop(ctx);
          await Future.delayed(const Duration(milliseconds: 300));
          if (context.mounted && selected != null && selected.id == updatedCredential.id) {
            RefreshHelper.refreshDomainListPassiveWithCredential(
              context,
              providerId: updatedCredential.providerId,
              credentials: updatedCredential.credentials,
            );
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
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDnsConfirmDialog(
      context,
      title: l10n.credentialDelete,
      message: '${l10n.credentialDelete} "${credential.providerName}"?',
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );
    if (confirm == true && context.mounted) {
      final wasSelected = credentialState.selectedCredentialId == credential.id;
      await credentialState.removeCredential(credential.id);
      if (context.mounted) {
        ToastUtil.showSuccess(context, l10n.toastCredentialDeleted);
        if (wasSelected) {
          final newSelected = credentialState.selectedCredential;
          if (newSelected != null) {
            await RefreshHelper.refreshDomainListPassiveWithCredential(
              context,
              providerId: newSelected.providerId,
              credentials: newSelected.credentials,
            );
          }
        }
      }
    }
  }
}

class _DrawerHeader extends StatelessWidget {
  final int credentialCount;
  const _DrawerHeader({required this.credentialCount});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
      ),
      padding: EdgeInsets.fromLTRB(
        DnsSpacing.lg,
        DnsSpacing.md + topPadding,
        DnsSpacing.lg,
        DnsSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(DnsRadius.md),
            ),
            child: Icon(Icons.dns, size: 26, color: colorScheme.onPrimary),
          ),
          const SizedBox(width: DnsSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.drawerTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  credentialCount > 0
                      ? AppLocalizations.of(context)!.drawerCredentials(credentialCount)
                      : AppLocalizations.of(context)!.drawerNoCredentials,
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

class _DrawerSettingsEntry extends StatelessWidget {
  final VoidCallback onTap;
  const _DrawerSettingsEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DnsRadius.lg),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(DnsRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DnsRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DnsSpacing.md,
              vertical: DnsSpacing.sm + 4,
            ),
            child: Row(
              children: [
                Icon(Icons.settings_outlined, size: 20, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: DnsSpacing.md),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.navSettings,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DomainListItem extends StatelessWidget {
  final Map<String, dynamic> domain;
  final bool supportsDelete;
  final bool supportsRenew;
  final bool supportsShowNameServers;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRenew;

  const _DomainListItem({
    super.key,
    required this.domain,
    required this.supportsDelete,
    required this.supportsRenew,
    required this.supportsShowNameServers,
    required this.onTap,
    required this.onDelete,
    required this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    return DnsDomainTile(
      domain: domain,
      supportsDelete: supportsDelete,
      supportsRenew: supportsRenew,
      supportsShowNameServers: supportsShowNameServers,
      onTap: onTap,
      onDelete: onDelete,
      onRenew: onRenew,
    );
  }
}

class _CredentialCard extends StatelessWidget {
  final int index;
  final CredentialModel credential;
  final bool isSelected;
  final VoidCallback onTap;

  const _CredentialCard({
    super.key,
    required this.index,
    required this.credential,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      child: _CredentialCardContent(
        credential: credential,
        isSelected: isSelected,
        onTap: onTap,
      ),
    );
  }
}

class _CredentialCardContent extends StatelessWidget {
  final CredentialModel credential;
  final bool isSelected;
  final VoidCallback onTap;

  const _CredentialCardContent({
    required this.credential,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: DnsSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DnsRadius.lg),
        border: Border.all(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(DnsRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DnsRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DnsSpacing.md,
              vertical: DnsSpacing.sm + 4,
            ),
            child: Row(
              children: [
                _buildProviderIcon(colorScheme),
                const SizedBox(width: DnsSpacing.md),
                Expanded(child: _buildInfo(colorScheme)),
                Icon(Icons.chevron_right, size: 20, color: colorScheme.onSurfaceVariant),
              ],
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
      iconWidget = SvgPicture.asset(iconPath, width: 20, height: 20);
    } else {
      iconWidget = Image.asset(
        iconPath,
        width: 20,
        height: 20,
        errorBuilder: (_, __, ___) => Icon(Icons.language, size: 20, color: colorScheme.onSurfaceVariant),
      );
    }
    return ClipOval(child: SizedBox(width: 20, height: 20, child: iconWidget));
  }

  Widget _buildInfo(ColorScheme colorScheme) {
    final hasRemark = credential.remark != null && credential.remark!.isNotEmpty;
    final nameStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colorScheme.onSurface);
    if (hasRemark) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(credential.remark!, style: nameStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            credential.providerName,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
    return Text(credential.providerName, style: nameStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}

class _CredentialDialog extends StatefulWidget {
  final String title;
  final CredentialModel? credential;
  final Function(CredentialModel) onSave;

  const _CredentialDialog({required this.title, this.credential, required this.onSave});

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

    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isEditing) ...[
              DropdownButtonFormField<String>(
                value: _selectedProviderId,
                decoration: InputDecoration(
                  labelText: l10n.credentialProvider,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DnsRadius.md),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                isExpanded: true,
                items: drivers.map((d) => DropdownMenuItem(value: d.providerId, child: Text(d.providerName))).toList(),
                onChanged: (value) => setState(() {
                  _selectedProviderId = value;
                  _controllers.clear();
                }),
              ),
              const SizedBox(height: 12),
            ],
            if (isEditing) ...[
              IgnorePointer(
                child: DropdownButtonFormField<String>(
                  value: _selectedProviderId,
                  decoration: InputDecoration(
                    labelText: l10n.credentialProviderReadonly,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DnsRadius.md),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  isExpanded: true,
                  items: drivers.map((d) => DropdownMenuItem(value: d.providerId, child: Text(d.providerName))).toList(),
                  onChanged: null,
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _remarkController,
              decoration: InputDecoration(labelText: l10n.credentialRemarkLabel, hintText: l10n.credentialRemarkHint),
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
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
        FilledButton(
          onPressed: _selectedProviderId != null && !_isValidating ? _saveCredential : null,
          child: _isValidating
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.commonSave),
        ),
      ],
    );
  }

  Widget _buildCredentialFields() {
    final driver = DriverFactory.get(_selectedProviderId!);
    if (driver == null) return const SizedBox.shrink();
    final fields = driver.getCredentialFields();
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: fields.entries.map((entry) {
        _controllers[entry.key] = _controllers[entry.key] ?? TextEditingController();
        final label = l10n != null
            ? DriverLocalizations.credentialFieldLabel(l10n, driver.providerId, entry.key, entry.value)
            : entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _controllers[entry.key],
            decoration: InputDecoration(labelText: label),
            obscureText: entry.key.toLowerCase().contains('secret'),
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
      if (value != null && value.isNotEmpty) credentials[key] = value;
    }
    if (credentials.isEmpty) {
      ToastUtil.showError(context, AppLocalizations.of(context)!.credentialFillKeys, errorCode: 400);
      return;
    }
    setState(() => _isValidating = true);
    final result = await CredentialValidationService.validateCredential(_selectedProviderId!, credentials);
    if (!result['success']) {
      setState(() => _isValidating = false);
      if (mounted) {
        final errorMsg = result['error']?.toString() ?? '';
        ToastUtil.showError(context, errorMsg ?? '', errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode'].toString()) : null);
      }
      return;
    }
    final remark = _remarkController.text.trim();
    if (widget.credential != null) {
      final updated = widget.credential!.copyWith(
        providerId: _selectedProviderId!.toLowerCase(),
        providerName: driver.providerName,
        remark: remark.isEmpty ? null : remark,
        credentials: credentials,
      );
      await widget.onSave(updated);
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
