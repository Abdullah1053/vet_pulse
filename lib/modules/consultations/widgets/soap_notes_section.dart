import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/new_consultation_controller.dart';

class SoapNotesSection extends GetView<NewConsultationController> {
  const SoapNotesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'منهجية الفحص السريري (SOAP Notes)',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
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
    );
  }
}
