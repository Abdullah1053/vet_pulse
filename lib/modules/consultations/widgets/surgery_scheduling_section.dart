import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/new_consultation_controller.dart';

class SurgerySchedulingSection extends GetView<NewConsultationController> {
  const SurgerySchedulingSection({super.key});

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
                  backgroundColor: Color(0xFFFFEFEA),
                  child: Icon(Icons.healing, color: Color(0xFFE76F51)),
                ),
                title: const Text(
                  '3- حجز موعد عملية جراحية للحالة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'تفعيل خيار جدولة عملية جراحية بناءً على نتائج هذا الفحص',
                  style: TextStyle(fontSize: 11),
                ),
                value: controller.needSurgery.value,
                onChanged: (v) => controller.needSurgery.value = v,
              ),
            ),
            Obx(() {
              if (!controller.needSurgery.value) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 20),
                  CustomTextField(
                    label: 'اسم العملية الجراحية',
                    hint: 'مثال: تعقيم قطة، استئصال ورم، تنظيف جير الأسنان',
                    controller: controller.surgeryNameController,
                    prefixIcon: const Icon(Icons.healing),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'تاريخ العملية',
                          hint: 'YYYY-MM-DD',
                          controller: controller.surgeryDateController,
                          readOnly: true,
                          onTap: () => _selectDate(context, controller.surgeryDateController),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: CustomTextField(
                          label: 'ساعة الحضور للجناح',
                          hint: '09:00 ص',
                          controller: controller.surgeryTimeController,
                          readOnly: true,
                          onTap: () => _selectTime(context, controller.surgeryTimeController),
                          prefixIcon: const Icon(Icons.access_time),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_pin_outlined, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'الجراح المسؤول عن العملية *',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int?>(
                          isExpanded: true,
                          initialValue: controller.selectedSurgeon.value?.id,
                          decoration: InputDecoration(
                            hintText: 'اختر الطبيب الجراح المسؤول',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          items: controller.availableSurgeons.map((d) {
                            return DropdownMenuItem<int?>(
                              value: d.id,
                              child: Row(
                                children: [
                                  const Icon(Icons.medical_services, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'د. ${d.fullName} (${d.role})',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) {
                              controller.selectedSurgeon.value =
                                  controller.availableSurgeons.firstWhere((u) => u.id == id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'التكلفة التقديرية للعملية (${AppStringsAr.currencyShort})',
                    hint: '25000',
                    controller: controller.surgeryCostController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'ملاحظات التحضير للجراحة',
                    hint: 'الصيام عن الطعام 12 ساعة، إيقاف أدوية معينة...',
                    controller: controller.surgeryNotesController,
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
