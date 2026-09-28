import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../controllers/consultation_controller.dart';

class NewConsultationView extends GetView<ConsultationController> {
  const NewConsultationView({super.key});

  void _showDosageCalcDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStringsAr.dosageCalculator),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'المعادلة: الجرعة (مل) = (الوزن كجم × معدل الجرعة مجم/كجم) ÷ التركيز مجم/مل',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'وزن المريض (كجم)',
                hint: 'مثال: 4.5',
                controller: controller.calcWeightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: AppStringsAr.targetDoseRate,
                hint: 'مثال: 10 (مجم لكل كجم)',
                controller: controller.calcDoseRateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: AppStringsAr.medicineConcentration,
                hint: 'مثال: 50 (مجم لكل مل أو قرص)',
                controller: controller.calcConcentrationController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: controller.calculateDosage,
                icon: const Icon(Icons.calculate),
                label: const Text('حساب الجرعة'),
              ),
              const SizedBox(height: 12),
              Obx(() {
                if (controller.calculatedDose.value > 0) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${AppStringsAr.calculatedDoseResult} ${controller.calculatedDose.value} مل',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('تم واعتمد الجرعة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStringsAr.newConsultation),
        actions: [
          IconButton(
            tooltip: AppStringsAr.dosageCalculator,
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () => _showDosageCalcDialog(context),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Obx(() => PrimaryButton(
              text: 'حفظ الكشف وصرف الأدوية وطباعة الروشتة',
              icon: Icons.print,
              isLoading: controller.isLoading.value,
              onPressed: controller.saveConsultation,
            )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Select Patient & Allergy Alert
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بيانات المريض البيطري',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      return DropdownButtonFormField<int?>(
                        initialValue: controller.selectedPet.value?.id,
                        decoration: const InputDecoration(labelText: 'اختر المريض من السجل'),
                        items: controller.allPets.map((p) {
                          return DropdownMenuItem<int?>(
                            value: p.id,
                            child: Text('${p.name} (${p.species}) - المالك: ${p.ownerName ?? ""}'),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) {
                            final pet = controller.allPets.firstWhere((p) => p.id == id);
                            controller.selectedPet.value = pet;
                            if (pet.latestWeight != null) {
                              controller.calcWeightController.text = pet.latestWeight.toString();
                            }
                          }
                        },
                      );
                    }),
                    Obx(() {
                      final pet = controller.selectedPet.value;
                      if (pet != null && pet.hasAllergies) {
                        return Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.criticalBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.critical),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: AppColors.critical, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'تنبيه حساسية دوائية: ${pet.allergies!}',
                                  style: const TextStyle(
                                    color: AppColors.critical,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Clinical Vitals
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStringsAr.vitalsSection,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: AppStringsAr.temperature,
                            hint: '38.5',
                            controller: controller.tempController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixIcon: const Icon(Icons.thermostat),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: AppStringsAr.heartRate,
                            hint: '120',
                            controller: controller.heartRateController,
                            keyboardType: TextInputType.number,
                            prefixIcon: const Icon(Icons.favorite),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. SOAP Framework
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'منهجية الفحص السريري (SOAP Notes)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: AppStringsAr.subjective,
                      hint: AppStringsAr.subjectiveHint,
                      controller: controller.symptomsController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: AppStringsAr.objective,
                      hint: AppStringsAr.objectiveHint,
                      controller: controller.findingsController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: AppStringsAr.assessment,
                      hint: AppStringsAr.assessmentHint,
                      controller: controller.diagnosisController,
                      maxLines: 2,
                      prefixIcon: const Icon(Icons.biotech),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: AppStringsAr.plan,
                      hint: AppStringsAr.planHint,
                      controller: controller.planController,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Prescriptions & Medication Dispensing
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStringsAr.prescription,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () => _showDosageCalcDialog(context),
                          icon: const Icon(Icons.calculate, size: 16),
                          label: const Text('حاسبة الجرعات'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Add medicine dropdown
                    Obx(() {
                      return DropdownButtonFormField<int?>(
                        initialValue: controller.selectedMedForRx.value?.id,
                        decoration: const InputDecoration(labelText: AppStringsAr.selectMedicine),
                        items: controller.availableMedicines.map((m) {
                          return DropdownMenuItem<int?>(
                            value: m.id,
                            child: Text('${m.tradeName} (المتوفر بالرف: ${m.clinicStock})'),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) {
                            controller.selectedMedForRx.value =
                                controller.availableMedicines.firstWhere((m) => m.id == id);
                          }
                        },
                      );
                    }),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            label: AppStringsAr.dosage,
                            hint: 'مثال: 0.5 مل أو 1 قرص',
                            controller: controller.rxDosageController,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            label: AppStringsAr.frequency,
                            hint: 'مرتين يومياً',
                            controller: controller.rxFrequencyController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: AppStringsAr.durationDays,
                            hint: '5',
                            controller: controller.rxDurationController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomTextField(
                            label: AppStringsAr.quantityDispensed,
                            hint: '1',
                            controller: controller.rxQuantityController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    CustomTextField(
                      label: AppStringsAr.instructions,
                      hint: 'مثال: يحفظ بالثلاجة، يؤخذ مع الطعام',
                      controller: controller.rxInstructionsController,
                    ),
                    const SizedBox(height: 14),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: controller.addPrescriptionItem,
                        icon: const Icon(Icons.add_shopping_cart, size: 16),
                        label: const Text('إضافة الدواء للروشتة'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ),
                    const Divider(height: 24),

                    // Prescription List
                    Obx(() {
                      if (controller.prescriptionCart.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text('لم يتم إضافة أدوية للروشتة بعد', style: TextStyle(color: AppColors.textMuted)),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.prescriptionCart.length,
                        separatorBuilder: (_, _) => const Divider(height: 12),
                        itemBuilder: (context, idx) {
                          final item = controller.prescriptionCart[idx];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${item.medicineName ?? "دواء"} (${item.dosage})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${item.frequency} لمدة ${item.durationDays} أيام | منصرف: ${item.quantityDispensed}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.critical, size: 20),
                              onPressed: () => controller.removePrescriptionItem(idx),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 5. Cost of Consultation
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CustomTextField(
                  label: AppStringsAr.visitCost,
                  hint: '100',
                  controller: controller.costController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
