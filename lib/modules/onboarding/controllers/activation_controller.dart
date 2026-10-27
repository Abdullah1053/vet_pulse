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

  @override
  void onInit() {
    super.onInit();
    LicenseService.to.refreshDeviceRequestCode();
  }

  void refreshRequestCode() {
    LicenseService.to.refreshDeviceRequestCode();
  }

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
    const phone = DemoConfig.contactPhone; // 967771882350
    String currentCode = requestCode;
    if (currentCode.isEmpty) {
      final fp = await LicenseService.to.getDeviceFingerprint();
      currentCode = LicenseService.to.getDeviceRequestCode(fp);
      LicenseService.to.deviceRequestCode.value = currentCode;
    }

    final message =
        'السلام عليكم ورحمة الله وبركاته،\n'
        'أرغب في تفعيل ترخيص نظام VetPulse لإدارة المنشآت والعيادات البيطرية.\n'
        'معرف الجهاز المعتمد:\n$currentCode';

    // Auto-copy the request code to clipboard first for convenience
    Clipboard.setData(ClipboardData(text: currentCode));

    final encoded = Uri.encodeComponent(message);
    final nativeUrl = Uri.parse('whatsapp://send?phone=$phone&text=$encoded');
    final webUrl = Uri.parse('https://api.whatsapp.com/send?phone=$phone&text=$encoded');
    final waMeUrl = Uri.parse('https://wa.me/$phone?text=$encoded');

    bool launched = false;

    // 1. Try native scheme first (WhatsApp app on mobile / registered desktop client)
    try {
      if (await canLaunchUrl(nativeUrl)) {
        launched = await launchUrl(nativeUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    // 2. Try universal web links with externalApplication (redirects to WhatsApp on mobile / desktop)
    if (!launched) {
      try {
        if (await canLaunchUrl(webUrl)) {
          launched = await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        } else if (await canLaunchUrl(waMeUrl)) {
          launched = await launchUrl(waMeUrl, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }

    // 3. Fallback: Force launch web URL without canLaunchUrl check (handles desktop browsers and restricted intents)
    if (!launched) {
      try {
        launched = await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (_) {
        try {
          launched = await launchUrl(webUrl, mode: LaunchMode.platformDefault);
        } catch (_) {
          try {
            launched = await launchUrl(waMeUrl, mode: LaunchMode.platformDefault);
          } catch (_) {}
        }
      }
    }

    if (!launched) {
      Clipboard.setData(ClipboardData(text: '$phone\n$currentCode'));
      Get.snackbar(
        'تنبيه',
        'تعذر فتح تطبيق واتساب تلقائياً. تم نسخ رقم المطور ($phone) ومعرف الجهاز إلى الحافظة.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber.shade100,
        colorText: Colors.black87,
        duration: const Duration(seconds: 4),
      );
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
