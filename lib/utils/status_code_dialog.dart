import 'package:flutter/material.dart';

class StatusCodeDialog {
  static Future<void> showResult({
    required BuildContext context,
    required bool success,
    String? message,
    String? statusCode,
    String? errorCode,
  }) async {
    final displayMessage = message ?? (success ? '操作成功' : '操作失败');
    final fullMessage = errorCode != null || statusCode != null
        ? '$displayMessage\n${errorCode != null ? '错误码: $errorCode' : ''}${statusCode != null ? '\nHTTP状态: $statusCode' : ''}'
        : displayMessage;

    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(success ? '成功' : '失败'),
          ],
        ),
        content: Text(fullMessage.trim()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  static void showSnackBar({
    required BuildContext context,
    required bool success,
    String? message,
    String? statusCode,
  }) {
    final displayMessage = message ?? (success ? '操作成功' : '操作失败');
    final fullMessage = statusCode != null
        ? '$displayMessage\n状态码: $statusCode'
        : displayMessage;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(fullMessage),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}