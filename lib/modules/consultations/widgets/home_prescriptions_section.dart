import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/prescription_item_controller.dart';

class HomePrescriptionsSection extends GetView<PrescriptionItemController> {
  const HomePrescriptionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF2A9D8F), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A9D8F).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long, color: Color(0xFF2A9D8F), size: 20),
                ),
                const SizedBox(width: 8),
                const Text(
                  '2- روشيتة علاج للمنزل (للمالك)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF2A9D8F),
                  ),
                ),
              ],
            ),
            const Text(
              'روشتة طبية تصرف للمالك للاستخدام المنزلي (تكتب بحرية وبدون تقييد بمخزون صيدلية العيادة)',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            CustomTextField(
              label: 'اسم الدواء / العلاج الموصوف',
              hint: 'مثال: أموكسيسيلين أقراص، فيتامين قطرة، غسول أذن',
              controller: controller.homeMedNameController,
              prefixIcon: const Icon(Icons.medication),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    label: 'الجرعة',
                    hint: '1 قرص / 2 مل',
                    controller: controller.homeDosageController,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    label: 'التكرار',
                    hint: 'مرتين يومياً',
                    controller: controller.homeFrequencyController,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    label: 'المدة (أيام)',
                    hint: '5',
                    controller: controller.homeDurationController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            CustomTextField(
              label: 'إرشادات الاستعمال للعميل',
              hint: 'مثال: يحفظ في الثلاجة، يُرج جيداً قبل الاستعمال، تجنب ملامسة العين',
              controller: controller.homeInstructionsController,
            ),
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: controller.addHomePrescription,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('إضافة للروشتة المنزلية'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A9D8F),
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            // List of home prescriptions
            Obx(() {
              if (controller.homePrescriptions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'لم يتم إضافة أدوية للروشتة المنزلية بعد',
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
                    itemCount: controller.homePrescriptions.length,
                    separatorBuilder: (_, _) => const Divider(height: 10),
                    itemBuilder: (context, idx) {
                      final item = controller.homePrescriptions[idx];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFFEAF8F6),
                          child: Icon(Icons.description, size: 16, color: Color(0xFF2A9D8F)),
                        ),
                        title: Text(
                          '${item.displayName} (${item.dosage})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(
                          '${item.frequency} لمدة ${item.durationDays} أيام | ${item.instructions ?? ""}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.critical, size: 20),
                          onPressed: () => controller.removeHomePrescription(idx),
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
