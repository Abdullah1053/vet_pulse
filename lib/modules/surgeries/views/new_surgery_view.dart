import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../controllers/surgery_controller.dart';

class NewSurgeryView extends GetView<SurgeryController> {
  const NewSurgeryView({super.key});

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      controller.scheduledDateController.text = picked.toIso8601String().substring(0, 10);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      final hourStr = picked.hourOfPeriod == 0 ? '12' : picked.hourOfPeriod.toString();
      final minStr = picked.minute.toString().padLeft(2, '0');
      final periodStr = picked.period == DayPeriod.am ? 'ص' : 'م';
      controller.scheduledTimeController.text = '$hourStr:$minStr $periodStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditing.value ? 'تعديل بيانات العملية الجراحية' : AppStringsAr.scheduleSurgery)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Patient & Surgeon Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بيانات العملية الجراحية',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Obx(() => DropdownButtonFormField<int?>(
                          isExpanded: true,
                          initialValue: controller.selectedPet.value?.id,
                          decoration: const InputDecoration(labelText: 'اختر المريض'),
                          items: controller.pets.map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  '${p.name} (${p.species}) - المالك: ${p.ownerName ?? ""}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              )).toList(),
                          onChanged: (id) {
                            if (id != null) {
                              controller.selectedPet.value = controller.pets.firstWhere((p) => p.id == id);
                            }
                          },
                        )),
                    const SizedBox(height: 14),
                    Obx(() => DropdownButtonFormField<int?>(
                          isExpanded: true,
                          initialValue: controller.selectedSurgeon.value?.id,
                          decoration: const InputDecoration(labelText: AppStringsAr.leadSurgeon),
                          items: controller.doctors.map((d) => DropdownMenuItem(
                                value: d.id,
                                child: Text(
                                  '${d.fullName} (${d.roleDisplayArabic})',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              )).toList(),
                          onChanged: (id) {
                            if (id != null) {
                              controller.selectedSurgeon.value = controller.doctors.firstWhere((d) => d.id == id);
                            }
                          },
                        )),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: AppStringsAr.surgeryName,
                      hint: 'مثال: استئصال ورم سطحي، تعقيم قطة، تنظيف جير أسنان',
                      controller: controller.surgeryNameController,
                      prefixIcon: const Icon(Icons.healing),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: controller.categoryController.text,
                      decoration: const InputDecoration(labelText: AppStringsAr.surgeryCategory),
                      items: const [
                        DropdownMenuItem(value: AppStringsAr.categoryElective, child: Text(AppStringsAr.categoryElective)),
                        DropdownMenuItem(value: AppStringsAr.categorySoftTissue, child: Text(AppStringsAr.categorySoftTissue)),
                        DropdownMenuItem(value: AppStringsAr.categoryOrthopedic, child: Text(AppStringsAr.categoryOrthopedic)),
                        DropdownMenuItem(value: AppStringsAr.categoryDental, child: Text(AppStringsAr.categoryDental)),
                        DropdownMenuItem(value: AppStringsAr.categoryEmergency, child: Text(AppStringsAr.categoryEmergency)),
                      ],
                      onChanged: (v) {
                        if (v != null) controller.categoryController.text = v;
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'تاريخ العملية',
                            hint: 'YYYY-MM-DD',
                            controller: controller.scheduledDateController,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'ساعة الحضور للجناح',
                            hint: 'اختر الوقت',
                            controller: controller.scheduledTimeController,
                            readOnly: true,
                            onTap: () => _selectTime(context),
                            prefixIcon: const Icon(Icons.access_time),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Pre-Operative Safety Checklist
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStringsAr.preOpChecklist,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'معايير الأمان الموصى بها قبل إدخال الحيوان لغرفة العمليات',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Obx(() => CheckboxListTile(
                          title: const Text(AppStringsAr.checkFasting, style: TextStyle(fontSize: 13)),
                          value: controller.checkFasting.value,
                          onChanged: (v) => controller.checkFasting.value = v ?? false,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        )),
                    Obx(() => CheckboxListTile(
                          title: const Text(AppStringsAr.checkBloodWork, style: TextStyle(fontSize: 13)),
                          value: controller.checkBloodWork.value,
                          onChanged: (v) => controller.checkBloodWork.value = v ?? false,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        )),
                    Obx(() => CheckboxListTile(
                          title: const Text(AppStringsAr.checkConsent, style: TextStyle(fontSize: 13)),
                          value: controller.checkConsent.value,
                          onChanged: (v) => controller.checkConsent.value = v ?? false,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Anesthesia Protocol & Cost
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بروتوكول التخدير وملاحظات الخروج',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: AppStringsAr.anesthesiaProtocol,
                      hint: 'مثال: الحث بـ Propofol والحفظ بـ Isoflurane 2%',
                      controller: controller.anesthesiaController,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: AppStringsAr.postOpNotes,
                      hint: 'تعليمات الغرز، موعد الإفاقة، مضاد حيوي ومسكن',
                      controller: controller.postOpNotesController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'التكلفة التقديرية للعملية (ريال يمني)',
                      hint: 'مثال: 15000',
                      controller: controller.costController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Obx(() => PrimaryButton(
                  text: controller.isEditing.value ? 'حفظ تعديلات العملية الجراحية' : 'حفظ وتأكيد حجز العملية',
                  isLoading: controller.isLoading.value,
                  icon: Icons.check,
                  onPressed: controller.saveSurgery,
                )),
          ],
        ),
      ),
    );
  }
}
