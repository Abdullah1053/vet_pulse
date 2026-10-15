import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/new_consultation_controller.dart';

class TreatmentPlanSection extends GetView<NewConsultationController> {
  const TreatmentPlanSection({super.key});

  Future<void> _selectDate(BuildContext context, TextEditingController textCtrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      textCtrl.text = picked.toIso8601String().substring(0, 10);
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController textCtrl) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'ص' : 'م';
      textCtrl.text = '$hour:$minute $period';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF8F6),
                  child: Icon(Icons.event_repeat, color: Color(0xFF2A9D8F)),
                ),
                title: const Text(
                  '4- خطة علاجية وجلسات متابعة متتالية',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'مثل: إبر مضاد حيوي بالعيادة تتطلب عودة المريض لمدة 3 أيام متتالية',
                  style: TextStyle(fontSize: 11),
                ),
                value: controller.needTreatmentPlan.value,
                onChanged: (v) => controller.needTreatmentPlan.value = v,
              ),
            ),
            Obx(() {
              if (!controller.needTreatmentPlan.value) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 20),
                  CustomTextField(
                    label: 'سبب المراجعات والجلسات',
                    hint: 'مثال: إبر مضاد حيوي بالعيادة، غيار جروح يومي',
                    controller: controller.planReasonController,
                    prefixIcon: const Icon(Icons.medical_services),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'عدد الأيام المتتالية',
                          hint: '3',
                          controller: controller.planDaysController,
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.repeat),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          label: 'وقت الحضور اليومي',
                          hint: '10:00 ص',
                          controller: controller.planTimeController,
                          readOnly: true,
                          onTap: () => _selectTime(context, controller.planTimeController),
                          prefixIcon: const Icon(Icons.access_time),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'تاريخ بدء الجلسات',
                    hint: 'YYYY-MM-DD',
                    controller: controller.planStartDateController,
                    readOnly: true,
                    onTap: () => _selectDate(context, controller.planStartDateController),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'ملاحظات وتوصيات للمربي قبل كل جلسة',
                    hint: 'مثال: إحضار الحيوان بدون إجهاد، إبلاغ الطبيب بأي مضاعفات',
                    controller: controller.planNotesController,
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
