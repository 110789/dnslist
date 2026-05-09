import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/state/theme_provider.dart';
import '../../core/ui/adaptive_widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return AdaptiveScaffold(
      title: '设置',
      showBackButton: true,
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _SectionHeader(title: '外观'),
          _buildUIStyleTile(context, themeProvider),
          _buildDarkModeTile(context, themeProvider),
          const Divider(height: 32),
          _SectionHeader(title: '关于'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('版本'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Flutter'),
            subtitle: const Text('跨平台DNS域名管理工具'),
          ),
        ],
      ),
    );
  }

  Widget _buildUIStyleTile(BuildContext context, ThemeProvider themeProvider) {
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: const Text('界面风格'),
      subtitle: Text(themeProvider.uiStyle == UIStyle.md3 ? 'Material Design 3' : 'Cupertino'),
      onTap: () => _showUIStyleSheet(context, themeProvider),
    );
  }

  void _showUIStyleSheet(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '选择界面风格',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.android),
              title: const Text('Material Design 3'),
              subtitle: const Text('现代Android风格'),
              trailing: themeProvider.uiStyle == UIStyle.md3
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                themeProvider.setUIStyle(UIStyle.md3);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.apple),
              title: const Text('Cupertino'),
              subtitle: const Text('iOS风格'),
              trailing: themeProvider.uiStyle == UIStyle.cupertino
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                themeProvider.setUIStyle(UIStyle.cupertino);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkModeTile(BuildContext context, ThemeProvider themeProvider) {
    String darkModeLabel;
    switch (themeProvider.darkMode) {
      case DarkModeOption.light:
        darkModeLabel = '浅色';
        break;
      case DarkModeOption.dark:
        darkModeLabel = '深色';
        break;
      case DarkModeOption.system:
        darkModeLabel = '跟随系统';
        break;
    }

    return ListTile(
      leading: const Icon(Icons.dark_mode_outlined),
      title: const Text('深色模式'),
      subtitle: Text(darkModeLabel),
      onTap: () => _showDarkModeSheet(context, themeProvider),
    );
  }

  void _showDarkModeSheet(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '选择深色模式',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('浅色'),
              trailing: themeProvider.darkMode == DarkModeOption.light
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                themeProvider.setDarkMode(DarkModeOption.light);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('深色'),
              trailing: themeProvider.darkMode == DarkModeOption.dark
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                themeProvider.setDarkMode(DarkModeOption.dark);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_suggest),
              title: const Text('跟随系统'),
              trailing: themeProvider.darkMode == DarkModeOption.system
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                themeProvider.setDarkMode(DarkModeOption.system);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}