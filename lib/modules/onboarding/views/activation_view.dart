import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/license_service.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../controllers/activation_controller.dart';

class ActivationView extends GetView<ActivationController> {
  const ActivationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('توثيق وتفعيل ترخيص النظام'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Reassuring Expiration Banner if redirected due to expiry
                  Obx(() {
                    if (!LicenseService.to.isExpired.value) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.shade400, width: 1.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shield_outlined, color: Colors.amber.shade900, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تنبيه انتهاء فترة الترخيص',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'انتهت صلاحية ترخيص النسخة الحالية — جميع بيانات العيادة والمرضى والحسابات المالية محفوظة وآمنة بالكامل. يرجى إدخال كود التفعيل الجديد لاستئناف العمل فوراً.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textPrimary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Device Request ID Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.fingerprint_rounded,
                                  color: AppColors.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'معرف الجهاز المعتمد (Device Request ID)',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'بصمة رقمية مشفرة خاصة بجهازكم هذا فقط',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Request Code Box with Selectable / Copyable text
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Obx(() => SelectableText(
                                  controller.requestCode,
                                  textDirection: TextDirection.ltr,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: AppColors.primaryDark,
                                  ),
                                )),
                          ),
                          const SizedBox(height: 16),

                          // Copy & WhatsApp Actions
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    side: const BorderSide(color: AppColors.primary),
                                    foregroundColor: AppColors.primary,
                                  ),
                                  icon: const Icon(Icons.copy_rounded, size: 18),
                                  label: const Text(
                                    'نسخ المعرف',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  onPressed: controller.copyRequestCode,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF25D366),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.chat_rounded, size: 18),
                                  label: const Text(
                                    'إرسال للمطور عبر واتساب',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  onPressed: controller.sendWhatsAppToDeveloper,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Clear Instructions Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'خطوات التفعيل:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. انسخ "معرف الجهاز" أعلاه أو اضغط زر "إرسال للمطور عبر واتساب".\n'
                          '2. أرسل المعرف إلى المطور المعتمد للتحقق وتوليد كود تفعيل موثق لجهازكم.\n'
                          '3. الصق كود التفعيل المستلم في الحقل أدناه واضغط زر التفعيل.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            height: 1.6,
                          ),
                        ),
                        const Divider(height: 18),
                        Row(
                          children: [
                            const Icon(Icons.support_agent_rounded, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'المطور: ${DemoConfig.developerName} (${DemoConfig.contactPhoneDisplay})',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Enter Activation Code Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'إدخال كود التفعيل المعتمد',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'مثال: VPACT-20261125-9A7F-A1B2C3D4E5F6',
                            textDirection: TextDirection.ltr,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 14),

                          CustomTextField(
                            label: 'كود التفعيل (Activation Code) *',
                            hint: 'VPACT-YYYYMMDD-XXXX-XXXXXXXXXXXX',
                            controller: controller.codeController,
                            textDirection: TextDirection.ltr,
                            prefixIcon: const Icon(Icons.key_rounded, color: AppColors.primary),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
                            ],
                          ),
                          const SizedBox(height: 20),

                          Obx(() => PrimaryButton(
                                text: 'تفعيل النسخة وتوثيق الجهاز',
                                icon: Icons.verified_user_rounded,
                                isLoading: controller.isLoading.value,
                                onPressed: controller.activateLicense,
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
