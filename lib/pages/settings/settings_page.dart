import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/md3_widgets.dart';
import '../../core/theme/design_system.dart';
import '../../core/state/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: DnsSpacing.sm),
            children: [
              DnsSectionHeader(title: '外观'),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: '外观模式',
                    subtitle: _getDarkModeLabel(themeProvider.darkMode),
                    onTap: () => _showDarkModeDialog(context, themeProvider),
                    showDivider: true,
                  ),
                  _SettingsTile(
                    icon: Icons.palette_outlined,
                    title: '主题颜色',
                    subtitle: '默认',
                    showDivider: true,
                  ),
                  _SettingsTile(
                    icon: Icons.android,
                    title: '界面风格',
                    subtitle: themeProvider.uiStyle == UIStyle.md3 ? 'Material Design 3' : 'Cupertino',
                  ),
                ],
              ),
              const SizedBox(height: DnsSpacing.sm),
              DnsSectionHeader(title: '通用'),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.language_outlined,
                    title: '语言',
                    subtitle: '跟随系统',
                  ),
                ],
              ),
              const SizedBox(height: DnsSpacing.sm),
              DnsSectionHeader(title: '高级'),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.article_outlined,
                    title: '日志',
                    subtitle: '查看应用运行日志',
                  ),
                ],
              ),
              const SizedBox(height: DnsSpacing.sm),
              DnsSectionHeader(title: '关于'),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: '版本',
                    subtitle: '1.0.0',
                    showDivider: true,
                  ),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    title: '开源许可',
                  ),
                ],
              ),
              const SizedBox(height: DnsSpacing.xl),
              Center(
                child: Text(
                  'DNS域名管理工具 v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: DnsSpacing.lg),
            ],
          );
        },
      ),
    );
  }

  String _getDarkModeLabel(DarkModeOption mode) {
    switch (mode) {
      case DarkModeOption.light: return '浅色';
      case DarkModeOption.dark: return '深色';
      case DarkModeOption.system: return '跟随系统';
    }
  }

  void _showDarkModeDialog(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DarkModeBottomSheet(
        themeProvider: themeProvider,
        getDarkModeLabel: _getDarkModeLabel,
        onDarkModeChanged: (mode) {
          themeProvider.setDarkMode(mode);
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _DarkModeBottomSheet extends StatelessWidget {
  final ThemeProvider themeProvider;
  final String Function(DarkModeOption) getDarkModeLabel;
  final Function(DarkModeOption) onDarkModeChanged;

  const _DarkModeBottomSheet({
    required this.themeProvider,
    required this.getDarkModeLabel,
    required this.onDarkModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DnsRadius.xl),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: DnsSpacing.sm),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DnsSpacing.lg,
                DnsSpacing.lg,
                DnsSpacing.lg,
                DnsSpacing.md,
              ),
              child: Text(
                '外观模式',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...DarkModeOption.values.map((mode) {
              final isSelected = themeProvider.darkMode == mode;
              return _DarkModeOption(
                mode: mode,
                label: getDarkModeLabel(mode),
                isSelected: isSelected,
                onTap: () => onDarkModeChanged(mode),
              );
            }),
            const SizedBox(height: DnsSpacing.sm),
            Divider(
              height: 0.5,
              color: colorScheme.outlineVariant,
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: DnsSpacing.md,
                  ),
                  child: Center(
                    child: Text(
                      '取消',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkModeOption extends StatelessWidget {
  final DarkModeOption mode;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DarkModeOption({
    required this.mode,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (mode) {
      case DarkModeOption.light: return Icons.light_mode_outlined;
      case DarkModeOption.dark: return Icons.dark_mode_outlined;
      case DarkModeOption.system: return Icons.settings_suggest_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DnsRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DnsSpacing.md,
            vertical: DnsSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Icon(_icon, size: 22, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
              const SizedBox(width: DnsSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check, size: 20, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DnsSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DnsRadius.md),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool showDivider;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.showDivider = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DnsRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DnsSpacing.md,
                vertical: DnsSpacing.sm + 2,
              ),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: colorScheme.primary),
                  const SizedBox(width: DnsSpacing.md),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  if (subtitle != null) ...[
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: DnsSpacing.xs),
                  ],
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: colorScheme.outlineVariant,
            ),
          ),
      ],
    );
  }
}