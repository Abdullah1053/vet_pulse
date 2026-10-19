import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/utils/yemeni_phone_validator.dart';
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
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'بيانات وهوية المنشأة البيطرية',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'تظهر هذه البيانات الرسمية والشعار تلقائياً على ترويسة الروشتات الطبية والفواتير وسندات القبض',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 20),

                      // Clinic Logo Upload Section
                      Center(
                        child: Obx(() {
                          final logo = controller.clinicLogoPath.value;
                          return Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              GestureDetector(
                                onTap: controller.pickClinicLogo,
                                child: Container(
                                  width: 104,
                                  height: 104,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryLight.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primary, width: 2.5),
                                    image: logo != null && File(logo).existsSync()
                                        ? DecorationImage(
                                            image: FileImage(File(logo)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: logo == null || !File(logo).existsSync()
                                      ? const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate_outlined,
                                              size: 36,
                                              color: AppColors.primary,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'شعار العيادة',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: controller.pickClinicLogo,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                              if (logo != null && File(logo).existsSync())
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: GestureDetector(
                                    onTap: controller.removeClinicLogo,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade700,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: 22),

                      // Clinic Name
                      CustomTextField(
                        label: '${AppStringsAr.clinicName} *',
                        hint: 'مثال: عيادة الرعاية البيطرية المتقدمة',
                        controller: controller.clinicNameController,
                        prefixIcon: const Icon(Icons.business_outlined, color: AppColors.primary),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم المنشأة البيطرية مطلوب' : null,
                      ),
                      const SizedBox(height: 16),

                      // Responsible Doctor
                      CustomTextField(
                        label: '${AppStringsAr.doctorName} (الطبيب المسؤول) *',
                        hint: 'مثال: د. أحمد محمد السالم',
                        controller: controller.doctorNameController,
                        prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'اسم الطبيب المسؤول مطلوب' : null,
                      ),
                      const SizedBox(height: 16),

                      // Practice License Number
                      CustomTextField(
                        label: '${AppStringsAr.licenseNumber} *',
                        hint: 'رقم ترخيص مزاولة المهنة المعتمد',
                        controller: controller.licenseController,
                        prefixIcon: const Icon(Icons.verified_outlined, color: AppColors.primary),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'رقم ترخيص مزاولة المهنة مطلوب' : null,
                      ),
                      const SizedBox(height: 16),

                      // Official Clinic Phone
                      CustomTextField(
                        label: '${AppStringsAr.phone} (رقم يمني رسمي +967) *',
                        hint: '77xxxxxxx أو 78 أو 73 أو 70 أو 71',
                        controller: controller.phoneController,
                        keyboardType: TextInputType.phone,
                        prefixText: '+967 ',
                        textDirection: TextDirection.ltr,
                        maxLength: 9,
                        validator: (v) => YemeniPhoneValidator.validate(v, isRequired: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),

                      // Clinic Address
                      CustomTextField(
                        label: '${AppStringsAr.address} *',
                        hint: 'المدينة، الحي، الشارع الرئيسي',
                        controller: controller.addressController,
                        prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'عنوان المنشأة البيطرية مطلوب' : null,
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
