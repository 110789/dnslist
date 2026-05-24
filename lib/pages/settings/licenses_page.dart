import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';

class LicensesPage extends StatelessWidget {
  const LicensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LicensePage(
      applicationName: AppConfig.appName,
    );
  }
}
