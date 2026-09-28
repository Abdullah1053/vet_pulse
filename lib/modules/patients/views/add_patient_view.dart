import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../controllers/patient_controller.dart';

class AddPatientView extends GetView<PatientController> {
  const AddPatientView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStringsAr.newPetAction),
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
                                  DropdownMenuItem(value: 'قط', child: Text('قط (Feline)')),
                                  DropdownMenuItem(value: 'كلب', child: Text('كلب (Canine)')),
                                  DropdownMenuItem(value: 'طائر', child: Text('طائر (Avian)')),
                                  DropdownMenuItem(value: 'خيل', child: Text('خيل (Equine)')),
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
                    CustomTextField(
                      label: AppStringsAr.microchipNumber,
                      hint: 'رقم الشريحة المكون من 15 رقماً',
                      controller: controller.microchipController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.qr_code),
                    ),
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

            PrimaryButton(
              text: AppStringsAr.save,
              icon: Icons.check,
              onPressed: controller.savePatient,
            ),
          ],
        ),
      ),
    );
  }
}
