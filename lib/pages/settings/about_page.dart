import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dp/generated/l10n/app_localizations.dart';
import '../../core/config/app_config.dart';
import '../../core/router/app_router.dart';
import '../../core/ui/md3_widgets.dart';
import '../../core/theme/design_system.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String _repoUrl = 'https://github.com/lioisme';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.navAbout),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: DnsSpacing.lg),
        children: [
          _buildAppInfoSection(context),
          const SizedBox(height: DnsSpacing.xl),
          DnsSectionHeader(title: AppLocalizations.of(context)!.aboutInfo),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.code_outlined,
                title: AppLocalizations.of(context)!.aboutGitHub,
                subtitle: AppLocalizations.of(context)!.aboutGitHubSub,
                onTap: () => _launchUrl(context, _repoUrl),
                showDivider: true,
              ),
              _SettingsTile(
                icon: Icons.policy_outlined,
                title: AppLocalizations.of(context)!.aboutLicense,
                onTap: () => GoRouter.of(context).push(RoutePaths.licenses),
              ),
            ],
          ),
          const SizedBox(height: DnsSpacing.xl),
          _buildCopyright(context),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.language,
            size: 36,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: DnsSpacing.md),
        Text(
          l10n.appName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DnsSpacing.xs),
        Text(
          l10n.aboutVersion(AppConfig.appVersion),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DnsSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DnsSpacing.xl),
          child: Text(
            l10n.aboutDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyright(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Text(
        l10n.aboutCopyright,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          height: 1.5,
        ),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
      child: Column(children: children),
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
