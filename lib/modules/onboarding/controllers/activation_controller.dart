import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/services/license_service.dart';
import '../../../routes/app_routes.dart';

class ActivationController extends GetxController {
  final TextEditingController codeController = TextEditingController();
  final RxBool isLoading = false.obs;

  String get requestCode => LicenseService.to.deviceRequestCode.value;
  bool get isExpired => LicenseService.to.isExpired.value;

  void copyRequestCode() {
    Clipboard.setData(ClipboardData(text: requestCode));
    Get.snackbar(
      'تم النسخ',
      'تم نسخ معرف الجهاز إلى الحافظة بنجاح',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.teal.shade100,
      colorText: Colors.black87,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> sendWhatsAppToDeveloper() async {
    final phone = DemoConfig.contactPhone.replaceAll(RegExp(r'\D'), '');
    final fullPhone = phone.startsWith('967') ? phone : '967$phone';
    final message = Uri.encodeComponent(
      'السلام عليكم ورحمة الله وبركاته،\n'
      'أرغب في تفعيل ترخيص نظام VetPulse لإدارة المنشآت والعيادات البيطرية.\n'
      'معرف الجهاز المعتمد:\n$requestCode',
    );
    final url = Uri.parse('https://wa.me/$fullPhone?text=$message');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('تنبيه', 'تعذر فتح تطبيق واتساب مباشرة');
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء فتح واتساب: $e');
    }
  }

  Future<void> activateLicense() async {
    final code = codeController.text.trim();
    if (code.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يرجى إدخال كود التفعيل المستلم من المطور',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber.shade100,
        colorText: Colors.black87,
      );
      return;
    }

    isLoading.value = true;
    try {
      final success = await LicenseService.to.verifyAndActivateCode(code);
      if (success) {
        codeController.clear();
        if (LicenseService.to.clinicSetupCompleted.value) {
          Get.offAllNamed(AppRoutes.login);
        } else {
          Get.offAllNamed(AppRoutes.clinicSetup);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    codeController.dispose();
    super.onClose();
  }
}
