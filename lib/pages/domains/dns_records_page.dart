import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dp/generated/l10n/app_localizations.dart';
import '../../services/credential_state.dart';
import '../../services/new_domain_state.dart';
import '../../services/refresh_helper.dart';
import '../../drivers/driver_factory.dart';
import '../../drivers/dnshe/index.dart' as dnshe_driver;
import '../../core/localization/driver_localizations.dart';
import '../../utils/toast_util.dart';
import '../../core/ui/md3_widgets.dart';
import '../../core/theme/design_system.dart';

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
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await RefreshHelper.refreshDnsRecordListPassive(
          context,
          domainId: widget.domainId,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _autoLoadRecords() async {
    await RefreshHelper.refreshDnsRecordListPassive(
      context,
      domainId: widget.domainId,
    );
  }

  Future<void> _pullToRefresh() async {
    await RefreshHelper.refreshDnsRecordListManual(
      context,
      domainId: widget.domainId,
    );
  }

  void _showAddRecordDialog(BuildContext context, String providerId) {
    final driver = DriverFactory.get(providerId);
    if (driver == null) return;

    if (providerId == 'dnshe' && driver is dnshe_driver.DnsheDriver) {
      final domainState = context.read<NewDomainState>();
      final credentialState = context.read<CredentialState>();
      final credentials = credentialState.selectedCredential?.credentials ?? {};

      driver.showAddRecordDialog(
        context,
        domainId: widget.domainId,
        onSubmit: (recordData) async {
          final result = await domainState.createDnsRecord(
            providerId,
            widget.domainId,
            recordData,
            credentials,
          );

          if (result['success'] == true) {
            if (context.mounted) {
              ToastUtil.showSuccess(context, AppLocalizations.of(context)!.toastDnsRecordAdded);
            }
          }

          return result;
        },
      );
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final domainState = context.read<NewDomainState>();
    final credentialState = context.read<CredentialState>();
    final credentials = credentialState.selectedCredential?.credentials ?? {};

    String selectedType = driver.getSupportedRecordTypes().first;
    final fieldControllers = <String, TextEditingController>{};
    final fieldValues = <String, String>{};
    bool proxied = false;
    String? priorityValue;
    bool isSubmitting = false;
    bool hasError = false;

    void initControllers() {
      for (final field in driver.getAddRecordFields()) {
        fieldControllers[field.key] = TextEditingController(text: field.initialValue ?? '');
        fieldValues[field.key] = field.initialValue ?? '';
      }
      if (driver.supportsProxy) {
        proxied = false;
      }
    }

    initControllers();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final fields = driver.getAddRecordFields();

          return AlertDialog(
            title: Text(DriverLocalizations.addRecordTitle(context, driver)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(labelText: l10n.dnsRecordType),
                    items: driver.getSupportedRecordTypes().map((t) =>
                      DropdownMenuItem(value: t, child: Text(t))
                    ).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedType = v);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ...fields.map((field) {
                    final label = DriverLocalizations.fieldLabel(l10n, driver.providerId, field.key, field.label);
                    final hintText = DriverLocalizations.fieldHint(l10n, driver.providerId, field.key, field.hintText);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: fieldControllers[field.key],
                        decoration: InputDecoration(
                          labelText: label,
                          hintText: hintText,
                        ),
                        keyboardType: field.keyboardType,
                        onChanged: (v) => fieldValues[field.key] = v,
                      ),
                    );
                  }),
                  if (selectedType == 'MX' || selectedType == 'SRV') ...[
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        labelText: selectedType == 'MX' ? l10n.dnsRecordPriority : l10n.dnsRecordWeight,
                        hintText: l10n.dnsRecordPriorityHint,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => priorityValue = v,
                    ),
                  ],
                  if (driver.supportsProxy && (selectedType == 'A' || selectedType == 'AAAA' || selectedType == 'CNAME')) ...[
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.dnsRecordProxy),
                      subtitle: Text(l10n.dnsRecordProxyHint),
                      value: proxied,
                      onChanged: (v) => setDialogState(() => proxied = v),
                    ),
                  ],
                  if (driver.supportsRecordLine()) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: fieldValues['line'] ?? 'DEFAULT',
                      decoration: InputDecoration(labelText: l10n.dnsRecordLine),
                      items: [
                        DropdownMenuItem(value: 'DEFAULT', child: Text(l10n.dnsRecordLineDefault)),
                        DropdownMenuItem(value: 'LTEL', child: Text(l10n.dnsRecordLineLTEL)),
                        DropdownMenuItem(value: 'LCNC', child: Text(l10n.dnsRecordLineLCNC)),
                        DropdownMenuItem(value: 'LMOB', child: Text(l10n.dnsRecordLineLMOB)),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => fieldValues['line'] = v);
                        }
                      },
                    ),
                  ],
                  if (hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(l10n.dnsRecordRequired, style: TextStyle(color: Theme.of(dialogContext).colorScheme.error, fontSize: 12)),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.commonCancel),
              ),
              FilledButton(
                onPressed: isSubmitting ? null : () async {
                  bool hasEmpty = false;
                  for (final field in fields) {
                    if (field.required && (fieldValues[field.key]?.isEmpty ?? true)) {
                      hasEmpty = true;
                      break;
                    }
                  }

                  final contentKey = providerId == 'cloudns' ? 'record' :
                                   providerId == 'dnshe' ? 'record' :
                                   providerId == 'rainyun' ? 'value' : 'content';
                  if (fieldValues[contentKey]?.isEmpty ?? true) {
                    hasEmpty = true;
                  }

                  if (hasEmpty) {
                    setDialogState(() => hasError = true);
                    return;
                  }

                  setDialogState(() { isSubmitting = true; hasError = false; });

                  if (driver.supportsProxy) {
                    fieldValues['proxied'] = proxied.toString();
                  }
                  if (priorityValue != null) {
                    fieldValues['priority'] = priorityValue!;
                  }

                  final recordData = driver.prepareRecordData(
                    fieldValues: fieldValues,
                    recordType: selectedType,
                    isEdit: false,
                  );

                  final result = await domainState.createDnsRecord(
                    providerId,
                    widget.domainId,
                    recordData,
                    credentials,
                  );

                  if (dialogContext.mounted) {
                    if (result['success']) {
                      Navigator.pop(dialogContext);
                      ToastUtil.showSuccess(context, l10n.toastDnsRecordAdded);
                    } else {
                      setDialogState(() => isSubmitting = false);
                      ToastUtil.showError(
                        context,
                        result['error'] ?? '',
                        errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null,
                      );
                    }
                  }
                },
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

  void _showEditRecordDialog(BuildContext context, String providerId, Map<String, dynamic> record) {
    final driver = DriverFactory.get(providerId);
    if (driver == null) return;

    if (providerId == 'dnshe' && driver is dnshe_driver.DnsheDriver) {
      final domainState = context.read<NewDomainState>();
      final credentialState = context.read<CredentialState>();
      final credentials = credentialState.selectedCredential?.credentials ?? {};

      driver.showEditRecordDialog(
        context,
        record,
        onSubmit: (recordData) async {
          final result = await domainState.updateDnsRecord(
            providerId,
            widget.domainId,
            record['id'].toString(),
            recordData,
            credentials,
          );

          if (result['success'] == true) {
            if (context.mounted) {
              ToastUtil.showSuccess(context, AppLocalizations.of(context)!.toastDnsRecordUpdated);
            }
          }

          return result;
        },
      );
      return;
    }

    final l10nEdit = AppLocalizations.of(context)!;
    final domainState = context.read<NewDomainState>();
    final credentialState = context.read<CredentialState>();
    final credentials = credentialState.selectedCredential?.credentials ?? {};

    String selectedType = record['type']?.toString() ?? 'A';
    final fieldControllers = <String, TextEditingController>{};
    final fieldValues = <String, String>{};
    bool proxied = record['proxied'] == true;
    bool isSubmitting = false;

    void initControllers() {
      for (final field in driver.getEditRecordFields(record)) {
        fieldControllers[field.key] = TextEditingController(text: field.initialValue ?? '');
        fieldValues[field.key] = field.initialValue ?? '';
      }
      if (driver.supportsProxy) {
        proxied = record['proxied'] == true;
      }
    }

    initControllers();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final fields = driver.getEditRecordFields(record);

          return AlertDialog(
            title: Text(DriverLocalizations.editRecordTitle(context, driver)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(labelText: l10nEdit.dnsRecordType),
                    items: driver.getSupportedRecordTypes().map((t) =>
                      DropdownMenuItem(value: t, child: Text(t))
                    ).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedType = v);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ...fields.where((f) => f.key != 'line').map((field) {
                    final label = DriverLocalizations.fieldLabel(l10nEdit, driver.providerId, field.key, field.label);
                    final hintText = DriverLocalizations.fieldHint(l10nEdit, driver.providerId, field.key, field.hintText);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: fieldControllers[field.key],
                        decoration: InputDecoration(
                          labelText: label,
                          hintText: hintText,
                        ),
                        keyboardType: field.keyboardType,
                        onChanged: (v) => fieldValues[field.key] = v,
                      ),
                    );
                  }),
                  if (selectedType == 'MX' || selectedType == 'SRV') ...[
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        labelText: selectedType == 'MX' ? l10nEdit.dnsRecordPriority : l10nEdit.dnsRecordWeight,
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(
                        text: record['priority']?.toString() ??
                              record['mx']?.toString() ??
                              '10',
                      ),
                      onChanged: (v) => fieldValues['priority'] = v,
                    ),
                  ],
                  if (driver.supportsProxy && (selectedType == 'A' || selectedType == 'AAAA' || selectedType == 'CNAME')) ...[
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10nEdit.dnsRecordProxy),
                      subtitle: Text(l10nEdit.dnsRecordProxyHint),
                      value: proxied,
                      onChanged: (v) => setDialogState(() => proxied = v),
                    ),
                  ],
                  if (driver.supportsRecordLine()) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: fieldValues['line'] ?? record['line']?.toString() ?? 'DEFAULT',
                      decoration: InputDecoration(labelText: l10nEdit.dnsRecordLine),
                      items: [
                        DropdownMenuItem(value: 'DEFAULT', child: Text(l10nEdit.dnsRecordLineDefault)),
                        DropdownMenuItem(value: 'LTEL', child: Text(l10nEdit.dnsRecordLineLTEL)),
                        DropdownMenuItem(value: 'LCNC', child: Text(l10nEdit.dnsRecordLineLCNC)),
                        DropdownMenuItem(value: 'LMOB', child: Text(l10nEdit.dnsRecordLineLMOB)),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => fieldValues['line'] = v);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10nEdit.commonCancel),
              ),
              FilledButton(
                onPressed: isSubmitting ? null : () async {
                  setDialogState(() => isSubmitting = true);

                  if (driver.supportsProxy) {
                    fieldValues['proxied'] = proxied.toString();
                  }

                  final recordData = driver.prepareRecordData(
                    fieldValues: fieldValues,
                    recordType: selectedType,
                    isEdit: true,
                  );

                  final result = await domainState.updateDnsRecord(
                    providerId,
                    widget.domainId,
                    record['id'].toString(),
                    recordData,
                    credentials,
                  );

                  if (dialogContext.mounted) {
                    if (result['success']) {
                      Navigator.pop(dialogContext);
                      ToastUtil.showSuccess(context, l10nEdit.toastDnsRecordUpdated);
                    } else {
                      setDialogState(() => isSubmitting = false);
                      ToastUtil.showError(
                        context,
                        result['error'] ?? l10nEdit.toastDnsRecordUpdateFailed,
                        errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null,
                      );
                    }
                  }
                },
                child: isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10nEdit.commonSave),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteRecord(BuildContext context, String providerId, Map<String, dynamic> record) {
    final name = record['name']?.toString() ?? '';
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final l10nDel = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l10nDel.dnsRecordDeleteTitle),
            content: Text(l10nDel.dnsRecordDeleteConfirm(name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10nDel.commonCancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  foregroundColor: Theme.of(dialogContext).colorScheme.onError,
                ),
                onPressed: isDeleting ? null : () async {
                  setDialogState(() => isDeleting = true);
                  final domainState = context.read<NewDomainState>();
                  final result = await domainState.deleteDnsRecord(
                    providerId,
                    widget.domainId,
                    record['id'].toString(),
                    context.read<CredentialState>().selectedCredential!.credentials,
                  );
                  if (dialogContext.mounted) {
                    if (result['success']) {
                      Navigator.pop(dialogContext);
                      ToastUtil.showSuccess(context, l10nDel.toastDnsRecordDeleted);
                    } else {
                      setDialogState(() => isDeleting = false);
                      ToastUtil.showError(
                        context,
                        result['error'] ?? l10nDel.toastDnsRecordDeleteFailed,
                        errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null,
                      );
                    }
                  }
                },
                child: isDeleting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10nDel.commonDelete),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final credentialState = context.watch<CredentialState>();
    final domainState = context.watch<NewDomainState>();
    final records = domainState.dnsRecords[widget.domainId] ?? [];
    final providerId = credentialState.selectedCredential?.providerId ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.domainName),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _autoLoadRecords,
          ),
        ],
      ),
      body: _buildBody(domainState, records, providerId),
      floatingActionButton: providerId.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddRecordDialog(context, providerId),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBody(NewDomainState state, List<Map<String, dynamic>> records, String providerId) {
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

    if (state.isLoading && records.isEmpty) return const DnsLoading();

    if (state.error != null) {
      final hasError = state.error != null;
      if (hasError && records.isEmpty) {
        return DnsErrorState(
          message: state.error!,
          onRetry: _autoLoadRecords,
        );
      }
    }

    final isLoading = state.loadingState == LoadingState.loading;

    if (isLoading && records.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final showCenterLoading = state.showCenterLoading;
    if (showCenterLoading) {
      return Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.1),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      );
    }

    if (records.isEmpty) {
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
              child: _buildEmptyState(),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: _pullToRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: DnsSpacing.sm),
        itemCount: records.length,
        separatorBuilder: (_, __) => const DnsDivider(),
        itemBuilder: (context, index) {
          final record = records[index];
          return DnsDnsRecordTile(
            record: record,
            onEdit: state.isOperating ? null : () => _showEditRecordDialog(context, providerId, record),
            onDelete: state.isOperating ? () {} : () => _deleteRecord(context, providerId, record),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return DnsEmptyState(
      icon: Icons.dns_outlined,
      title: l10n.dnsRecordEmptyTitle,
      description: l10n.dnsRecordEmptyDesc,
    );
  }
}
