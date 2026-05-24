import 'package:flutter/material.dart';
import '../../architecture/interfaces/domain_provider.dart';
import '../../drivers/driver_factory.dart';

class UxFormDialog extends StatefulWidget {
  final String title;
  final List<ProviderField> fields;
  final Map<String, String> initialValues;
  final Function(Map<String, String>) onSubmit;
  final String submitLabel;
  final String cancelLabel;
  final bool isSubmitting;
  final String? errorMessage;

  const UxFormDialog({
    super.key,
    required this.title,
    required this.fields,
    this.initialValues = const {},
    required this.onSubmit,
    this.submitLabel = 'Save',
    this.cancelLabel = 'Cancel',
    this.isSubmitting = false,
    this.errorMessage,
  });

  static Future<Map<String, String>?> show(
    BuildContext context, {
    required String title,
    required List<ProviderField> fields,
    Map<String, String> initialValues = const {},
    String submitLabel = 'Save',
    String cancelLabel = 'Cancel',
  }) {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => UxFormDialog(
        title: title,
        fields: fields,
        initialValues: initialValues,
        submitLabel: submitLabel,
        cancelLabel: cancelLabel,
        onSubmit: (values) => Navigator.pop(ctx, values),
      ),
    );
  }

  @override
  State<UxFormDialog> createState() => _UxFormDialogState();
}

class _UxFormDialogState extends State<UxFormDialog> {
  late Map<String, TextEditingController> _controllers;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (final field in widget.fields) {
      _controllers[field.key] = TextEditingController(
        text: widget.initialValues[field.key] ?? field.initialValue ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validate() {
    for (final field in widget.fields) {
      if (field.required) {
        final value = _controllers[field.key]?.text ?? '';
        if (value.isEmpty) {
          setState(() => _validationError = 'Please fill in all required fields');
          return false;
        }
      }
    }
    setState(() => _validationError = null);
    return true;
  }

  void _submit() {
    if (!_validate()) return;

    final values = <String, String>{};
    for (final key in _controllers.keys) {
      values[key] = _controllers[key]?.text ?? '';
    }
    widget.onSubmit(values);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...widget.fields.map((field) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: _controllers[field.key],
                decoration: InputDecoration(
                  labelText: field.label,
                  hintText: field.hintText,
                ),
                keyboardType: field.keyboardType,
                obscureText: field.key.toLowerCase().contains('secret'),
              ),
            )),
            if (_validationError != null || widget.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _validationError ?? widget.errorMessage!,
                  style: TextStyle(
                    color: colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isSubmitting ? null : () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: widget.isSubmitting ? null : _submit,
          child: widget.isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.submitLabel),
        ),
      ],
    );
  }
}

class UxCredentialFormDialog extends StatefulWidget {
  final String title;
  final String? selectedProviderId;
  final Function(String providerId, Map<String, String> credentials, String? remark) onSubmit;
  final String submitLabel;
  final String cancelLabel;

  const UxCredentialFormDialog({
    super.key,
    required this.title,
    this.selectedProviderId,
    required this.onSubmit,
    this.submitLabel = 'Save',
    this.cancelLabel = 'Cancel',
  });

  @override
  State<UxCredentialFormDialog> createState() => _UxCredentialFormDialogState();
}

class _UxCredentialFormDialogState extends State<UxCredentialFormDialog> {
  String? _selectedProviderId;
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _remarkController = TextEditingController();
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _selectedProviderId = widget.selectedProviderId;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _remarkController.dispose();
    super.dispose();
  }

  List<dynamic> get _currentFields {
    if (_selectedProviderId == null) return [];
    final driver = DriverFactory.get(_selectedProviderId!);
    if (driver == null) return [];
    final fields = driver.getCredentialFields();
    return fields.entries.map((e) => e).toList();
  }

  @override
  Widget build(BuildContext context) {
    final drivers = DriverFactory.getAll();
    final fields = _currentFields;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedProviderId,
              decoration: const InputDecoration(
                labelText: 'Provider',
              ),
              isExpanded: true,
              items: drivers.map((d) => DropdownMenuItem(
                value: d.providerId,
                child: Text(d.providerName),
              )).toList(),
              onChanged: widget.selectedProviderId != null
                  ? null
                  : (value) => setState(() {
                    _selectedProviderId = value;
                    _controllers.clear();
                  }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarkController,
              decoration: const InputDecoration(
                labelText: 'Remark (Optional)',
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedProviderId != null)
              ...fields.map((field) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _controllers[field.key] ??= TextEditingController(),
                  decoration: InputDecoration(labelText: field.label),
                  obscureText: field.key.toLowerCase().contains('secret'),
                ),
              )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _selectedProviderId != null && !_isValidating
              ? () => _submit()
              : null,
          child: _isValidating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.submitLabel),
        ),
      ],
    );
  }

  void _submit() {
    if (_selectedProviderId == null) return;

    final credentials = <String, String>{};
    for (final key in _controllers.keys) {
      final value = _controllers[key]?.text;
      if (value != null && value.isNotEmpty) {
        credentials[key] = value;
      }
    }

    if (credentials.isEmpty) return;

    setState(() => _isValidating = true);

    widget.onSubmit(
      _selectedProviderId!,
      credentials,
      _remarkController.text.isEmpty ? null : _remarkController.text,
    );
  }
}