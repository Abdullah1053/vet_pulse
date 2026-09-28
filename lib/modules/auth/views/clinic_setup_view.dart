import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../controllers/auth_controller.dart';

class ClinicSetupView extends GetView<AuthController> {
  const ClinicSetupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStringsAr.clinicSetupTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'بيانات وهوية المنشأة البيطرية',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'تظهر هذه البيانات تلقائياً على ترويسة الروشتات الطبية والفواتير المطبوعة',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        label: AppStringsAr.clinicName,
                        hint: 'مثال: عيادة الرعاية البيطرية',
                        controller: controller.clinicNameController,
                        prefixIcon: const Icon(Icons.business_outlined),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: AppStringsAr.doctorName,
                        hint: 'مثال: د. أحمد محمد',
                        controller: controller.doctorNameController,
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: AppStringsAr.licenseNumber,
                        hint: 'رقم الترخيص المهني الصادر من الوزارة',
                        controller: controller.licenseController,
                        prefixIcon: const Icon(Icons.verified_outlined),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: AppStringsAr.phone,
                        hint: 'رقم هاتف العيادة أو الواتساب الرسمي',
                        controller: controller.phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: AppStringsAr.address,
                        hint: 'المدينة، الحي، الشارع',
                        controller: controller.addressController,
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                      const SizedBox(height: 28),
                      Obx(() => PrimaryButton(
                            text: AppStringsAr.save,
                            isLoading: controller.isLoading.value,
                            icon: Icons.check,
                            onPressed: controller.saveClinicProfile,
                          )),
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
