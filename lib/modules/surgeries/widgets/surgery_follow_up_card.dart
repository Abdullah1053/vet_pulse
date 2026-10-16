import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/surgery_follow_up_controller.dart';

class SurgeryFollowUpCard extends GetView<SurgeryFollowUpController> {
  const SurgeryFollowUpCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event_repeat, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'حجز موعد مراجعة بعد العملية',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
                Obx(() => Switch(
                      value: controller.needFollowUp.value,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => controller.needFollowUp.value = val,
                    )),
              ],
            ),
            Obx(() {
              if (!controller.needFollowUp.value) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'تاريخ المراجعة *',
                          hint: 'YYYY-MM-DD',
                          controller: controller.followUpDateController,
                          readOnly: true,
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) {
                              controller.followUpDateController.text =
                                  picked.toIso8601String().substring(0, 10);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          label: 'الوقت المحدد',
                          hint: '10:00 ص',
                          controller: controller.followUpTimeController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'سبب المراجعة',
                    hint: 'معاينة التئام الجرح وفك الغرز',
                    controller: controller.followUpReasonController,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'ملاحظات الموعد',
                    hint: 'تعليمات الحضور للمراجعة',
                    controller: controller.followUpNotesController,
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
