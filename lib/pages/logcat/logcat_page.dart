import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dlist/generated/l10n/app_localizations.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/ui/md3_widgets.dart';
import '../../core/theme/design_system.dart';
import '../../utils/log/log.dart';
import '../../utils/toast_util.dart';

class LogcatPage extends StatefulWidget {
  const LogcatPage({super.key});

  @override
  State<LogcatPage> createState() => _LogcatPageState();
}

class _LogcatPageState extends State<LogcatPage> {
  List<LogEntry> _logs = [];
  Set<LogLevel> _selectedLevels = LogLevel.values.toSet();
  Set<String> _selectedModules = {
    'architecture', 'core', 'drivers', 'ux', 'ui', 'utils', 'services'
  };
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await LogService.instance.getLogs();
    setState(() {
      _logs = logs.reversed.toList();
      _isLoading = false;
    });
  }

  List<LogEntry> get _filteredLogs {
    return _logs.where((log) {
      if (!_selectedLevels.contains(log.level)) return false;
      if (!_selectedModules.contains(log.module)) return false;
      return true;
    }).toList();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterBottomSheet(
        selectedLevels: _selectedLevels,
        selectedModules: _selectedModules,
        onLevelsChanged: (levels) {
          setState(() => _selectedLevels = levels);
        },
        onModulesChanged: (modules) {
          setState(() => _selectedModules = modules);
        },
      ),
    );
  }

  Future<void> _clearLogs() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDnsConfirmDialog(
      context,
      title: l10n.logcatClearTitle,
      message: l10n.logcatClearConfirm,
      confirmLabel: l10n.logcatClearBtn,
      isDestructive: true,
    );
    if (confirm == true) {
      await LogService.instance.clearLogs();
      await _loadLogs();
      if (mounted) {
        ToastUtil.showSuccess(context, l10n.toastLogcatCleared);
      }
    }
  }

  Future<void> _copyLogs() async {
    final text = _filteredLogs.map((log) {
      return '${log.timestampIso} ${log.level.tag} [${log.module.toUpperCase()}] ${log.classMethod} ${log.action}${log.data != null ? ' ${jsonEncode(log.data)}' : ''}${log.durationMs != null ? ' ${log.durationMs}ms' : ''}${log.status != null ? ' ${log.status}' : ''}';
    }).join('\n');

    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ToastUtil.showSuccess(context, AppLocalizations.of(context)!.toastLogcatCopied);
    }
  }

  Future<void> _exportLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/logcat_$timestamp.txt');

      final text = _filteredLogs.map((log) {
        return '${log.timestampIso} ${log.level.tag} [${log.module.toUpperCase()}] ${log.classMethod} ${log.action}${log.data != null ? ' ${jsonEncode(log.data)}' : ''}${log.durationMs != null ? ' ${log.durationMs}ms' : ''}${log.status != null ? ' ${log.status}' : ''}${log.errorMessage != null ? ' ERROR: ${log.errorMessage}' : ''}';
      }).join('\n');

      await file.writeAsString(text);

      if (mounted) {
        ToastUtil.showSuccess(context, AppLocalizations.of(context)!.toastLogcatExported(file.path));
      }
    } catch (e) {
      if (mounted) {
        ToastUtil.showError(context, AppLocalizations.of(context)!.toastLogcatExportFailed(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.logcatTitle),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'copy':
                  _copyLogs();
                case 'export':
                  _exportLogs();
                case 'clear':
                  _clearLogs();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'copy',
                child: ListTile(
                  leading: const Icon(Icons.copy),
                  title: Text(AppLocalizations.of(context)!.logcatCopy),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: const Icon(Icons.download),
                  title: Text(AppLocalizations.of(context)!.logcatExport),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(AppLocalizations.of(context)!.logcatClear, style: const TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const DnsLoading()
                : _filteredLogs.isEmpty
                    ? DnsEmptyState(
                        icon: Icons.article_outlined,
                        title: AppLocalizations.of(context)!.logcatEmptyTitle,
                        description: AppLocalizations.of(context)!.logcatEmptyDesc,
                      )
                    : _buildLogList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DnsSpacing.md,
        vertical: DnsSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: LogLevel.values.map((level) {
            final isSelected = _selectedLevels.contains(level);
            return Padding(
              padding: const EdgeInsets.only(right: DnsSpacing.xs),
              child: FilterChip(
                label: Text(_getLevelLabel(level)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedLevels.add(level);
                    } else {
                      _selectedLevels.remove(level);
                    }
                  });
                },
                backgroundColor: colorScheme.surfaceContainerLow,
                selectedColor: _getLevelColor(level).withValues(alpha: 0.2),
                checkmarkColor: _getLevelColor(level),
                labelStyle: TextStyle(
                  color: isSelected ? _getLevelColor(level) : colorScheme.onSurface,
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLogList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: DnsSpacing.md),
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final log = _filteredLogs[index];
        return _LogEntryTile(log: log);
      },
    );
  }

  String _getLevelLabel(LogLevel level) {
    switch (level) {
      case LogLevel.debug: return 'Debug';
      case LogLevel.info: return 'Info';
      case LogLevel.warn: return 'Warn';
      case LogLevel.error: return 'Error';
      case LogLevel.fatal: return 'Fatal';
    }
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug: return Colors.cyan;
      case LogLevel.info: return Colors.green;
      case LogLevel.warn: return Colors.orange;
      case LogLevel.error: return Colors.red;
      case LogLevel.fatal: return Colors.purple;
    }
  }
}

class _LogEntryTile extends StatelessWidget {
  final LogEntry log;

  const _LogEntryTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final levelColor = _getLevelColor(log.level);

    return Container(
      margin: const EdgeInsets.only(bottom: DnsSpacing.sm),
      padding: const EdgeInsets.all(DnsSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DnsRadius.sm),
        border: Border(
          left: BorderSide(
            color: levelColor,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.level.tag,
                  style: TextStyle(
                    color: levelColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: DnsSpacing.xs),
              Text(
                '[${log.module.toUpperCase()}]',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                log.timestampIso.split('T').last.substring(0, 12),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: DnsSpacing.xs),
          Text(
            '${log.className}.${log.methodName}',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            log.action,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 12,
            ),
          ),
          if (log.data != null && log.data!.isNotEmpty) ...[
            const SizedBox(height: DnsSpacing.xs),
            Container(
              padding: const EdgeInsets.all(DnsSpacing.xs),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                jsonEncode(log.data),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          if (log.durationMs != null || log.status != null) ...[
            const SizedBox(height: DnsSpacing.xs),
            Row(
              children: [
                if (log.durationMs != null) ...[
                  Icon(Icons.timer_outlined, size: 12, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Text(
                    '${log.durationMs}ms',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10),
                  ),
                  const SizedBox(width: DnsSpacing.sm),
                ],
                if (log.status != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: log.status == 'success'
                          ? Colors.green.withValues(alpha: 0.15)
                          : log.status == 'error'
                              ? Colors.red.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      log.status!,
                      style: TextStyle(
                        color: log.status == 'success'
                            ? Colors.green
                            : log.status == 'error'
                                ? Colors.red
                                : Colors.orange,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug: return Colors.cyan;
      case LogLevel.info: return Colors.green;
      case LogLevel.warn: return Colors.orange;
      case LogLevel.error: return Colors.red;
      case LogLevel.fatal: return Colors.purple;
    }
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final Set<LogLevel> selectedLevels;
  final Set<String> selectedModules;
  final ValueChanged<Set<LogLevel>> onLevelsChanged;
  final ValueChanged<Set<String>> onModulesChanged;

  const _FilterBottomSheet({
    required this.selectedLevels,
    required this.selectedModules,
    required this.onLevelsChanged,
    required this.onModulesChanged,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late Set<LogLevel> _levels;
  late Set<String> _modules;

  static const List<String> _allModules = [
    'architecture', 'core', 'drivers', 'ux', 'ui', 'utils', 'services'
  ];

  @override
  void initState() {
    super.initState();
    _levels = Set.from(widget.selectedLevels);
    _modules = Set.from(widget.selectedModules);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      margin: EdgeInsets.only(top: topPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DnsSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.logcatFilterTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    widget.onLevelsChanged(_levels);
                    widget.onModulesChanged(_modules);
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.logcatFilterApply),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(DnsSpacing.md),
              children: [
                Text(AppLocalizations.of(context)!.logcatFilterLevel, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: DnsSpacing.sm),
                Wrap(
                  spacing: DnsSpacing.xs,
                  runSpacing: DnsSpacing.xs,
                  children: LogLevel.values.map((level) {
                    final isSelected = _levels.contains(level);
                    return FilterChip(
                      label: Text(_getLevelLabel(level)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _levels.add(level);
                          } else {
                            _levels.remove(level);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: DnsSpacing.lg),
                Text(AppLocalizations.of(context)!.logcatFilterModule, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: DnsSpacing.sm),
                Wrap(
                  spacing: DnsSpacing.xs,
                  runSpacing: DnsSpacing.xs,
                  children: _allModules.map((module) {
                    final isSelected = _modules.contains(module);
                    return FilterChip(
                      label: Text(module),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _modules.add(module);
                          } else {
                            _modules.remove(module);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: DnsSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _levels = LogLevel.values.toSet();
                            _modules = _allModules.toSet();
                          });
                        },
                        child: Text(AppLocalizations.of(context)!.commonSelectAll),
                      ),
                    ),
                    const SizedBox(width: DnsSpacing.md),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _levels.clear();
                            _modules.clear();
                          });
                        },
                        child: Text(AppLocalizations.of(context)!.commonClear),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + DnsSpacing.md),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLevelLabel(LogLevel level) {
    switch (level) {
      case LogLevel.debug: return 'Debug';
      case LogLevel.info: return 'Info';
      case LogLevel.warn: return 'Warn';
      case LogLevel.error: return 'Error';
      case LogLevel.fatal: return 'Fatal';
    }
  }
}