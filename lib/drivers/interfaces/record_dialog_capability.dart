import 'package:flutter/material.dart';

abstract class RecordDialogCapability {
  void showAddRecordDialog(
    BuildContext context, {
    required Future<Map<String, dynamic>> Function(Map<String, dynamic>) onSubmit,
  });

  void showEditRecordDialog(
    BuildContext context,
    Map<String, dynamic> record, {
    required Future<Map<String, dynamic>> Function(Map<String, dynamic>) onSubmit,
  });
}