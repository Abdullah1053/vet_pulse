import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../routes/app_routes.dart';
import '../controllers/auth_controller.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Logo & Title
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryLight, width: 2),
                        ),
                        child: const Icon(
                          Icons.pets,
                          size: 38,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStringsAr.appName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStringsAr.appSubTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Form Fields
                      CustomTextField(
                        label: AppStringsAr.username,
                        hint: 'اسم المستخدم (افتراضي: admin)',
                        controller: controller.usernameController,
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: AppStringsAr.password,
                        hint: 'كلمة المرور (افتراضي: admin123)',
                        controller: controller.passwordController,
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                        onSubmitted: (_) => controller.login(),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      Obx(() => PrimaryButton(
                            text: AppStringsAr.login,
                            isLoading: controller.isLoading.value,
                            icon: Icons.login,
                            onPressed: controller.login,
                          )),
                      const SizedBox(height: 16),

                      // Quick PIN Unlock Option
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () => Get.toNamed(AppRoutes.pinLock),
                            icon: const Icon(Icons.pin_outlined, size: 18),
                            label: const Text(AppStringsAr.quickUnlock),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Clinic Profile Setup Link
                      OutlinedButton.icon(
                        onPressed: () => Get.toNamed(AppRoutes.clinicSetup),
                        icon: const Icon(Icons.local_hospital_outlined, size: 18),
                        label: const Text(AppStringsAr.clinicSetupTitle),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
