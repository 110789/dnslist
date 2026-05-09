import 'package:flutter/material.dart';
import '../../core/ui/md3_widgets.dart';
import '../../core/theme/design_system.dart';

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
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: DnsSpacing.sm),
        children: [
          DnsSectionHeader(title: '外观'),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: '外观模式',
                subtitle: '浅色',
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
                subtitle: 'Material Design 3',
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

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
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