import 'package:flutter/material.dart';
import '../../core/refresh/refresh_core.dart';
import '../../drivers/driver_factory.dart';
import '../../models/credential_model.dart';
import '../../services/credential_state.dart';
import '../../services/credential_validation.dart';
import '../../services/new_domain_state.dart';
import '../../utils/toast_util.dart';
import 'home_ux_state.dart';

class HomeUxController {
  final BuildContext context;
  final HomeUxState uxState;
  final DomainListUxState domainState;
  final CredentialState credentialState;
  final NewDomainState domainStateService;

  HomeUxController({
    required this.context,
    required this.uxState,
    required this.domainState,
    required this.credentialState,
    required this.domainStateService,
  });

  void syncFromCredentialState() {
    uxState.updateCredentials(credentialState.credentials);
    uxState.updateSelectedCredential(credentialState.selectedCredential);
  }

  Future<void> initialize() async {
    await credentialState.init();
    syncFromCredentialState();

    if (credentialState.hasSelected) {
      final selected = credentialState.selectedCredential;
      if (selected != null) {
        await _refreshDomainList(selected);
      }
    } else {
      domainState.setLoading(true);
    }
  }

  Future<void> refreshManual() async {
    final selected = credentialState.selectedCredential;
    if (selected == null) return;

    domainState.setRefreshing(true);
    final result = await domainStateService.refreshDomainList(
      providerId: selected.providerId,
      credentials: selected.credentials,
      triggerType: RefreshTriggerType.manual,
    );

    _handleRefreshResult(result);
  }

  Future<void> refreshPassive() async {
    if (credentialState.hasSelected) {
      final selected = credentialState.selectedCredential;
      if (selected != null) {
        await _refreshDomainList(selected);
      }
    }
  }

  Future<void> _refreshDomainList(CredentialModel credential) async {
    domainState.setLoading(true);
    final result = await domainStateService.refreshDomainList(
      providerId: credential.providerId,
      credentials: credential.credentials,
      triggerType: RefreshTriggerType.passive,
    );

    _handleRefreshResult(result);
  }

  void _handleRefreshResult(dynamic result) {
    if (result.success) {
      final domains = (result.data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      domainState.setDomains(domains.cast<Map<String, dynamic>>());
      domainState.clearError();
    } else {
      domainState.setError(result.error, result.errorCode);
    }
    domainState.setLoading(false);
    domainState.setRefreshing(false);
  }

  void showDeleteDomainDialog(String domainName, String domainId) {
    final selected = credentialState.selectedCredential;
    if (selected == null) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          bool isDeleting = false;
          return AlertDialog(
            title: Text(_getLocalizedString('delete_domain_title')),
            content: Text(_getLocalizedString('delete_domain_message', domainName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(_getLocalizedString('cancel')),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  foregroundColor: Theme.of(dialogContext).colorScheme.onError,
                ),
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        final result = await domainStateService.deleteDomain(
                          selected.providerId,
                          domainId,
                          selected.credentials,
                        );
                        if (dialogContext.mounted) {
                          if (result['success'] == true) {
                            Navigator.pop(dialogContext);
                            ToastUtil.showSuccess(context, _getLocalizedString('domain_deleted'));
                            await _refreshDomainList(selected);
                          } else {
                            Navigator.pop(dialogContext);
                            final errorMsg = result['error']?.toString() ?? '';
                            ToastUtil.showError(
                              context,
                              errorMsg,
                              errorCode: result['errorCode'] != null
                                  ? double.tryParse(result['errorCode'].toString())
                                  : null,
                            );
                            domainState.setLoading(false);
                          }
                        }
                      },
                child: isDeleting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_getLocalizedString('delete')),
              ),
            ],
          );
        },
      ),
    );
  }

  void showRenewDomainDialog(String domainName, String domainId) {
    final selected = credentialState.selectedCredential;
    if (selected == null) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          bool isRenewing = false;
          return AlertDialog(
            title: Text(_getLocalizedString('renew_domain_title')),
            content: Text(_getLocalizedString('renew_domain_message', domainName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(_getLocalizedString('cancel')),
              ),
              FilledButton(
                onPressed: isRenewing
                    ? null
                    : () async {
                        setDialogState(() => isRenewing = true);
                        final result = await domainStateService.renewDomain(
                          selected.providerId,
                          domainId,
                          selected.credentials,
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          if (result['success'] == true) {
                            final remainingDays = result['remaining_days'];
                            final msg = remainingDays != null
                                ? '续期成功，剩余 $remainingDays 天'
                                : _getLocalizedString('renew_success');
                            ToastUtil.showSuccess(context, msg);
                            await _refreshDomainList(selected);
                          } else {
                            final errorMsg = result['error']?.toString() ?? '';
                            ToastUtil.showError(
                              context,
                              errorMsg,
                              errorCode: result['errorCode'] != null
                                  ? double.tryParse(result['errorCode'].toString())
                                  : null,
                            );
                            domainState.setLoading(false);
                          }
                        }
                      },
                child: isRenewing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_getLocalizedString('renew')),
              ),
            ],
          );
        },
      ),
    );
  }

  void showAddDomainDialog(String providerId, Function(Map<String, dynamic>) onSubmit) {
    final driver = DriverFactory.get(providerId);
    if (driver == null) return;

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
          return AlertDialog(
            title: Text(driver.getAddDomainTitle()),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...fields.map((field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: controllers[field.key],
                        decoration: InputDecoration(
                          labelText: field.label,
                          hintText: field.hintText,
                        ),
                      ),
                      if (field.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          field.description!,
                          style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                            color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  )),
                  if (hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, size: 16, color: Theme.of(dialogContext).colorScheme.error),
                          const SizedBox(width: 4),
                          Text(
                            _getLocalizedString('fill_required_fields'),
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
                child: Text(_getLocalizedString('cancel')),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
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
                        Navigator.pop(dialogContext);
                        onSubmit(domainData);
                      },
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_getLocalizedString('add')),
              ),
            ],
          );
        },
      ),
    );
  }

  void showCredentialBottomSheet(CredentialModel credential, VoidCallback onSelect, VoidCallback onEdit, VoidCallback onDelete) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: EdgeInsets.only(top: MediaQuery.of(ctx).padding.top),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: Theme.of(ctx).colorScheme.primary),
              title: Text(_getLocalizedString('select_credential')),
              onTap: () {
                Navigator.pop(ctx);
                onSelect();
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Theme.of(ctx).colorScheme.primary),
              title: Text(_getLocalizedString('edit_credential')),
              onTap: () {
                Navigator.pop(ctx);
                onEdit();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Theme.of(ctx).colorScheme.error),
              title: Text(_getLocalizedString('delete_credential'), style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Future<void> _validateAndSaveCredential(String providerId, Map<String, String> credentials, String? remark, Function(CredentialModel) onSave) async {
    final driver = DriverFactory.get(providerId);
    if (driver == null) return;

    final result = await CredentialValidationService.validateCredential(providerId, credentials);
    if (!result['success']) {
      if (context.mounted) {
        ToastUtil.showError(
          context,
          result['error']?.toString() ?? '',
          errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode'].toString()) : null,
        );
      }
      return;
    }

    final credential = CredentialModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      providerId: providerId.toLowerCase(),
      providerName: driver.providerName,
      remark: remark,
      credentials: credentials,
      createdAt: DateTime.now(),
    );

    onSave(credential);
  }

  String _getLocalizedString(String key, [String? arg]) {
    final strings = {
      'delete_domain_title': '删除域名',
      'delete_domain_message': '确定要删除 "%s" 吗？此操作无法撤销。',
      'domain_deleted': '域名已删除',
      'renew_domain_title': '续期域名',
      'renew_domain_message': '确定要续期 "%s" 吗？',
      'renew_success': '续期成功',
      'cancel': '取消',
      'delete': '删除',
      'renew': '续期',
      'add': '添加',
      'fill_required_fields': '请填写所有必填项',
      'select_credential': '选择此凭证',
      'edit_credential': '编辑凭证',
      'delete_credential': '删除凭证',
    };

    var text = strings[key] ?? key;
    if (arg != null) {
      text = text.replaceAll('%s', arg);
    }
    return text;
  }
}