import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/new_consultation_controller.dart';

class PatientInfoSection extends GetView<NewConsultationController> {
  const PatientInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'بيانات المريض البيطري',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Obx(() {
              return DropdownButtonFormField<int?>(
                isExpanded: true,
                initialValue: controller.selectedPet.value?.id,
                decoration: const InputDecoration(labelText: 'اختر المريض من السجل'),
                items: controller.allPets.map((p) {
                  return DropdownMenuItem<int?>(
                    value: p.id,
                    child: Text(
                      '${p.name} (${p.species}) - المالك: ${p.ownerName ?? ""}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null) {
                    final pet = controller.allPets.firstWhere((p) => p.id == id);
                    controller.selectedPet.value = pet;
                    if (pet.latestWeight != null) {
                      controller.prescriptionController.calcWeightController.text =
                          pet.latestWeight.toString();
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
    );
  }
}
