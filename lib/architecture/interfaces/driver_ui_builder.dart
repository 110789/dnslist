import 'package:flutter/material.dart';
import 'domain_provider.dart';

abstract class DriverUiBuilder {
  Widget buildDomainListItem(
    DomainRecord domain, {
    required VoidCallback onTap,
    required VoidCallback onDelete,
    required VoidCallback onRenew,
    required VoidCallback onShowNameServers,
  });

  Widget buildDnsRecordListItem(DnsRecord record);

  void showDomainListItemMenu(
    BuildContext context,
    DomainRecord domain, {
    required VoidCallback onDelete,
    required VoidCallback onRenew,
    required VoidCallback onShowNameServers,
  });

  Widget buildEmptyState({
    required IconData icon,
    required String title,
    String? description,
    Widget? action,
  });

  Widget buildErrorState({
    required String message,
    VoidCallback? onRetry,
  });

  Widget buildLoadingState({String? message});

  String getLocalizedString(String key);

  Map<String, String> get localizedStrings;
}

abstract class DriverRecordFormBuilder {
  List<ProviderField> getAddRecordFields();

  List<ProviderField> getEditRecordFields(DnsRecord record);

  DnsRecord prepareRecordData({
    required Map<String, String> fieldValues,
    required String recordType,
    bool isEdit = false,
  });

  String getAddRecordTitle();

  String getEditRecordTitle();

  bool supportsRecordLine();

  List<String> getSupportedRecordTypes();

  Widget buildAddRecordDialog({
    required BuildContext context,
    required String domainId,
    required Function(Map<String, dynamic>) onSubmit,
    required Future<Map<String, dynamic>> Function(Map<String, dynamic>) onSubmitAsync,
  });

  Widget buildEditRecordDialog({
    required BuildContext context,
    required DnsRecord record,
    required Function(Map<String, dynamic>) onSubmit,
    required Future<Map<String, dynamic>> Function(Map<String, dynamic>) onSubmitAsync,
  });
}

class DriverLocalizedStrings {
  final Map<String, String> _strings;

  const DriverLocalizedStrings(this._strings);

  String get(String key) => _strings[key] ?? key;

  static DriverLocalizedStrings fromJson(Map<String, dynamic> json) {
    final strings = json.map((k, v) => MapEntry(k, v.toString()));
    return DriverLocalizedStrings(strings);
  }

  Map<String, String> get all => _strings;
}

class DriverUiConstants {
  static const double horizontalPadding = 16;
  static const double verticalPadding = 12;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double avatarSize = 44;
}

class DriverStatusMapper {
  static String mapStatus(String? status) {
    final statusMap = {
      'active': 'Active',
      'pending': 'Pending',
      'expired': 'Expired',
      'suspended': 'Suspended',
      'deleted': 'Deleted',
      'ok': 'Active',
      'pendingdelete': 'Pending Delete',
    };
    return statusMap[status?.toLowerCase()] ?? status ?? '';
  }

  static Color getStatusColor(String status, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'active':
      case 'ok':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'expired':
      case 'suspended':
      case 'deleted':
      case 'pendingdelete':
        return colorScheme.error;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }
}