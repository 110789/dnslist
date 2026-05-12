import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/design_system.dart';

enum DnsLoadState { idle, loading, loaded, empty, error }

class DnsScaffold extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? leading;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;

  const DnsScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.drawer,
    this.leading,
    this.showBackButton = true,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        leading: showBackButton
            ? null
            : leading ?? (drawer != null ? null : const SizedBox.shrink()),
        actions: actions,
        bottom: bottom,
      ),
      drawer: drawer,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class DnsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool showBackButton;
  final VoidCallback? onBack;

  const DnsAppBar({
    super.key,
    required this.title,
    this.actions,
    this.bottom,
    this.showBackButton = true,
    this.onBack,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return DnsScaffold(
      title: title,
      actions: actions,
      bottom: bottom,
      showBackButton: showBackButton,
      body: const SizedBox.shrink(),
    );
  }
}

class DnsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const DnsCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(DnsRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DnsRadius.md),
        child: Container(
          padding: padding ?? const EdgeInsets.all(DnsSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DnsRadius.md),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class DnsListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DnsListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(DnsRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DnsSpacing.md,
            vertical: DnsSpacing.sm + 4,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: DnsSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class DnsSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const DnsSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(DnsSpacing.md + 4, DnsSpacing.md, DnsSpacing.md, DnsSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class DnsTypeBadge extends StatelessWidget {
  final String type;
  final bool compact;
  static const double _size = 40.0;

  const DnsTypeBadge({super.key, required this.type, this.compact = false});

  double get _fontSize {
    final len = type.length;
    if (len <= 2) return 14.0;
    if (len == 3) return 12.0;
    if (len == 4) return 11.0;
    return 9.0;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: _size,
      height: _size,
      child: Center(
        child: Container(
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                type,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DnsTtlTag extends StatelessWidget {
  final int ttl;

  const DnsTtlTag({super.key, required this.ttl});

  String get _label {
    if (ttl <= 0) return 'TTL: $ttl';
    if (ttl < 60) return 'TTL: ${ttl}s';
    if (ttl < 3600) return 'TTL: ${(ttl / 60).round()}m';
    if (ttl < 86400) return 'TTL: ${(ttl / 3600).round()}h';
    return 'TTL: ${(ttl / 86400).round()}d';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(DnsRadius.sm),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class DnsStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const DnsStatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = DnsDesignTokens.getStatusColor(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DnsRadius.sm),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class DnsDnsRecordTile extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DnsDnsRecordTile({
    super.key,
    required this.record,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = record['name']?.toString() ?? '';
    final type = record['type']?.toString() ?? '';
    final content = record['content']?.toString() ?? '';
    final ttl = record['ttl'];
    final proxied = record['proxied'] == true;

    return DnsListTile(
      leading: DnsTypeBadge(type: type),
      title: name,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            content,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (ttl != null)
            Text(
              'TTL: $ttl',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (proxied)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.cloud, size: 16, color: colorScheme.primary),
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: colorScheme.onSurfaceVariant),
            onSelected: (value) {
              if (value == 'edit') onEdit?.call();
              if (value == 'delete') onDelete?.call();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('编辑')),
              PopupMenuItem(
                value: 'delete',
                child: Text('删除', style: TextStyle(color: colorScheme.error)),
              ),
            ],
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class DnsDomainTile extends StatelessWidget {
  final Map<String, dynamic> domain;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onRenew;
  final bool supportsDelete;
  final bool supportsRenew;
  final bool supportsShowNameServers;

  const DnsDomainTile({
    super.key,
    required this.domain,
    this.onTap,
    this.onDelete,
    this.onRenew,
    this.supportsDelete = false,
    this.supportsRenew = false,
    this.supportsShowNameServers = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = domain['name']?.toString() ?? '';
    final status = domain['status']?.toString() ?? '';
    final displayStatus = _translateStatus(status);
    final colorScheme = Theme.of(context).colorScheme;

    final createdAt = domain['created_at'] ?? domain['created_on'];
    final expiresAt = domain['expires_at'] ?? domain['expiry_at'];
    final ttl = domain['ttl'];

    final dateLines = <String>[];
    if (createdAt != null) {
      final formatted = _formatDate(createdAt);
      if (formatted.isNotEmpty) dateLines.add('添加: $formatted');
    }
    if (expiresAt != null && expiresAt.toString().isNotEmpty) {
      final formatted = _formatDate(expiresAt);
      if (formatted.isNotEmpty) dateLines.add('过期: $formatted');
    }
    if (ttl != null) {
      final ttlInt = ttl is int ? ttl : int.tryParse(ttl.toString()) ?? 0;
      dateLines.add('TTL: ${_ttlLabel(ttlInt)}');
    }

    final subtitleChild = dateLines.isEmpty
        ? (displayStatus.isNotEmpty
            ? Text(
                displayStatus,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DnsDesignTokens.getStatusColor(status),
                ),
              )
            : null)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...dateLines.map((line) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  line,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              )),
              if (displayStatus.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    displayStatus,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DnsDesignTokens.getStatusColor(status),
                    ),
                  ),
                ),
            ],
          );

    return DnsListTile(
      leading: Icon(Icons.language, color: colorScheme.primary),
      title: name,
      subtitle: subtitleChild,
      onTap: onTap,
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, size: 20, color: colorScheme.onSurfaceVariant),
        onSelected: (value) {
          if (value == 'delete') onDelete?.call();
          if (value == 'renew') onRenew?.call();
          if (value == 'nameservers') _showNameServersDialog(context, domain);
        },
        itemBuilder: (ctx) => [
          if (supportsShowNameServers)
            PopupMenuItem(value: 'nameservers', child: Text(_getNameServersTitle(domain))),
          if (supportsRenew)
            const PopupMenuItem(value: 'renew', child: Text('续期')),
          if (supportsDelete)
            PopupMenuItem(
              value: 'delete',
              child: Text('删除', style: TextStyle(color: colorScheme.error)),
            ),
        ],
      ),
    );
  }

  String _getNameServersTitle(Map<String, dynamic> domainData) {
    final nameServers = domainData['name_servers'] as List? ?? [];
    if (nameServers.isEmpty) return 'DNS 服务器';
    return 'DNS 服务器 (${nameServers.length})';
  }

  void _showNameServersDialog(BuildContext context, Map<String, dynamic> domainData) {
    final nameServers = domainData['name_servers'] as List? ?? [];
    final domainName = domainData['name']?.toString() ?? '';
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(domainName, style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DNS 服务器', style: Theme.of(ctx).textTheme.titleSmall),
              const SizedBox(height: 8),
              if (nameServers.isEmpty)
                Text('无', style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant))
              else
                ...nameServers.map((ns) {
                  final nsValue = ns.toString();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: nsValue));
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('已复制: $nsValue'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(nsValue, style: Theme.of(ctx).textTheme.bodyMedium)),
                              Icon(Icons.copy, size: 16, color: colorScheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  String _ttlLabel(int ttl) {
    if (ttl <= 0) return '$ttl';
    if (ttl < 60) return '${ttl}s';
    if (ttl < 3600) return '${(ttl / 60).round()}m';
    if (ttl < 86400) return '${(ttl / 3600).round()}h';
    return '${(ttl / 86400).round()}d';
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return '';
    try {
      final s = dateVal is int ? dateVal.toString() : dateVal.toString();
      if (s.isEmpty) return '';
      if (dateVal is int && dateVal > 10000000000) {
        final dt = DateTime.fromMillisecondsSinceEpoch(dateVal, isUtc: true);
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
      if (s.contains('T') || s.contains('-')) {
        final dt = DateTime.tryParse(s);
        if (dt != null) return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
      if (s.length >= 10) {
        final dt = DateTime.tryParse(s);
        if (dt != null) return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      }
      return s;
    } catch (_) {
      return '';
    }
  }

  String _translateStatus(String status) {
    final map = {
      'active': '活跃',
      'pending': '待处理',
      'expired': '已过期',
      'suspended': '已暂停',
      'deleted': '已删除',
    };
    return map[status.toLowerCase()] ?? status;
  }
}

class DnsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  const DnsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DnsSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 44,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: DnsSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: DnsSpacing.sm),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: DnsSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class DnsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const DnsErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DnsSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 44,
                color: colorScheme.error.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: DnsSpacing.lg),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DnsSpacing.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: DnsSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DnsLoading extends StatelessWidget {
  final String? message;

  const DnsLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: DnsSpacing.md),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DnsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDestructive;
  final IconData? icon;
  final bool expanded;

  const DnsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDestructive = false,
    this.icon,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDestructive ? colorScheme.onError : colorScheme.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 6),
              ],
              Text(label),
            ],
          );

    final button = isDestructive
        ? FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: child,
          )
        : FilledButton(
            onPressed: isLoading ? null : onPressed,
            child: child,
          );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class DnsOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  const DnsOutlinedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 6),
        ],
        Text(label),
      ],
    );

    final button = OutlinedButton(
      onPressed: onPressed,
      child: child,
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

Future<bool?> showDnsConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '确定',
  String cancelLabel = '取消',
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      final colorScheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: Text(
          title,
          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          message,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  )
                : null,
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );
}

class DnsTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final String? suffixText;

  const DnsTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
    this.suffixText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        suffixText: suffixText,
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }
}

class DnsDivider extends StatelessWidget {
  final double indent;
  final double endIndent;

  const DnsDivider({super.key, this.indent = 60.0, this.endIndent = 44.0});

  @override
  Widget build(BuildContext context) {
    return Divider(
      indent: indent,
      endIndent: endIndent,
      height: 1,
    );
  }
}

class DnsCredentialCard extends StatelessWidget {
  final String providerName;
  final String? remark;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const DnsCredentialCard({
    super.key,
    required this.providerName,
    this.remark,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.3) : Colors.transparent,
      borderRadius: BorderRadius.circular(DnsRadius.md),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(DnsRadius.md),
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
                      providerName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (remark != null && remark!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        remark!,
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
                index: 0,
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

class DnsBottomSheet extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final Widget? footer;

  const DnsBottomSheet({
    super.key,
    this.title,
    required this.children,
    this.footer,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required List<Widget> children,
    Widget? footer,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DnsBottomSheet(
        title: title,
        children: children,
        footer: footer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DnsSpacing.md,
                DnsSpacing.sm,
                DnsSpacing.md,
                DnsSpacing.sm,
              ),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ...children,
          if (footer != null) footer!,
        ],
      ),
    );
  }
}
