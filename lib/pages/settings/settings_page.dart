import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:dp/generated/l10n/app_localizations.dart';
import '../../core/ui/md3_widgets.dart';
import '../../core/theme/design_system.dart';
import '../../core/state/theme_provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/router/app_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.navSettings),
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
              DnsSectionHeader(title: l10n.settingsAppearance),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.dark_mode_outlined,
                    title: l10n.settingsDarkMode,
                    subtitle: _getDarkModeLabel(l10n, darkMode),
                    onTap: () => _showDarkModeSheet(context, context.read<ThemeProvider>()),
                    showDivider: true,
                  ),
                  _SettingsTile(
                    icon: Icons.palette_outlined,
                    title: l10n.settingsThemeColor,
                    subtitle: l10n.settingsThemeDefault,
                    showDivider: true,
                  ),
                  _SettingsTile(
                    icon: Icons.phone_android,
                    title: l10n.settingsUIStyle,
                    subtitle: context.read<ThemeProvider>().uiStyle == UIStyle.md3 ? l10n.settingsUIStyleMD3 : l10n.settingsUIStyleCupertino,
                  ),
                ],
              ),
              const SizedBox(height: DnsSpacing.sm),
              DnsSectionHeader(title: l10n.settingsGeneral),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.translate,
                    title: l10n.settingsLanguage,
                    subtitle: _getLanguageLabel(context),
                    onTap: () => _showLanguageSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: DnsSpacing.sm),
              DnsSectionHeader(title: l10n.settingsAdvanced),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.settingsLogs,
                    subtitle: l10n.settingsLogsSubtitle,
                    onTap: () => GoRouter.of(context).push(RoutePaths.logcat),
                  ),
                ],
              ),
              const SizedBox(height: DnsSpacing.sm),
              DnsSectionHeader(title: l10n.settingsAbout),
              _SettingsGroup(
                children: [
                  _SettingsTile(
                    icon: Icons.new_releases_outlined,
                    title: l10n.settingsAbout,
                    subtitle: l10n.settingsVersion,
                    onTap: () => GoRouter.of(context).push(RoutePaths.about),
                  ),
                ],
              ),
              const SizedBox(height: DnsSpacing.xl),
              Center(
                child: Text(
                  l10n.settingsFooter,
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

  String _getLanguageLabel(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!;
    if (localeProvider.useSystemLocale) return l10n.languageSystem;
    if (localeProvider.locale?.languageCode == 'zh') return l10n.languageZh;
    return l10n.languageEn;
  }

  void _showLanguageSheet(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!;
    DnsBottomSheet.show(
      context: context,
      title: l10n.settingsLanguage,
      children: [
        _LanguageOption(
          label: l10n.languageSystem,
          isSelected: localeProvider.useSystemLocale,
          onTap: () {
            localeProvider.setLocale(null);
            Navigator.pop(context);
          },
        ),
        _LanguageOption(
          label: l10n.languageEn,
          isSelected: localeProvider.locale?.languageCode == 'en',
          onTap: () {
            localeProvider.setLocale(const Locale('en'));
            Navigator.pop(context);
          },
        ),
        _LanguageOption(
          label: l10n.languageZh,
          isSelected: localeProvider.locale?.languageCode == 'zh',
          onTap: () {
            localeProvider.setLocale(const Locale('zh'));
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  String _getDarkModeLabel(AppLocalizations l10n, DarkModeOption mode) {
    switch (mode) {
      case DarkModeOption.light: return l10n.darkModeLight;
      case DarkModeOption.dark: return l10n.darkModeDark;
      case DarkModeOption.system: return l10n.darkModeSystem;
    }
  }

  void _showDarkModeSheet(BuildContext context, ThemeProvider themeProvider) {
    final l10n = AppLocalizations.of(context)!;
    DnsBottomSheet.show(
      context: context,
      title: l10n.settingsDarkMode,
      children: DarkModeOption.values.map((mode) {
        final isSelected = themeProvider.darkMode == mode;
        return _DarkModeOption(
          mode: mode,
          label: _getDarkModeLabel(l10n, mode),
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

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

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
              Icon(Icons.translate, size: 22, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
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