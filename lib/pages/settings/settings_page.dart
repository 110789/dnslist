import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/md3_widgets.dart';
import '../../core/theme/design_system.dart';
import '../../core/state/theme_provider.dart';
import '../../core/router/app_router.dart';

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
      body: Selector<ThemeProvider, DarkModeOption>(
        selector: (_, theme) => theme.darkMode,
        builder: (context, darkMode, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: DnsSpacing.sm),
            children: [
              DnsSectionHeader(title: '外观'),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: '外观模式',
                    subtitle: _getDarkModeLabel(darkMode),
                    onTap: () => _showDarkModeSheet(context, context.read<ThemeProvider>()),
                    showDivider: true,
                  ),
                  _SettingsTile(
                    icon: Icons.palette_outlined,
                    title: '主题颜色',
                    subtitle: '默认',
                    showDivider: true,
                  ),
                  _SettingsTile(
                    icon: Icons.phone_android,
                    title: '界面风格',
                    subtitle: context.read<ThemeProvider>().uiStyle == UIStyle.md3 ? 'Material Design 3' : 'Cupertino',
                  ),
                ],
              ),
              const SizedBox(height: DnsSpacing.sm),
              DnsSectionHeader(title: '通用'),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.translate,
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
                    icon: Icons.receipt_long_outlined,
                    title: '日志',
                    subtitle: '查看应用运行日志',
                    onTap: () => GoRouter.of(context).push(RoutePaths.logcat),
                  ),
                ],
              ),
              const SizedBox(height: DnsSpacing.sm),
              DnsSectionHeader(title: '关于'),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.new_releases_outlined,
                    title: '关于',
                    subtitle: '版本 1.0.0',
                    onTap: () => GoRouter.of(context).push(RoutePaths.about),
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
      case DarkModeOption.light: return '日间模式';
      case DarkModeOption.dark: return '夜间模式';
      case DarkModeOption.system: return '跟随系统';
    }
  }

  void _showDarkModeSheet(BuildContext context, ThemeProvider themeProvider) {
    DnsBottomSheet.show(
      context: context,
      title: '外观模式',
      children: DarkModeOption.values.map((mode) {
        final isSelected = themeProvider.darkMode == mode;
        return _DarkModeOption(
          mode: mode,
          label: _getDarkModeLabel(mode),
          isSelected: isSelected,
          onTap: () {
            themeProvider.setDarkMode(mode);
            Navigator.pop(context);
          },
        );
      }).toList(),
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