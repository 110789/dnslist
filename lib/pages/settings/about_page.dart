import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dlist/generated/l10n/app_localizations.dart';
import '../../core/config/app_config.dart';
import '../../core/router/app_router.dart';
import '../../core/ui/md3_widgets.dart';
import '../../core/theme/design_system.dart';
import '../../services/update_provider.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UpdateProvider>().addListener(_onUpdateStateChanged);
    });
  }

  @override
  void dispose() {
    // Avoid calling listen after dispose
    super.dispose();
  }

  void _onUpdateStateChanged() {
    if (!mounted) return;
    final provider = context.read<UpdateProvider>();
    switch (provider.status) {
      case UpdateStatus.noUpdate:
        _showToast(context, AppLocalizations.of(context)!.updateNoUpdate);
        provider.reset();
      case UpdateStatus.available:
        _showUpdateDialog();
      case UpdateStatus.downloaded:
        _showInstallDialog();
      case UpdateStatus.error:
        if (provider.errorMessage.isNotEmpty) {
          _showToast(context, AppLocalizations.of(context)!.updateError(provider.errorMessage));
          provider.reset();
        }
      default:
        break;
    }
  }

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
                onTap: () => _launchUrl(context, 'https://github.com/lioisme/dnslist'),
                showDivider: true,
              ),
              _SettingsTile(
                icon: Icons.system_update_outlined,
                title: AppLocalizations.of(context)!.updateCheck,
                subtitle: AppLocalizations.of(context)!.updateCurrentVersion(AppConfig.appVersion),
                onTap: _onCheckUpdate,
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

  Future<void> _onCheckUpdate() async {
    final provider = context.read<UpdateProvider>();
    final l10n = AppLocalizations.of(context)!;
    await provider.checkForUpdate();
    if (provider.status == UpdateStatus.noUpdate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.updateNoUpdate),
            behavior: SnackBarBehavior.floating,
          ),
        );
        provider.reset();
      }
    }
  }

  void _showUpdateDialog() {
    final provider = context.read<UpdateProvider>();
    final release = provider.releaseInfo;
    if (release == null) return;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            l10n.updateAvailable(release.version),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.updateCurrentVersion(AppConfig.appVersion),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DnsSpacing.sm),
                Text(
                  l10n.updateLatestVersion(release.version),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (release.body.isNotEmpty) ...[
                  const SizedBox(height: DnsSpacing.md),
                  Text(
                    l10n.updateChangelog,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: DnsSpacing.xs),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(DnsRadius.sm),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(DnsSpacing.sm),
                      child: Text(
                        release.body,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                provider.reset();
              },
              child: Text(l10n.updateLater),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                provider.downloadUpdate();
                _showDownloadProgress();
              },
              child: Text(l10n.updateDownload),
            ),
          ],
        );
      },
    );
  }

  void _showDownloadProgress() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Consumer<UpdateProvider>(
          builder: (context, provider, _) {
            return AlertDialog(
              title: Text(l10n.updateCheck),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: provider.progress),
                  const SizedBox(height: DnsSpacing.md),
                  Text(
                    l10n.updateDownloading((provider.progress * 100).toInt()),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    provider.cancelDownload();
                    Navigator.of(ctx).pop();
                  },
                  child: Text(l10n.updateCancel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showInstallDialog() {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.read<UpdateProvider>();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            l10n.updateInstall,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            l10n.updateAvailable(provider.releaseInfo?.version ?? ''),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                provider.reset();
              },
              child: Text(l10n.updateLater),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                provider.installUpdate();
              },
              child: Text(l10n.updateInstall),
            ),
          ],
        );
      },
    );
  }

  void _showToast(BuildContext context, String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
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
  final Widget? trailing;
  final bool showDivider;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
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
                  if (trailing != null) ...[
                    trailing!,
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
