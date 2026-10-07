import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../controllers/consultation_controller.dart';

class NewConsultationView extends GetView<ConsultationController> {
  const NewConsultationView({super.key});

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

  void _showDosageCalcDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
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
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('تم واعتمد الجرعة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStringsAr.newConsultation),
        actions: [
          IconButton(
            tooltip: AppStringsAr.dosageCalculator,
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () => _showDosageCalcDialog(context),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Obx(() => PrimaryButton(
              text: 'حفظ الكشف الطبي وصرف الأدوية والروشتة',
              icon: Icons.check_circle_outline,
              isLoading: controller.isLoading.value,
              onPressed: controller.saveConsultation,
            )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Select Patient & Allergy Alert
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بيانات المريض البيطري',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                              controller.calcWeightController.text = pet.latestWeight.toString();
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
            ),
            const SizedBox(height: 16),

            // 2. Clinical Vitals
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStringsAr.vitalsSection,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
            ),
            const SizedBox(height: 16),

            // 3. SOAP Framework
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'منهجية الفحص السريري (SOAP Notes)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
            ),
            const SizedBox(height: 16),

            // 4. Medication Type 1: In-Clinic Administered Injections & Treatments (Deducted from Pharmacy Shelf Stock)
            Card(
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
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => _showDosageCalcDialog(context),
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
                          child: Text('لم يتم صرف إبر أو علاجات بالعيادة بعد', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
            ),
            const SizedBox(height: 16),

            // 5. Medication Type 2: Take-Home Prescription for Owner (Freeform, not deducted from pharmacy stock)
            Card(
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2A9D8F)),
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
                          child: Text('لم يتم إضافة أدوية للروشتة المنزلية بعد', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
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
            ),
            const SizedBox(height: 16),

            // 6. Schedule Surgery if Needed
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: const CircleAvatar(
                            backgroundColor: Color(0xFFFFEFEA),
                            child: Icon(Icons.healing, color: Color(0xFFE76F51)),
                          ),
                          title: const Text('3- حجز موعد عملية جراحية للحالة', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('تفعيل خيار جدولة عملية جراحية بناءً على نتائج هذا الفحص', style: TextStyle(fontSize: 11)),
                          value: controller.needSurgery.value,
                          onChanged: (v) => controller.needSurgery.value = v,
                        )),
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
                          // Dedicated stylized Lead Surgeon selector
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
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
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
            ),
            const SizedBox(height: 16),

            // 7. Consecutive Treatment Plan / Follow-up Visits Option
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: const CircleAvatar(
                            backgroundColor: Color(0xFFEAF8F6),
                            child: Icon(Icons.event_repeat, color: Color(0xFF2A9D8F)),
                          ),
                          title: const Text('4- خطة علاجية وجلسات متابعة متتالية', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('مثل: إبر مضاد حيوي بالعيادة تتطلب عودة المريض لمدة 3 أيام متتالية', style: TextStyle(fontSize: 11)),
                          value: controller.needTreatmentPlan.value,
                          onChanged: (v) => controller.needTreatmentPlan.value = v,
                        )),
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
            ),
            const SizedBox(height: 16),

            // 8. Cost of Consultation in Yemeni Rial
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '5- أتعاب الكشف والخدمات السريرية',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            AppStringsAr.currency, // ريال يمني
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'أتعاب الكشف والخدمات (${AppStringsAr.currencyShort})',
                      hint: '5000',
                      controller: controller.costController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                    const SizedBox(height: 14),
                    Obx(() => DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: controller.selectedPaymentMethod.value,
                      decoration: const InputDecoration(
                        labelText: 'طريقة الدفع *',
                        prefixIcon: Icon(Icons.payment, color: AppColors.primary),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'نقدا',
                          child: Row(
                            children: [
                              Icon(Icons.money, size: 18, color: Colors.green),
                              SizedBox(width: 8),
                              Text('نقدا', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'جوالي',
                          child: Row(
                            children: [
                              Icon(Icons.phone_android, size: 18, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('جوالي', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'جيب',
                          child: Row(
                            children: [
                              Icon(Icons.account_balance_wallet, size: 18, color: Colors.purple),
                              SizedBox(width: 8),
                              Text('جيب', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'كريمي',
                          child: Row(
                            children: [
                              Icon(Icons.account_balance, size: 18, color: Colors.teal),
                              SizedBox(width: 8),
                              Text('كريمي', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'فلوسك',
                          child: Row(
                            children: [
                              Icon(Icons.credit_card, size: 18, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('فلوسك', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) controller.selectedPaymentMethod.value = val;
                      },
                    )),
                    const SizedBox(height: 14),
                    Obx(() => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: controller.showCostInPrescription.value
                            ? AppColors.secondaryLight
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: controller.showCostInPrescription.value
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            controller.showCostInPrescription.value
                                ? Icons.receipt_long
                                : Icons.money_off,
                            color: controller.showCostInPrescription.value
                                ? AppColors.primary
                                : Colors.grey.shade600,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إظهار أتعاب الكشف في الروشتة المطبوعة',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: controller.showCostInPrescription.value
                                        ? AppColors.primaryDark
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  controller.showCostInPrescription.value
                                      ? 'سيظهر مبلغ الأتعاب في أسفل الروشتة'
                                      : 'مخفي: لن يظهر المبلغ في الروشتة (روشتة علاجية فقط)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: controller.showCostInPrescription.value
                                        ? AppColors.primaryDark.withValues(alpha: 0.8)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: controller.showCostInPrescription.value,
                            activeTrackColor: AppColors.primary,
                            onChanged: (val) => controller.showCostInPrescription.value = val,
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
