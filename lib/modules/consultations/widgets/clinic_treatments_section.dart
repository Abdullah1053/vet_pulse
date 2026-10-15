import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/prescription_item_controller.dart';
import 'dosage_calculator_dialog.dart';

class ClinicTreatmentsSection extends GetView<PrescriptionItemController> {
  const ClinicTreatmentsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.vaccines, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '1- إبر وعلاجات العيادة الفورية',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => DosageCalculatorDialog.show(context),
                  icon: const Icon(Icons.calculate, size: 16),
                  label: const Text('حاسبة الجرعات'),
                ),
              ],
            ),
            const Text(
              'أدوية وإبر يتم حقنها أو إعطاؤها للحيوان مباشرة في العيادة ويتم خصمها من مخزون الصيدلية',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            // Select medicine from shelf
            Obx(() {
              return DropdownButtonFormField<int?>(
                isExpanded: true,
                initialValue: controller.selectedClinicMed.value?.id,
                decoration: const InputDecoration(labelText: 'اختر الدواء من صيدلية العيادة'),
                items: controller.availableMedicines.map((m) {
                  return DropdownMenuItem<int?>(
                    value: m.id,
                    child: Text(
                      '${m.tradeName} (متوفر بالرف: ${m.clinicStock})',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null) {
                    controller.selectedClinicMed.value =
                        controller.availableMedicines.firstWhere((m) => m.id == id);
                  }
                },
              );
            }),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    label: 'الجرعة المعطاة',
                    hint: 'مثال: 1.5 مل أو 1 أمبول',
                    controller: controller.clinicDoseController,
                    prefixIcon: const Icon(Icons.healing, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    label: 'الكمية المنصرفة',
                    hint: '1',
                    controller: controller.clinicQtyController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.pin, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: controller.clinicRouteController.text.isNotEmpty
                  ? controller.clinicRouteController.text
                  : 'حقن عضلي (IM)',
              decoration: const InputDecoration(
                labelText: 'طريقة الإعطاء *',
                prefixIcon: Icon(Icons.vaccines, color: AppColors.primary),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'حقن عضلي (IM)',
                  child: Text('حقن عضلي (IM) - Intramuscular', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'حقن وريدي (IV)',
                  child: Text('حقن وريدي (IV) - Intravenous', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'حقن تحت الجلد (SC)',
                  child: Text('حقن تحت الجلد (SC) - Subcutaneous', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'إعطاء فموي (Oral)',
                  child: Text('إعطاء فموي (Oral)', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 'موضعي (Topical)',
                  child: Text('موضعي (Topical)', overflow: TextOverflow.ellipsis),
                ),
              ],
              onChanged: (v) {
                if (v != null) controller.clinicRouteController.text = v;
              },
            ),
            const SizedBox(height: 10),

            CustomTextField(
              label: 'ملاحظات الإعطاء',
              hint: 'مثال: تم إعطاء الحقنة بالعضل، الحيوان هادئ',
              controller: controller.clinicNotesController,
            ),
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: controller.addClinicTreatment,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة لإبر وعلاجات العيادة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            // List of in-clinic treatments
            Obx(() {
              if (controller.clinicTreatments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'لم يتم صرف إبر أو علاجات بالعيادة بعد',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                );
              }
              return Column(
                children: [
                  const Divider(height: 20),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.clinicTreatments.length,
                    separatorBuilder: (_, _) => const Divider(height: 10),
                    itemBuilder: (context, idx) {
                      final item = controller.clinicTreatments[idx];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.secondaryLight,
                          child: Icon(Icons.check, size: 16, color: AppColors.primary),
                        ),
                        title: Text(
                          '${item.medicineName ?? "علاج"} - ${item.dosage}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(
                          '${item.route ?? "حقن"} | منصرف من الرف: ${item.quantityDispensed} | ${item.instructions ?? ""}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.critical, size: 20),
                          onPressed: () => controller.removeClinicTreatment(idx),
                        ),
                      );
                    },
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
