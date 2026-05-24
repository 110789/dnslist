import 'package:flutter/material.dart';
import 'package:dlist/generated/l10n/app_localizations.dart';
import '../../drivers/interfaces/driver_interface.dart';

class DriverLocalizations {
  static String addDomainTitle(BuildContext context, DriverInterface driver) {
    final l10n = AppLocalizations.of(context)!;
    final getter = _titleGetters[driver.providerId];
    return getter != null ? getter(l10n) : driver.getAddDomainTitle();
  }

  static String addRecordTitle(BuildContext context, DriverInterface driver) {
    final l10n = AppLocalizations.of(context)!;
    final getter = _addRecordGetters[driver.providerId];
    return getter != null ? getter(l10n) : driver.getAddRecordTitle();
  }

  static String editRecordTitle(BuildContext context, DriverInterface driver) {
    final l10n = AppLocalizations.of(context)!;
    final getter = _editRecordGetters[driver.providerId];
    return getter != null ? getter(l10n) : driver.getEditRecordTitle();
  }

  static String fieldLabel(AppLocalizations l10n, String providerId, String fieldKey, String fallback) {
    final value = _labelFieldGetters[providerId]?[fieldKey]?.call(l10n);
    return value ?? fallback;
  }

  static String fieldHint(AppLocalizations l10n, String providerId, String fieldKey, String fallback) {
    final value = _hintFieldGetters[providerId]?[fieldKey]?.call(l10n);
    return value ?? fallback;
  }

  static String fieldDesc(AppLocalizations l10n, String providerId, String fieldKey, String fallback) {
    final value = _descFieldGetters[providerId]?[fieldKey]?.call(l10n);
    return value ?? fallback;
  }

  static String credentialFieldLabel(AppLocalizations l10n, String providerId, String fieldKey, String fallback) {
    final value = _credentialGetters[providerId]?[fieldKey]?.call(l10n);
    return value ?? fallback;
  }

  static final Map<String, String Function(AppLocalizations)> _titleGetters = {
    'cloudflare': (l) => l.driverCloudflareAddDomainTitle,
    'dnspod': (l) => l.driverDnspodAddDomainTitle,
    'dnshe': (l) => l.driverDnsheAddDomainTitle,
    'cloudns': (l) => l.driverCloudnsAddDomainTitle,
    'digitalplat': (l) => l.driverDigitalplatAddDomainTitle,
    'rainyun': (l) => l.driverRainyunAddDomainTitle,
  };

  static final Map<String, String Function(AppLocalizations)> _addRecordGetters = {
    'cloudflare': (l) => l.driverCloudflareAddRecordTitle,
    'dnspod': (l) => l.driverDnspodAddRecordTitle,
    'dnshe': (l) => l.driverDnsheAddRecordTitle,
    'cloudns': (l) => l.driverCloudnsAddRecordTitle,
    'rainyun': (l) => l.driverRainyunAddRecordTitle,
  };

  static final Map<String, String Function(AppLocalizations)> _editRecordGetters = {
    'cloudflare': (l) => l.driverCloudflareEditRecordTitle,
    'dnspod': (l) => l.driverDnspodEditRecordTitle,
    'dnshe': (l) => l.driverDnsheEditRecordTitle,
    'cloudns': (l) => l.driverCloudnsEditRecordTitle,
    'rainyun': (l) => l.driverRainyunEditRecordTitle,
  };

  static final Map<String, Map<String, String Function(AppLocalizations)>> _labelFieldGetters = {
    'cloudflare': {
      'domain': (l) => l.driverCloudflareDomainFieldLabel,
      'name': (l) => l.driverCloudflareRecordNameLabel,
      'content': (l) => l.driverCloudflareContentLabel,
      'ttl': (l) => l.driverCloudflareTtlLabel,
    },
    'dnspod': {
      'domain': (l) => l.driverDnspodDomainFieldLabel,
      'name': (l) => l.driverDnspodRecordNameLabel,
      'value': (l) => l.driverDnspodContentLabel,
      'ttl': (l) => l.driverDnspodTtlLabel,
    },
    'cloudns': {
      'domain': (l) => l.driverCloudnsDomainFieldLabel,
      'name': (l) => l.driverCloudnsRecordNameLabel,
      'content': (l) => l.driverCloudnsContentLabel,
      'ttl': (l) => l.driverCloudnsTtlLabel,
    },
    'dnshe': {
      'subdomain': (l) => l.driverDnsheSubdomainLabel,
      'domain': (l) => l.driverDnsheRootDomainLabel,
      'name': (l) => l.driverDnsheRecordNameLabel,
      'ttl': (l) => l.driverDnsheTtlLabel,
      'priority': (l) => l.driverDnshePriorityLabel,
      'port': (l) => l.driverDnshePortLabel,
      'weight': (l) => l.driverDnsheWeightLabel,
    },
    'digitalplat': {
      'domain': (l) => l.driverDigitalplatDomainFieldLabel,
      'type': (l) => l.driverDigitalplatTypeLabel,
    },
    'rainyun': {
      'domain': (l) => l.driverRainyunDomainFieldLabel,
      'name': (l) => l.driverRainyunRecordNameLabel,
      'value': (l) => l.driverRainyunContentLabel,
      'ttl': (l) => l.driverRainyunTtlLabel,
    },
  };

  static final Map<String, Map<String, String Function(AppLocalizations)>> _hintFieldGetters = {
    'cloudflare': {
      'domain': (l) => l.driverCloudflareDomainFieldHint,
      'name': (l) => l.driverCloudflareRecordNameHint,
      'content': (l) => l.driverCloudflareContentHint,
      'ttl': (l) => l.driverCloudflareTtlHint,
    },
    'dnspod': {
      'domain': (l) => l.driverDnspodDomainFieldHint,
      'name': (l) => l.driverDnspodRecordNameHint,
      'value': (l) => l.driverDnspodContentHint,
      'ttl': (l) => l.driverDnspodTtlHint,
    },
    'cloudns': {
      'domain': (l) => l.driverCloudnsDomainFieldHint,
      'name': (l) => l.driverCloudnsRecordNameHint,
      'content': (l) => l.driverCloudnsContentHint,
      'ttl': (l) => l.driverCloudnsTtlHint,
    },
    'dnshe': {
      'subdomain': (l) => l.driverDnsheSubdomainHint,
      'domain': (l) => l.driverDnsheRootDomainHint,
      'name': (l) => l.driverDnsheRecordNameHint,
      'ttl': (l) => l.driverDnsheTtlHint,
      'priority': (l) => l.driverDnshePriorityHint,
      'port': (l) => l.driverDnshePortHint,
      'weight': (l) => l.driverDnsheWeightHint,
    },
    'digitalplat': {
      'domain': (l) => l.driverDigitalplatDomainFieldHint,
      'type': (l) => l.driverDigitalplatTypeHint,
    },
    'rainyun': {
      'domain': (l) => l.driverRainyunDomainFieldHint,
      'name': (l) => l.driverRainyunRecordNameHint,
      'value': (l) => l.driverRainyunContentHint,
      'ttl': (l) => l.driverRainyunTtlHint,
    },
  };

  static final Map<String, Map<String, String Function(AppLocalizations)>> _descFieldGetters = {
    'dnspod': {
      'domain': (l) => l.driverDnspodDomainFieldDesc,
    },
    'cloudns': {
      'domain': (l) => l.driverCloudnsDomainFieldDesc,
    },
    'dnshe': {
      'domain': (l) => l.driverDnsheRootDomainDesc('', ''),
    },
    'digitalplat': {
      'domain': (l) => l.driverDigitalplatDomainFieldDesc,
      'type': (l) => l.driverDigitalplatTypeDesc,
    },
    'rainyun': {
      'domain': (l) => l.driverRainyunDomainFieldDesc,
    },
  };

  static final Map<String, Map<String, String Function(AppLocalizations)>> _credentialGetters = {
    'cloudflare': {
      'api_token': (l) => l.driverCloudflareCredentialApiToken,
    },
    'dnspod': {
      'secret_id': (l) => l.driverDnspodCredentialSecretId,
      'secret_key': (l) => l.driverDnspodCredentialSecretKey,
    },
    'cloudns': {
      'auth_id': (l) => l.driverCloudnsCredentialAuthId,
      'auth_password': (l) => l.driverCloudnsCredentialAuthPassword,
    },
    'dnshe': {
      'api_key': (l) => l.driverDnsheCredentialApiKey,
      'api_secret': (l) => l.driverDnsheCredentialApiSecret,
    },
    'digitalplat': {
      'api_token': (l) => l.driverDigitalplatCredentialApiToken,
    },
    'rainyun': {
      'api_key': (l) => l.driverRainyunCredentialApiKey,
    },
  };
}
