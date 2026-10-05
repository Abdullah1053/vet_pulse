import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/pet_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/patient_controller.dart';

class PatientDetailView extends StatefulWidget {
  const PatientDetailView({super.key});

  @override
  State<PatientDetailView> createState() => _PatientDetailViewState();
}

class _PatientDetailViewState extends State<PatientDetailView> with SingleTickerProviderStateMixin {
  late final PatientController controller;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<PatientController>();
    _tabController = TabController(length: 4, vsync: this);

    final arg = Get.arguments;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (arg != null) {
        controller.loadPetFullProfile(arg);
      } else if (controller.selectedPet.value != null) {
        controller.loadPetFullProfile(controller.selectedPet.value);
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _showAddWeightDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStringsAr.addWeight),
        content: TextField(
          controller: controller.newWeightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'الوزن بالكيلوجرام (كجم)',
            hintText: 'مثال: 4.5',
            suffixText: 'كجم',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStringsAr.cancel),
          ),
          ElevatedButton(
            onPressed: controller.recordNewWeight,
            child: const Text(AppStringsAr.save),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePet(BuildContext context, PetModel pet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.critical),
            SizedBox(width: 8),
            Text('تأكيد حذف ملف المريض'),
          ],
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في حذف ملف المريض "${pet.name}" نهائياً؟\n\nتنبيه: سيتم حذف جميع الكشوفات والمراجعات والعمليات وسجلات الوزن المرتبطة به.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStringsAr.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.critical),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.deletePet(pet.id!);
            },
            child: const Text('نعم، احذف الملف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('تنبيه', 'تعذر فتح تطبيق واتساب', backgroundColor: Colors.amber.shade100);
    }
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingProfile.value) {
        return Scaffold(
          appBar: AppBar(title: const Text(AppStringsAr.patientProfile)),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري تحميل السجل الطبي الكامل للمريض...'),
              ],
            ),
          ),
        );
      }

      final pet = controller.selectedPet.value;
      if (pet == null) {
        return Scaffold(
          appBar: AppBar(title: const Text(AppStringsAr.patientProfile)),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.pets, size: 64, color: Colors.grey),
                const SizedBox(height: 12),
                const Text(AppStringsAr.noDataFound, style: TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('العودة'),
                ),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(pet.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_chart),
              tooltip: AppStringsAr.addWeight,
              onPressed: () => _showAddWeightDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'تعديل بيانات المريض',
              onPressed: () {
                controller.initEditPet(pet);
                Get.toNamed(AppRoutes.addPatient);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.critical),
              tooltip: 'حذف ملف المريض',
              onPressed: () => _confirmDeletePet(context, pet),
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
          child: PrimaryButton(
            text: 'بدء كشف سريري جديد (SOAP)',
            icon: Icons.medical_services_outlined,
            onPressed: () => Get.toNamed(AppRoutes.newConsultation, arguments: pet),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CRITICAL DRUG ALLERGY BANNER
              if (pet.hasAllergies) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.criticalBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.critical, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.critical, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppStringsAr.allergyWarningTitle,
                              style: TextStyle(
                                color: AppColors.critical,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pet.allergies!,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 2. Patient Basic Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: AppColors.secondaryLight,
                            backgroundImage: (pet.photoPath != null &&
                                    pet.photoPath!.isNotEmpty &&
                                    File(pet.photoPath!).existsSync())
                                ? FileImage(File(pet.photoPath!))
                                : null,
                            child: (pet.photoPath != null &&
                                    pet.photoPath!.isNotEmpty &&
                                    File(pet.photoPath!).existsSync())
                                ? null
                                : const Icon(Icons.pets, size: 36, color: AppColors.primary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pet.name,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    StatusChip(label: pet.species, type: ChipStatusType.info),
                                    StatusChip(
                                      label: pet.genderDisplayArabic,
                                      type: ChipStatusType.neutral,
                                    ),
                                    if (pet.isNeutered)
                                      const StatusChip(
                                        label: 'معقم',
                                        type: ChipStatusType.success,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInfoRow('العمر', pet.ageDisplayArabic),
                      _buildInfoRow('السلالة', pet.breed ?? 'غير محددة'),
                      if (pet.microchipNumber != null && pet.microchipNumber!.trim().isNotEmpty)
                        _buildInfoRow('رقم الشريحة (Microchip)', pet.microchipNumber!),
                      _buildInfoRow('حالة الحساسية', pet.hasAllergies ? 'يوجد تنبيه حساسية' : 'سليم'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Owner Details Card with WhatsApp & Call actions
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
                            AppStringsAr.ownerInfo,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (pet.ownerPhone != null && pet.ownerPhone!.isNotEmpty)
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.phone, color: AppColors.primary, size: 20),
                                  onPressed: () => _makeCall(pet.ownerPhone!),
                                  tooltip: 'اتصال',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                                  onPressed: () => _openWhatsApp(pet.ownerPhone!),
                                  tooltip: 'واتساب',
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('الاسم', pet.ownerName ?? 'غير معروف'),
                      _buildInfoRow('الهاتف', pet.ownerPhone ?? 'غير متوفر'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Weight Tracking Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.show_chart, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppStringsAr.weightTracking,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => _showAddWeightDialog(context),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('تسجيل وزن'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (controller.petWeights.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('لم يتم تسجيل قراءات وزن بعد', style: TextStyle(color: AppColors.textMuted)),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.petWeights.length,
                          itemBuilder: (context, idx) {
                            final w = controller.petWeights[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(w.recordedDate, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                  Text(
                                    '${w.weight} كجم',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkNeutral),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Medical Consultation History (SOAP)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.assignment_outlined, color: AppColors.primary, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'سجل الكشوفات السريرية (SOAP)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${controller.petConsultations.length} زيارات',
                              style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (controller.petConsultations.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text('لا توجد زيارات أو كشوفات مسجلة لهذا المريض بعد', style: TextStyle(color: AppColors.textMuted)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.petConsultations.length,
                          separatorBuilder: (_, _) => const Divider(height: 24),
                          itemBuilder: (context, idx) {
                            final c = controller.petConsultations[idx];
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => Get.toNamed(AppRoutes.consultationDetail, arguments: c),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.event, size: 14, color: AppColors.primary),
                                            const SizedBox(width: 4),
                                            Text(
                                              c.visitDate.substring(0, 10),
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              '${c.visitCost.toStringAsFixed(0)} ${AppStringsAr.currencyShort}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textSecondary),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text('التشخيص: ${c.diagnosis}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    if (c.symptoms != null && c.symptoms!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text('الشكوى والأعراض: ${c.symptoms}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                    if (c.treatmentPlan != null && c.treatmentPlan!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text('الخطة العلاجية: ${c.treatmentPlan}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                    if (c.prescriptions.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.grey.shade300),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(Icons.medication_outlined, size: 14, color: AppColors.accent),
                                                SizedBox(width: 4),
                                                Text('العلاجات والروشتة المصروفة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            ...c.prescriptions.map((p) => Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                                  child: Row(
                                                    children: [
                                                      Text('• ${p.displayName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                                      const SizedBox(width: 6),
                                                      Text('(${p.dosage} - ${p.frequency} - ${p.durationDays} أيام)',
                                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                                    ],
                                                  ),
                                                )),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 6. Surgery Records Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.healing, color: AppColors.primary, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'سجل العمليات الجراحية',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${controller.petSurgeries.length} عمليات',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (controller.petSurgeries.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text('لا توجد عمليات جراحية مسجلة لهذا الحيوان', style: TextStyle(color: AppColors.textMuted)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.petSurgeries.length,
                          separatorBuilder: (_, _) => const Divider(height: 16),
                          itemBuilder: (context, idx) {
                            final s = controller.petSurgeries[idx];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          s.surgeryName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: s.status == 'completed' ? Colors.green.shade50 : Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: s.status == 'completed' ? Colors.green.shade300 : Colors.amber.shade300),
                                        ),
                                        child: Text(
                                          s.statusDisplayArabic,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: s.status == 'completed' ? Colors.green.shade800 : Colors.amber.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 13, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(s.scheduledDate, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.person, size: 13, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'الجراح: ${s.surgeonName ?? "طبيب بيطري"}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (s.postOpNotes != null && s.postOpNotes!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Text(
                                        'ملاحظات وتقرير ما بعد الجراحة:\n${s.postOpNotes}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.darkNeutral),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 7. Follow-ups & Upcoming Visits Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.event_repeat, color: AppColors.primary, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'المواعيد والمراجعات المسجلة',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${controller.petFollowUps.length} مواعيد',
                              style: TextStyle(fontSize: 12, color: Colors.purple.shade900, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (controller.petFollowUps.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text('لا توجد مراجعات أو مواعيد لاحقة مجدولة لهذا المريض', style: TextStyle(color: AppColors.textMuted)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.petFollowUps.length,
                          separatorBuilder: (_, _) => const Divider(height: 16),
                          itemBuilder: (context, idx) {
                            final f = controller.petFollowUps[idx];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            const Icon(Icons.alarm, size: 16, color: AppColors.primary),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                '${f.scheduledDate} ${f.scheduledTime != null ? "(${f.scheduledTime})" : ""}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: f.status == 'completed'
                                              ? Colors.green.shade50
                                              : (f.isOverdue ? Colors.red.shade50 : Colors.blue.shade50),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          f.statusDisplayArabic,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: f.status == 'completed'
                                              ? Colors.green.shade800
                                              : (f.isOverdue ? Colors.red.shade800 : Colors.blue.shade800),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('سبب المراجعة: ${f.reason}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  if (f.notes != null && f.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('ملاحظات المالك: ${f.notes}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ],
                              ),
                            );
                          },
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
    });
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
