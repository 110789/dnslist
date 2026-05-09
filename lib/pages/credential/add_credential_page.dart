import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/credential_state.dart';
import '../../services/credential_storage.dart';
import '../../services/credential_validation.dart';
import '../../drivers/driver_factory.dart';
import '../../utils/toast_util.dart';

class AddCredentialPage extends StatefulWidget {
  const AddCredentialPage({super.key});

  @override
  State<AddCredentialPage> createState() => _AddCredentialPageState();
}

class _AddCredentialPageState extends State<AddCredentialPage> {
  String? _selectedProviderId;
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _remarkController = TextEditingController();
  bool _isValidating = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drivers = DriverFactory.getAll();

    return Scaffold(
      appBar: AppBar(title: const Text('添加凭证')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: '选择服务商'),
            items: drivers.map((d) => DropdownMenuItem(
              value: d.providerId,
              child: Text(d.providerName),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedProviderId = value;
                _controllers.clear();
              });
            },
          ),
          const SizedBox(height: 16),
          if (_selectedProviderId != null) ...[
            TextField(
              controller: _remarkController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                hintText: '用于区分不同凭证，如邮箱、用途等',
              ),
            ),
            const SizedBox(height: 16),
            ..._buildCredentialFields(),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _selectedProviderId != null && !_isValidating ? _saveCredential : null,
            child: _isValidating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCredentialFields() {
    final driver = DriverFactory.get(_selectedProviderId!);
    if (driver == null) return [];

    final fields = driver.getCredentialFields();
    return fields.entries.map((entry) {
      final key = entry.key;
      final label = entry.value;
      _controllers[key] = _controllers[key] ?? TextEditingController();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: _controllers[key],
          decoration: InputDecoration(labelText: label),
          obscureText: key.contains('Secret'),
        ),
      );
    }).toList();
  }

  Future<void> _saveCredential() async {
    if (_selectedProviderId == null) return;

    final driver = DriverFactory.get(_selectedProviderId!);
    if (driver == null) return;

    final credentials = <String, String>{};
    for (final key in _controllers.keys) {
      final value = _controllers[key]?.text;
      if (value != null && value.isNotEmpty) {
        credentials[key] = value;
      }
    }

    if (credentials.isEmpty) {
      ToastUtil.showError(context, '请填写密钥信息', errorCode: 400);
      return;
    }

    setState(() {
      _isValidating = true;
    });

    final result = await CredentialValidationService.validateCredential(
      _selectedProviderId!,
      credentials,
    );

    if (!result['success']) {
      setState(() {
        _isValidating = false;
      });
      if (mounted) {
        ToastUtil.showError(
          context,
          result['error'] ?? '凭证校验失败',
          errorCode: result['errorCode'] != null ? double.tryParse(result['errorCode']) : null,
        );
      }
      return;
    }

    final remark = _remarkController.text.trim();

    final credential = CredentialModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      providerId: _selectedProviderId!.toLowerCase(),
      providerName: driver.providerName,
      remark: remark.isEmpty ? null : remark,
      credentials: credentials,
      createdAt: DateTime.now(),
    );

    await context.read<CredentialState>().addCredential(credential);
    if (mounted) {
      ToastUtil.showSuccess(context, '添加凭证成功');
      context.pop();
    }
  }
}