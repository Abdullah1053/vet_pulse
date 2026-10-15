import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/new_consultation_controller.dart';

class VitalsSection extends GetView<NewConsultationController> {
  const VitalsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStringsAr.vitalsSection,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
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
    );
  }
}
