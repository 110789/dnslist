import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/credential_state.dart';
import '../../services/credential_storage.dart';
import '../../services/credential_validation.dart';
import '../../drivers/driver_factory.dart';
import '../../utils/status_code_dialog.dart';

class EditCredentialPage extends StatefulWidget {
  final String credentialId;

  const EditCredentialPage({
    super.key,
    required this.credentialId,
  });

  @override
  State<EditCredentialPage> createState() => _EditCredentialPageState();
}

class _EditCredentialPageState extends State<EditCredentialPage> {
  String? _selectedProviderId;
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _remarkController = TextEditingController();
  bool _isInitialized = false;
  bool _isValidating = false;
  String? _errorMessage;
  String? _errorCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCredential();
    });
  }

  void _loadCredential() {
    final credentialState = context.read<CredentialState>();
    final credential = credentialState.credentials.firstWhere(
      (c) => c.id == widget.credentialId,
      orElse: () => throw Exception('Credential not found'),
    );

    setState(() {
      _selectedProviderId = credential.providerId;
      _remarkController.text = credential.remark ?? '';
      
      for (final key in credential.credentials.keys) {
        _controllers[key] = TextEditingController(text: credential.credentials[key]);
      }
      _isInitialized = true;
    });
  }

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
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final drivers = DriverFactory.getAll();

    return Scaffold(
      appBar: AppBar(title: const Text('编辑凭证')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _selectedProviderId,
            decoration: const InputDecoration(labelText: '选择服务商'),
            items: drivers.map((d) => DropdownMenuItem(
              value: d.providerId,
              child: Text(d.providerName),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedProviderId = value;
                _controllers.clear();
                _errorMessage = null;
                _errorCode = null;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _remarkController,
            decoration: const InputDecoration(
              labelText: '备注（可选）',
              hintText: '用于区分不同凭证，如邮箱、用途等',
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedProviderId != null) ..._buildCredentialFields(),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  if (_errorCode != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '状态码: $_errorCode',
                      style: TextStyle(color: Colors.red.shade300, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
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
      setState(() {
        _errorMessage = '请填写密钥信息';
        _errorCode = 'EMPTY_CREDENTIALS';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
      _errorCode = null;
    });

    final result = await CredentialValidationService.validateCredential(
      _selectedProviderId!,
      credentials,
    );

    if (!result['success']) {
      setState(() {
        _errorMessage = result['error'] ?? '凭证校验失败';
        _errorCode = result['errorCode'] ?? 'UNKNOWN';
        _isValidating = false;
      });
      return;
    }

    final remark = _remarkController.text.trim();
    final oldCredential = context.read<CredentialState>().credentials.firstWhere(
      (c) => c.id == widget.credentialId,
    );

    final updatedCredential = CredentialModel(
      id: oldCredential.id,
      providerId: _selectedProviderId!.toLowerCase(),
      providerName: driver.providerName,
      remark: remark.isEmpty ? null : remark,
      credentials: credentials,
      createdAt: oldCredential.createdAt,
    );

    await context.read<CredentialState>().updateCredential(updatedCredential);
    if (mounted) {
      await StatusCodeDialog.showResult(
        context: context,
        success: true,
        message: '更新凭证成功',
        statusCode: result['statusCode'],
      );
      if (mounted) {
        context.pop();
      }
    }
  }
}