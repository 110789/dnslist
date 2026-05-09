import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/ui/md3_widgets.dart';
import '../../core/theme/design_system.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
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
          DnsListTile(
            leading: Icon(Icons.palette_outlined, color: colorScheme.primary),
            title: '界面风格',
            subtitle: Text(themeProvider.uiStyle == UIStyle.md3 ? 'Material Design 3' : 'Cupertino'),
            trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            onTap: () => _showUIStyleSheet(context, themeProvider),
          ),
          const DnsDivider(indent: 72),
          DnsListTile(
            leading: Icon(Icons.dark_mode_outlined, color: colorScheme.primary),
            title: '深色模式',
            subtitle: Text(_getDarkModeLabel(themeProvider.darkMode)),
            trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            onTap: () => _showDarkModeSheet(context, themeProvider),
          ),
          const SizedBox(height: DnsSpacing.md),
          DnsSectionHeader(title: '关于'),
          DnsListTile(
            leading: Icon(Icons.info_outline, color: colorScheme.primary),
            title: '版本',
            subtitle: const Text('1.0.0'),
          ),
          const DnsDivider(indent: 72),
          DnsListTile(
            leading: Icon(Icons.flutter_dash, color: colorScheme.primary),
            title: 'Flutter',
            subtitle: const Text('跨平台DNS域名管理工具'),
          ),
        ],
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

  void _showUIStyleSheet(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DnsSpacing.md),
              child: Text(
                '选择界面风格',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            DnsListTile(
              leading: Icon(Icons.android, color: Theme.of(ctx).colorScheme.primary),
              title: 'Material Design 3',
              subtitle: const Text('现代Android风格'),
              trailing: themeProvider.uiStyle == UIStyle.md3
                  ? Icon(Icons.check_circle, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                themeProvider.setUIStyle(UIStyle.md3);
                Navigator.pop(ctx);
              },
            ),
            const DnsDivider(indent: 72),
            DnsListTile(
              leading: Icon(Icons.apple, color: Theme.of(ctx).colorScheme.primary),
              title: 'Cupertino',
              subtitle: const Text('iOS风格'),
              trailing: themeProvider.uiStyle == UIStyle.cupertino
                  ? Icon(Icons.check_circle, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                themeProvider.setUIStyle(UIStyle.cupertino);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: DnsSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _showDarkModeSheet(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DnsSpacing.md),
              child: Text(
                '选择深色模式',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            DnsListTile(
              leading: Icon(Icons.light_mode, color: Theme.of(ctx).colorScheme.primary),
              title: '浅色',
              trailing: themeProvider.darkMode == DarkModeOption.light
                  ? Icon(Icons.check_circle, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                themeProvider.setDarkMode(DarkModeOption.light);
                Navigator.pop(ctx);
              },
            ),
            const DnsDivider(indent: 72),
            DnsListTile(
              leading: Icon(Icons.dark_mode, color: Theme.of(ctx).colorScheme.primary),
              title: '深色',
              trailing: themeProvider.darkMode == DarkModeOption.dark
                  ? Icon(Icons.check_circle, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                themeProvider.setDarkMode(DarkModeOption.dark);
                Navigator.pop(ctx);
              },
            ),
            const DnsDivider(indent: 72),
            DnsListTile(
              leading: Icon(Icons.settings_suggest, color: Theme.of(ctx).colorScheme.primary),
              title: '跟随系统',
              trailing: themeProvider.darkMode == DarkModeOption.system
                  ? Icon(Icons.check_circle, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () {
                themeProvider.setDarkMode(DarkModeOption.system);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: DnsSpacing.lg),
          ],
        ),
      ),
    );
  }
}
