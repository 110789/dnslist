import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dlist/generated/l10n/app_localizations.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/ui/md3_widgets.dart';
import '../../core/theme/design_system.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  static const _languages = <_LanguageEntry>[
    _LanguageEntry(
      locale: null,
      flag: '',
      labelKey: _LabelKey.system,
    ),
    _LanguageEntry(
      locale: Locale('en'),
      flag: '\u{1F1EC}\u{1F1E7}',
      labelKey: _LabelKey.specific,
    ),
    _LanguageEntry(
      locale: Locale('zh'),
      flag: '\u{1F1E8}\u{1F1F3}',
      labelKey: _LabelKey.specific,
    ),
    _LanguageEntry(
      locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      flag: '\u{1F1F9}\u{1F1FC}',
      labelKey: _LabelKey.specific,
    ),
    _LanguageEntry(
      locale: Locale('ja'),
      flag: '\u{1F1EF}\u{1F1F5}',
      labelKey: _LabelKey.specific,
    ),
    _LanguageEntry(
      locale: Locale('ko'),
      flag: '\u{1F1F0}\u{1F1F7}',
      labelKey: _LabelKey.specific,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.settingsLanguage),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: DnsSpacing.sm),
        children: [
          const SizedBox(height: DnsSpacing.sm),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: DnsSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(DnsRadius.md),
            ),
            child: Column(
              children: _languages.map((entry) {
                final isSelected = entry.isSelected(localeProvider);
                final label = entry.label(l10n);
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onSelect(context, localeProvider, entry),
                    borderRadius: BorderRadius.circular(DnsRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DnsSpacing.md,
                        vertical: DnsSpacing.sm + 2,
                      ),
                      child: Row(
                        children: [
                          if (entry.flag.isNotEmpty)
                            Text(
                              entry.flag,
                              style: const TextStyle(fontSize: 24),
                            )
                          else
                            Icon(
                              Icons.settings_suggest_outlined,
                              size: 24,
                              color: colorScheme.onSurfaceVariant,
                            ),
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
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _onSelect(BuildContext context, LocaleProvider provider, _LanguageEntry entry) {
    provider.setLocale(entry.locale);
  }
}

enum _LabelKey { system, specific }

class _LanguageEntry {
  final Locale? locale;
  final String flag;
  final _LabelKey labelKey;

  const _LanguageEntry({
    required this.locale,
    required this.flag,
    required this.labelKey,
  });

  bool isSelected(LocaleProvider provider) {
    if (locale == null) return provider.useSystemLocale;
    if (provider.locale == null) return false;
    if (locale!.scriptCode != null) {
      return provider.locale!.languageCode == locale!.languageCode &&
          provider.locale!.scriptCode == locale!.scriptCode;
    }
    return provider.locale!.languageCode == locale!.languageCode &&
        provider.locale!.scriptCode == null;
  }

  String label(AppLocalizations l10n) {
    switch (labelKey) {
      case _LabelKey.system:
        return l10n.languageSystem;
      case _LabelKey.specific:
        if (locale == null) return '';
        if (locale!.languageCode == 'en') return l10n.languageEn;
        if (locale!.languageCode == 'zh' && locale!.scriptCode == 'Hant') return l10n.languageZhHant;
        if (locale!.languageCode == 'zh') return l10n.languageZhHans;
        if (locale!.languageCode == 'ja') return l10n.languageJa;
        if (locale!.languageCode == 'ko') return l10n.languageKo;
        return '';
    }
  }
}
