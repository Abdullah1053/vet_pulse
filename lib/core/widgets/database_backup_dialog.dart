import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class DatabaseBackupDialog extends StatelessWidget {
  const DatabaseBackupDialog({super.key});

  static Future<T?>? show<T>([BuildContext? context]) =>
      Get.toNamed<T>(AppRoutes.databaseBackup);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offNamed(AppRoutes.databaseBackup);
    });
    return const SizedBox.shrink();
  }
}
