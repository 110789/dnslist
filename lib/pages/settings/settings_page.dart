import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/credential_state.dart';
import '../../utils/status_code_dialog.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final credentialState = context.watch<CredentialState>();

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('凭证管理'),
            subtitle: Text('管理已添加的服务商凭证'),
          ),
          const Divider(),
          ...credentialState.credentials.map((c) => ListTile(
                leading: const Icon(Icons.key),
                title: Text(c.providerName),
                subtitle: Text('添加于 ${c.createdAt.toString().split(' ')[0]}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteDialog(context, c.id, c.providerName),
                ),
              )),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('添加凭证'),
            onTap: () => context.push('/settings/credential/add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除凭证'),
        content: Text('确定要删除 $name 的凭证吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              context.read<CredentialState>().removeCredential(id);
              Navigator.pop(ctx);
              await StatusCodeDialog.showResult(
                context: context,
                success: true,
                message: '删除凭证成功',
              );
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}