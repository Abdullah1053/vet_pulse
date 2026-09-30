import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService extends GetxService {
  static NotificationService get to => Get.find<NotificationService>();

  final RxBool hasNotificationPermission = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkPermissionStatus();
  }

  Future<void> checkPermissionStatus() async {
    try {
      final status = await Permission.notification.status;
      hasNotificationPermission.value = status.isGranted;
    } catch (_) {
      hasNotificationPermission.value = false;
    }
  }

  Future<bool> requestNotificationPermission({bool showDialogIfDenied = true}) async {
    try {
      final status = await Permission.notification.request();
      hasNotificationPermission.value = status.isGranted;

      if (status.isGranted) {
        Get.snackbar(
          'تم تفعيل الإشعارات بنجاح',
          'ستصلك تنبيهات العمليات الجراحية ومواعيد المراجعات على هاتفك',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          icon: const Icon(Icons.notifications_active, color: Colors.green),
          duration: const Duration(seconds: 3),
        );
        return true;
      } else if (status.isPermanentlyDenied && showDialogIfDenied) {
        _showOpenSettingsDialog();
        return false;
      } else {
        if (showDialogIfDenied) {
          Get.snackbar(
            'تنبيه الإشعارات',
            'يرجى السماح بصلاحية الإشعارات لتصلك تنبيهات العمليات والمراجعات البيطرية',
            backgroundColor: Colors.amber.shade100,
            colorText: Colors.brown.shade900,
            icon: const Icon(Icons.notifications_off, color: Colors.amber),
            duration: const Duration(seconds: 4),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  void _showOpenSettingsDialog() {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_paused, color: Colors.orange),
            SizedBox(width: 8),
            Text('تفعيل إشعارات التطبيق'),
          ],
        ),
        content: const Text(
          'تم رفض صلاحية الإشعارات مسبقاً. للحصول على تذكيرات العمليات الجراحية ومواعيد المراجعات التلقائية، يرجى تفعيل الإشعارات من إعدادات الهاتف.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }
}
