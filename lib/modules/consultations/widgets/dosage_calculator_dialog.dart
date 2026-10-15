import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/prescription_item_controller.dart';

class DosageCalculatorDialog extends GetView<PrescriptionItemController> {
  const DosageCalculatorDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const DosageCalculatorDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('تم واعتمد الجرعة'),
        ),
      ],
    );
  }
}
