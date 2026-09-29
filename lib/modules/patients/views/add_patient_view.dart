import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../controllers/patient_controller.dart';

class AddPatientView extends GetView<PatientController> {
  const AddPatientView({super.key});

  void _showImageSourceBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'اختيار صورة المريض البيطري',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondaryLight,
                  child: Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('التقاط صورة بالكاميرا'),
                subtitle: const Text('التقاط صورة سريرية للحيوان مباشرة عبر الكاميرا'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  controller.pickPetPhoto(ImageSource.camera);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondaryLight,
                  child: Icon(Icons.photo_library, color: AppColors.primary),
                ),
                title: const Text('اختيار من المعرض / الملفات'),
                subtitle: const Text('اختيار صورة محفوظة للحيوان من ذاكرة الجهاز'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  controller.pickPetPhoto(ImageSource.gallery);
                },
              ),
              if (controller.petPhotoPath.value != null) ...[
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEBEE),
                    child: Icon(Icons.delete_outline, color: AppColors.critical),
                  ),
                  title: const Text('إزالة الصورة الحالية', style: TextStyle(color: AppColors.critical)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    controller.clearPetPhoto();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              controller.isEditing.value ? 'تعديل بيانات المريض البيطري' : AppStringsAr.newPetAction,
            )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Pet Details Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بيانات المريض (الحيوان)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Pet Photo Avatar / Upload Box
                    Center(
                      child: Obx(() {
                        final photo = controller.petPhotoPath.value;
                        return Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            GestureDetector(
                              onTap: () => _showImageSourceBottomSheet(context),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryLight.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 2),
                                  image: photo != null
                                      ? DecorationImage(
                                          image: FileImage(File(photo)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: photo == null
                                    ? const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.primary),
                                          SizedBox(height: 4),
                                          Text('صورة الحيوان', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                        ],
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _showImageSourceBottomSheet(context),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primary,
                                  child: Icon(
                                    photo == null ? Icons.camera_alt : Icons.edit,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: AppStringsAr.petName,
                      hint: 'مثال: لوسي، ماكس، ريكس',
                      controller: controller.petNameController,
                      prefixIcon: const Icon(Icons.pets),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStringsAr.species,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: controller.speciesController.text,
                                decoration: const InputDecoration(),
                                items: const [
                                  DropdownMenuItem(value: 'قط', child: Text('قط')),
                                  DropdownMenuItem(value: 'كلب', child: Text('كلب')),
                                  DropdownMenuItem(value: 'طائر', child: Text('طائر')),
                                  DropdownMenuItem(value: 'خيل', child: Text('خيل')),
                                  DropdownMenuItem(value: 'أرنب', child: Text('أرنب')),
                                  DropdownMenuItem(value: 'أخرى', child: Text('حيوان أليف آخر')),
                                ],
                                onChanged: (v) {
                                  if (v != null) controller.speciesController.text = v;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: AppStringsAr.breed,
                            hint: 'مثال: شيرازي، هاسكي',
                            controller: controller.breedController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Age input row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: CustomTextField(
                            label: 'عمر الحيوان',
                            hint: 'مثال: 2',
                            controller: controller.ageValueController,
                            keyboardType: TextInputType.number,
                            prefixIcon: const Icon(Icons.cake_outlined),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('الوحدة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Obx(() => DropdownButtonFormField<String>(
                                    initialValue: controller.selectedAgeUnit.value,
                                    decoration: const InputDecoration(),
                                    items: const [
                                      DropdownMenuItem(value: 'سنوات', child: Text('سنوات')),
                                      DropdownMenuItem(value: 'أشهر', child: Text('أشهر')),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) controller.selectedAgeUnit.value = v;
                                    },
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Obx(() => RadioGroup<String>(
                                groupValue: controller.selectedGender.value,
                                onChanged: (v) {
                                  if (v != null) controller.selectedGender.value = v;
                                },
                                child: const Row(
                                  children: [
                                    Radio<String>(value: 'male'),
                                    Text('ذكر'),
                                    SizedBox(width: 8),
                                    Radio<String>(value: 'female'),
                                    Text('أنثى'),
                                  ],
                                ),
                              )),
                        ),
                        Expanded(
                          child: Obx(() => CheckboxListTile(
                                title: const Text('معقم', style: TextStyle(fontSize: 13)),
                                value: controller.isNeutered.value,
                                onChanged: (v) => controller.isNeutered.value = v ?? false,
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Microchip with toggle / collapsible view
                    Obx(() => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: controller.hasMicrochip.value
                                ? AppColors.secondaryLight.withValues(alpha: 0.3)
                                : Colors.grey.shade50,
                            border: Border.all(
                              color: controller.hasMicrochip.value ? AppColors.primary : AppColors.border,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.qr_code_2,
                                        size: 20,
                                        color: controller.hasMicrochip.value ? AppColors.primary : AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'شريحة إلكترونية للحيوان (Microchip)',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: controller.hasMicrochip.value,
                                    onChanged: (val) {
                                      controller.hasMicrochip.value = val;
                                      if (!val) controller.microchipController.clear();
                                    },
                                  ),
                                ],
                              ),
                              if (controller.hasMicrochip.value) ...[
                                const SizedBox(height: 8),
                                CustomTextField(
                                  label: AppStringsAr.microchipNumber,
                                  hint: 'أدخل رقم الشريحة المكون من 15 رقماً',
                                  controller: controller.microchipController,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(Icons.qr_code),
                                ),
                              ],
                            ],
                          ),
                        )),
                    const SizedBox(height: 14),

                    CustomTextField(
                      label: 'الوزن الأولي عند التسجيل (كجم)',
                      hint: 'مثال: 3.8',
                      controller: controller.initialWeightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.scale),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: AppStringsAr.allergyWarningTitle,
                      hint: 'تنبيهات الحساسية للأدوية (مثل: حساسية البنسلين، التطعيمات)',
                      controller: controller.allergiesController,
                      maxLines: 2,
                      prefixIcon: const Icon(Icons.warning_amber),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Owner Details Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بيانات المربي (المالك)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      if (controller.owners.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: DropdownButtonFormField<int?>(
                            initialValue: controller.selectedExistingOwner.value?.id,
                            decoration: const InputDecoration(labelText: 'اختر مالك مسجل سابقاً (أو أضف مالك جديد بالأسفل)'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('-- مالك جديد --')),
                              ...controller.owners.map((o) => DropdownMenuItem(
                                    value: o.id,
                                    child: Text('${o.fullName} (${o.phonePrimary})'),
                                  )),
                            ],
                            onChanged: (id) {
                              if (id == null) {
                                controller.selectedExistingOwner.value = null;
                              } else {
                                controller.selectedExistingOwner.value =
                                    controller.owners.firstWhere((o) => o.id == id);
                              }
                            },
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    Obx(() {
                      if (controller.selectedExistingOwner.value != null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'سيتم ربط المريض بالمالك: ${controller.selectedExistingOwner.value!.fullName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          CustomTextField(
                            label: AppStringsAr.ownerName,
                            hint: 'الاسم الثلاثي للمالك',
                            controller: controller.ownerNameController,
                            prefixIcon: const Icon(Icons.person),
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: AppStringsAr.primaryPhone,
                            hint: '05xxxxxxxx (لتذكيرات الواتساب)',
                            controller: controller.ownerPhoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          const SizedBox(height: 14),
                          CustomTextField(
                            label: AppStringsAr.ownerAddress,
                            hint: 'المدينة والحي',
                            controller: controller.ownerAddressController,
                            prefixIcon: const Icon(Icons.home),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Obx(() => PrimaryButton(
                  text: controller.isEditing.value ? 'حفظ تعديلات المريض' : AppStringsAr.save,
                  icon: Icons.check,
                  onPressed: controller.savePatient,
                )),
          ],
        ),
      ),
    );
  }
}
