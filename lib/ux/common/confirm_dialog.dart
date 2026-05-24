import 'package:flutter/material.dart';

abstract class UxLocalizedStrings {
  String get deleteTitle;
  String get deleteMessage;
  String get deleteConfirm;
  String get cancel;
  String get confirm;
  String get add;
  String get save;
  String get error;
  String get success;
  String get loading;
  String get emptyTitle;
  String get emptyDescription;
  String get errorTitle;
}

class DefaultLocalizedStrings implements UxLocalizedStrings {
  const DefaultLocalizedStrings();

  @override
  String get deleteTitle => 'Confirm Delete';
  @override
  String get deleteMessage => 'Are you sure you want to delete this item? This action cannot be undone.';
  @override
  String get deleteConfirm => 'Delete';
  @override
  String get cancel => 'Cancel';
  @override
  String get confirm => 'Confirm';
  @override
  String get add => 'Add';
  @override
  String get save => 'Save';
  @override
  String get error => 'Error';
  @override
  String get success => 'Success';
  @override
  String get loading => 'Loading...';
  @override
  String get emptyTitle => 'No Data';
  @override
  String get emptyDescription => 'No data available';
  @override
  String get errorTitle => 'Error Occurred';
}

class UxConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const UxConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    required this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => UxConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(title),
      content: Text(
        message,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          onPressed: onConfirm,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

class UxLoadingDialog extends StatelessWidget {
  final String? message;

  const UxLoadingDialog({super.key, this.message});

  static Future<T?> show<T>(
    BuildContext context, {
    String? message,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UxLoadingDialog(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(width: 16),
            Text(message!),
          ],
        ],
      ),
    );
  }
}