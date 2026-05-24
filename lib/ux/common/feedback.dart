import 'package:flutter/material.dart';

class UxFeedbackService {
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showError(BuildContext context, String message, {String? errorCode}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: errorCode != null
            ? SnackBarAction(
                label: errorCode,
                textColor: colorScheme.onError,
                onPressed: () {},
              )
            : null,
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.secondaryContainer,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showWarning(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class UxErrorHandler {
  final String? error;
  final String? errorCode;
  final String? customMessage;

  const UxErrorHandler({
    this.error,
    this.errorCode,
    this.customMessage,
  });

  String getDisplayMessage(BuildContext context, {String defaultMessage = 'An error occurred'}) {
    if (customMessage != null && customMessage!.isNotEmpty) {
      return customMessage!;
    }
    if (error != null && error!.isNotEmpty) {
      return error!;
    }
    return defaultMessage;
  }

  static String mapErrorCode(String code, {String locale = 'en'}) {
    final errorMappings = {
      'AUTH_FAILED': 'Authentication failed',
      'INVALID_CREDENTIAL': 'Invalid credentials',
      'NETWORK_ERROR': 'Network error occurred',
      'SERVER_ERROR': 'Server error',
      'TIMEOUT': 'Request timeout',
      'NOT_FOUND': 'Resource not found',
      'PERMISSION_DENIED': 'Permission denied',
      'RATE_LIMITED': 'Too many requests',
    };

    return errorMappings[code] ?? code;
  }
}

class UxToast {
  static void show(BuildContext context, String message, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}