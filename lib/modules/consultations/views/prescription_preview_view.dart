import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../data/models/consultation_model.dart';
import '../../../data/models/follow_up_model.dart';
import '../../../data/models/prescription_model.dart';
import '../../../data/models/surgery_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/prescription_preview_controller.dart';

class PrescriptionPreviewView extends GetView<PrescriptionPreviewController> {
  const PrescriptionPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    final clinic = authController?.clinicInfo.value;

    return Obx(() {
      if (controller.isLoading.value) {
        return Scaffold(
          appBar: AppBar(title: const Text('التقرير والروشتة الطبية')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      final consultation = controller.consultation.value;
      if (consultation == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('التقرير والروشتة الطبية')),
          body: const Center(child: Text('لا توجد بيانات كشف محددة')),
        );
      }

      final hasCost = consultation.visitCost > 0;
      final clinicRx = consultation.prescriptions.where((p) => p.isClinicAdministered).toList();
      final homeRx = consultation.prescriptions.where((p) => !p.isClinicAdministered).toList();
      final surgery = controller.scheduledSurgery.value;
      final followUps = controller.followUpSessions;

      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('التقرير والروشتة الطبية'),
            bottom: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(icon: Icon(Icons.description_outlined), text: 'المعاينة التفاعلية'),
                Tab(icon: Icon(Icons.picture_as_pdf_outlined), text: 'معاينة الطباعة (PDF)'),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'مشاركة ملف PDF',
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => controller.sharePdf(clinic),
              ),
              IconButton(
                tooltip: AppStringsAr.shareWhatsApp,
                icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                onPressed: () => controller.shareWhatsApp(clinic),
              ),
            ],
          ),
          body: Column(
            children: [
              // Consultation Fee visibility control banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: (controller.showCost.value && hasCost) ? AppColors.secondaryLight : Colors.grey.shade100,
                  border: Border(
                    bottom: BorderSide(
                      color: (controller.showCost.value && hasCost)
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      (controller.showCost.value && hasCost) ? Icons.visibility : Icons.visibility_off,
                      color: (controller.showCost.value && hasCost) ? AppColors.primary : Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'أتعاب الكشف والخدمات في التقرير والطباعة',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: (controller.showCost.value && hasCost)
                                      ? AppColors.primaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: !hasCost
                                      ? Colors.grey.shade400
                                      : (controller.showCost.value ? AppColors.primary : Colors.grey.shade500),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  !hasCost ? 'مجاني' : (controller.showCost.value ? 'ظاهر' : 'مخفي'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            hasCost
                                ? (controller.showCost.value
                                    ? 'سيظهر مبلغ الأتعاب (${consultation.visitCost.toStringAsFixed(0)} ${AppStringsAr.currencyShort}) في التقرير والطباعة'
                                    : 'مخفي: لن يظهر أي مبلغ مالي في التقرير والروشتة')
                                : 'لا توجد أتعاب مسجلة لهذا الكشف',
                            style: TextStyle(
                              fontSize: 11,
                              color: (controller.showCost.value && hasCost)
                                  ? AppColors.primaryDark.withValues(alpha: 0.8)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: controller.showCost.value && hasCost,
                      activeTrackColor: AppColors.primary,
                      onChanged: hasCost ? (val) => controller.toggleShowCost(val) : null,
                    ),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: On-Screen Interactive 4-Section Report (Strict RTL Table Columns)
                    _buildOnScreenReport(context, consultation, clinicRx, homeRx, surgery, followUps),

                    // Tab 2: Native PDF Preview (Printing / Sharing)
                    PdfPreview(
                      build: (format) => controller.getPdfBytes(clinic),
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      allowPrinting: true,
                      allowSharing: true,
                      pdfFileName: 'medical_report_${consultation.petName ?? "pet"}_${consultation.id ?? 1}.pdf',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildOnScreenReport(
    BuildContext context,
    ConsultationModel consultation,
    List<PrescriptionModel> clinicRx,
    List<PrescriptionModel> homeRx,
    SurgeryModel? surgery,
    List<FollowUpModel> followUps,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Clinic & Patient Header Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المريض: ${consultation.petName ?? "حيوان أليف"} (${consultation.petSpecies ?? ""})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'التاريخ: ${consultation.visitDate.length >= 10 ? consultation.visitDate.substring(0, 10) : consultation.visitDate}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('المالك: ${consultation.ownerName ?? "غير محدد"}', style: const TextStyle(fontSize: 13)),
                      if (consultation.temperature != null)
                        Text('حرارة الجسم: ${consultation.temperature}°C', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Clinical Assessment Card (SOAP)
          Card(
            color: AppColors.secondaryLight.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (consultation.symptoms?.isNotEmpty == true) ...[
                    Text('الشكوى والأعراض (S): ${consultation.symptoms}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    'التشخيص السريري (Assessment): ${consultation.diagnosis}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // SECTION 1: In-Clinic Procedures (RTL: Medication Rightmost -> Dosage -> Route -> Quantity -> Notes Leftmost)
          _buildSectionHeaderCard(
            sectionNumber: '1',
            title: 'الإجراءات والعلاجات داخل العيادة (In-Clinic Procedures)',
            icon: Icons.local_hospital_outlined,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          if (clinicRx.isEmpty)
            _buildEmptySectionBox('لا توجد علاجات أو حقن تم إعطاؤها داخل العيادة في هذه الزيارة.')
          else
            Directionality(
              textDirection: TextDirection.rtl,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(2.6), // Medication (Rightmost)
                    1: FlexColumnWidth(1.3), // Dosage
                    2: FlexColumnWidth(1.4), // Route
                    3: FlexColumnWidth(1.1), // Quantity
                    4: FlexColumnWidth(2.2), // Notes (Leftmost)
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1)),
                      children: [
                        _buildTableHeaderCell('الدواء / الإجراء'),
                        _buildTableHeaderCell('الجرعة'),
                        _buildTableHeaderCell('طريقة الإعطاء'),
                        _buildTableHeaderCell('الكمية'),
                        _buildTableHeaderCell('الملاحظات والإرشادات'),
                      ],
                    ),
                    ...clinicRx.map((rx) => TableRow(
                          children: [
                            _buildTableDataCell('${rx.displayName} ${rx.medicineForm != null ? "(${rx.medicineForm})" : ""}', isBold: true),
                            _buildTableDataCell(rx.dosage),
                            _buildTableDataCell(rx.route ?? 'حقن / موضعي'),
                            _buildTableDataCell('${rx.quantityDispensed}'),
                            _buildTableDataCell(rx.instructions ?? '-'),
                          ],
                        )),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),

          // SECTION 2: Home Treatment Prescription (RTL: Medication Rightmost -> Dosage -> Frequency -> Duration -> Notes Leftmost)
          _buildSectionHeaderCard(
            sectionNumber: '2',
            title: 'روشتة العلاج المنزلي للمريض (Home Treatment Prescription)',
            icon: Icons.medication_outlined,
            color: AppColors.accent,
          ),
          const SizedBox(height: 8),
          if (homeRx.isEmpty)
            _buildEmptySectionBox('لم يتم وصف علاجات منزلية في هذه الزيارة.')
          else
            Directionality(
              textDirection: TextDirection.rtl,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(2.6), // Medication (Rightmost)
                    1: FlexColumnWidth(1.3), // Dosage
                    2: FlexColumnWidth(1.4), // Frequency
                    3: FlexColumnWidth(1.1), // Duration
                    4: FlexColumnWidth(2.2), // Notes (Leftmost)
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.1)),
                      children: [
                        _buildTableHeaderCell('الدواء الموصوف'),
                        _buildTableHeaderCell('الجرعة'),
                        _buildTableHeaderCell('التكرار'),
                        _buildTableHeaderCell('المدة'),
                        _buildTableHeaderCell('تعليمات الاستخدام'),
                      ],
                    ),
                    ...homeRx.map((rx) => TableRow(
                          children: [
                            _buildTableDataCell('${rx.displayName} ${rx.medicineForm != null ? "(${rx.medicineForm})" : ""}', isBold: true),
                            _buildTableDataCell(rx.dosage),
                            _buildTableDataCell(rx.frequency),
                            _buildTableDataCell('لمدة ${rx.durationDays} يوم'),
                            _buildTableDataCell(rx.instructions ?? '-'),
                          ],
                        )),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),

          // SECTION 3: Surgery Appointments (if scheduled)
          if (surgery != null) ...[
            _buildSectionHeaderCard(
              sectionNumber: '3',
              title: 'مواعيد العمليات الجراحية المجدولة (Surgery Appointments)',
              icon: Icons.healing,
              color: Colors.deepOrange,
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.orange.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'العملية: ${surgery.surgeryName} (${surgery.surgeryCategory ?? "عام"})',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.brown.shade900),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            surgery.scheduledDate,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.brown.shade900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الجراح المسؤول: ${surgery.surgeonName ?? "الطبيب المعالج"}', style: const TextStyle(fontSize: 12)),
                        if (surgery.estimatedCost != null && surgery.estimatedCost! > 0)
                          Text(
                            'التكلفة التقديرية: ${surgery.estimatedCost!.toStringAsFixed(0)} ${AppStringsAr.currencyShort}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark),
                          ),
                      ],
                    ),
                    if (surgery.postOpNotes?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text('تعليمات وتجهيزات ما قبل الجراحة: ${surgery.postOpNotes}', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // SECTION 4: Follow-Up Sessions (if scheduled)
          if (followUps.isNotEmpty) ...[
            _buildSectionHeaderCard(
              sectionNumber: '4',
              title: 'جلسات المتابعة والمراجعات القادمة (Follow-Up Sessions)',
              icon: Icons.event_repeat,
              color: Colors.indigo,
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.rtl,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(2.5), // Reason / Session (Rightmost)
                    1: FlexColumnWidth(1.5), // Date
                    2: FlexColumnWidth(1.3), // Time
                    3: FlexColumnWidth(2.5), // Notes (Leftmost)
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1)),
                      children: [
                        _buildTableHeaderCell('الجلسة / سبب المراجعة'),
                        _buildTableHeaderCell('تاريخ المراجعة'),
                        _buildTableHeaderCell('الوقت المجدول'),
                        _buildTableHeaderCell('الملاحظات والإرشادات'),
                      ],
                    ),
                    ...followUps.map((f) => TableRow(
                          children: [
                            _buildTableDataCell(f.reason, isBold: true),
                            _buildTableDataCell(f.scheduledDate),
                            _buildTableDataCell(f.scheduledTime?.isNotEmpty == true ? f.scheduledTime! : 'خلال الدوام'),
                            _buildTableDataCell(f.notes?.isNotEmpty == true ? f.notes! : '-'),
                          ],
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Consultation Fees Card
          if (controller.showCost.value && consultation.visitCost > 0)
            Card(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('أتعاب الكشف والخدمات البيطرية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      '${consultation.visitCost.toStringAsFixed(0)} ${AppStringsAr.currencyShort}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderCard({
    required String sectionNumber,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(right: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySectionBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildTableDataCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 11,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
