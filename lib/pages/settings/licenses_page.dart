import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

class LicensesPage extends StatelessWidget {
  const LicensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('开源许可'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: LicensePage(
        applicationName: AppConfig.appName,
        applicationVersion: '版本 ${AppConfig.appVersion}',
        applicationLegalese: 'Copyright 2026 DNS管理工具. All rights reserved.',
        applicationIcon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.language,
            size: 32,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
