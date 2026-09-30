import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/services/data_sync_service.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/follow_up_model.dart';
import '../../../data/models/surgery_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/surgery_repository.dart';
import '../../../routes/app_routes.dart';

class CompleteSurgeryView extends StatefulWidget {
  const CompleteSurgeryView({super.key});

  @override
  State<CompleteSurgeryView> createState() => _CompleteSurgeryViewState();
}

class _CompleteSurgeryViewState extends State<CompleteSurgeryView> {
  final SurgeryRepository _surgeryRepo = SurgeryRepository();
  final AppointmentRepository _appointmentRepo = AppointmentRepository();

  late SurgeryModel surgery;
  bool isInitialized = false;

  final outcomeNotesController = TextEditingController();
  final recoveryStatusController = TextEditingController(text: 'إفاقة طبيعية ومستقرة، استعادة المنعكسات الحيوية');
  final complicationsController = TextEditingController(text: 'لا توجد مضاعفات جراحية أو تخديرية بحمد الله');
  final homeCareInstructionsController = TextEditingController(
    text: '1. تركيب طوق إليزابيث الواقي (E-Collar) لمنع لعق مكان الجرح.\n2. تطهير موضع الخياطة بمحلول معقم مرتين يومياً.\n3. راحة تامة وعزل في مكان دافئ ومنع القفز والحركة العنيفة لمدة 7 أيام.\n4. تقديم كميات ماء وغذاء قليلة ولينة خلال أول 24 ساعة.',
  );
  final finalCostController = TextEditingController();

  // Follow-up appointment options
  bool needFollowUp = true;
  final followUpDateController = TextEditingController();
  final followUpTimeController = TextEditingController(text: '10:00 ص');
  final followUpReasonController = TextEditingController(text: 'معاينة التئام الجرح الجراحي وفك الغرز');
  final followUpNotesController = TextEditingController(text: 'إحضار الحيوان لفحص الشفاء وإزالة خيوط الجراحة');

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is SurgeryModel) {
      surgery = args;
      isInitialized = true;
      outcomeNotesController.text = 'تمت العملية الجراحية (${surgery.surgeryName}) بنجاح تام.';
      finalCostController.text = (surgery.estimatedCost ?? 0.0).toStringAsFixed(0);
      final defaultFollowUp = DateTime.now().add(const Duration(days: 7));
      followUpDateController.text = defaultFollowUp.toIso8601String().substring(0, 10);
    }
  }

  @override
  void dispose() {
    outcomeNotesController.dispose();
    recoveryStatusController.dispose();
    complicationsController.dispose();
    homeCareInstructionsController.dispose();
    finalCostController.dispose();
    followUpDateController.dispose();
    followUpTimeController.dispose();
    followUpReasonController.dispose();
    followUpNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitCompletion() async {
    if (outcomeNotesController.text.trim().isEmpty) {
      Get.snackbar('تنبيه', 'يرجى تسجيل تقرير ونتائج العملية الجراحية', backgroundColor: Colors.amber.shade100);
      return;
    }

    setState(() => isSaving = true);
    try {
      // 1. Compile complete surgical discharge report
      final combinedNotes = StringBuffer();
      combinedNotes.writeln('📋 نتائج العملية:');
      combinedNotes.writeln(outcomeNotesController.text.trim());
      combinedNotes.writeln('\n💉 حالة الإفاقة:');
      combinedNotes.writeln(recoveryStatusController.text.trim());
      if (complicationsController.text.trim().isNotEmpty) {
        combinedNotes.writeln('\n⚠️ الملاحظات والمضاعفات:');
        combinedNotes.writeln(complicationsController.text.trim());
      }
      combinedNotes.writeln('\n🏠 تعليمات الرعاية المنزلية للمالك:');
      combinedNotes.writeln(homeCareInstructionsController.text.trim());

      final finalCost = double.tryParse(finalCostController.text.trim()) ?? surgery.estimatedCost ?? 0.0;

      // 2. Update Surgery
      final updatedSurgery = surgery.copyWith(
        status: 'completed',
        postOpNotes: combinedNotes.toString(),
        estimatedCost: finalCost,
      );
      await _surgeryRepo.updateSurgery(updatedSurgery);

      // 3. Create Follow-up appointment if requested
      if (needFollowUp && followUpDateController.text.trim().isNotEmpty) {
        await _appointmentRepo.insertFollowUp(FollowUpModel(
          petId: surgery.petId,
          scheduledDate: followUpDateController.text.trim(),
          scheduledTime: followUpTimeController.text.trim(),
          reason: followUpReasonController.text.trim(),
          notes: followUpNotesController.text.trim(),
        ));
      }

      // 4. Notify reactive data synchronizer
      DataSyncService.notifySurgeryChanged(petId: surgery.petId);
      if (needFollowUp) {
        DataSyncService.notifyFollowUpChanged(petId: surgery.petId);
      }

      Get.back(result: true);
      Get.snackbar(
        'تم إتمام العملية بنجاح',
        'تم تسجيل تقرير العملية الجراحية${needFollowUp ? " وحجز موعد المراجعة" : ""} بنجاح',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        icon: const Icon(Icons.check_circle, color: Colors.green),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر حفظ تقرير العملية: $e', backgroundColor: Colors.red.shade100);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('تقرير إتمام العملية الجراحية')),
        body: const Center(child: Text('لم يتم تمرير بيانات العملية')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير إتمام العملية والتخريج الجراحي'),
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
        child: PrimaryButton(
          text: isSaving ? 'جاري الحفظ...' : 'اعتماد إتمام العملية وحفظ التقرير',
          icon: Icons.task_alt,
          isLoading: isSaving,
          onPressed: isSaving ? null : _submitCompletion,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Surgery summary banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          surgery.surgeryName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Text(
                          surgery.surgeryCategory ?? 'جراحة عامة',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.pets, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text('المريض: ${surgery.petName ?? "غير محدد"} (${surgery.petSpecies ?? ""})',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const Spacer(),
                      InkWell(
                        onTap: () => Get.toNamed(AppRoutes.patientDetail, arguments: surgery.petId),
                        child: const Row(
                          children: [
                            Text('عرض الملف الطبي', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                            SizedBox(width: 2),
                            Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text('المالك: ${surgery.ownerName ?? "غير محدد"}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card 1: Surgical Outcomes & Clinical Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notes, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text('نتائج العملية الجراحية وملاحظات الجراح',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'تقرير نتائج الجراحة *',
                      hint: 'مثال: تمت العملية بنجاح، استئصال تام بدون نزيف، إغلاق الجرح بطبقتين...',
                      controller: outcomeNotesController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'حالة الإفاقة والتخدير',
                      hint: 'حالة العلامات الحيوية عند الإفاقة',
                      controller: recoveryStatusController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'ملاحظات المضاعفات (إن وجدت)',
                      hint: 'اكتب "لا توجد" أو اذكر أي مضاعفات للمتابعة',
                      controller: complicationsController,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card 2: Owner Home-Care Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.home_work_outlined, color: AppColors.accent, size: 20),
                        SizedBox(width: 8),
                        Text('تعليمات وإرشادات الرعاية المنزلية للمالك',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'هذه التعليمات سترفق بملف المريض ويمكن إرسالها للمالك عبر واتساب لضمان التئام الجرح',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'تعليمات الرعاية المنزلية للمالك *',
                      hint: 'إرشادات النظافة، طوق الحماية، التغذية، ومراقبة الجرح...',
                      controller: homeCareInstructionsController,
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card 3: Post-Op Follow-up Booking
            Card(
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
                            Text('حجز موعد مراجعة بعد العملية',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        Switch(
                          value: needFollowUp,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) => setState(() => needFollowUp = val),
                        ),
                      ],
                    ),
                    if (needFollowUp) ...[
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'تاريخ المراجعة *',
                              hint: 'YYYY-MM-DD',
                              controller: followUpDateController,
                              readOnly: true,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now().add(const Duration(days: 7)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 90)),
                                );
                                if (picked != null) {
                                  followUpDateController.text = picked.toIso8601String().substring(0, 10);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomTextField(
                              label: 'الوقت المحدد',
                              hint: '10:00 ص',
                              controller: followUpTimeController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'سبب المراجعة',
                        hint: 'معاينة التئام الجرح وفك الغرز',
                        controller: followUpReasonController,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'ملاحظات الموعد',
                        hint: 'تعليمات الحضور للمراجعة',
                        controller: followUpNotesController,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Card 4: Final Cost Settlement in Yemeni Rial
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.payments_outlined, color: Colors.teal, size: 20),
                        SizedBox(width: 8),
                        Text('التكلفة المالية النهائية للعملية',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: 'التكلفة الإجمالية للعملية الجراحية (${AppStringsAr.currencyShort})',
                      hint: '35000',
                      controller: finalCostController,
                      keyboardType: TextInputType.number,
                    ),
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
