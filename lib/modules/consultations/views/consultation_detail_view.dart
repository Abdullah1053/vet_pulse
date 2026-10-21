import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../routes/app_routes.dart';
import '../controllers/consultation_detail_controller.dart';

class ConsultationDetailView extends GetView<ConsultationDetailController> {
  const ConsultationDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Scaffold(
          appBar: AppBar(title: const Text('تفاصيل الكشف السريري')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      final item = controller.consultation.value;
      if (item == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('تفاصيل الكشف السريري')),
          body: const Center(child: Text('لم يتم العثور على بيانات الكشف')),
        );
      }

      final clinicRx =
          item.prescriptions.where((p) => p.isClinicAdministered).toList();
      final homeRx =
          item.prescriptions.where((p) => !p.isClinicAdministered).toList();

      return Scaffold(
        appBar: AppBar(
          title: Text('كشف: ${item.petName ?? "المريض"}'),
          actions: [
            if (item.ownerId != null)
              IconButton(
                icon: const Icon(Icons.receipt_long_rounded),
                tooltip: 'كشف الحساب المالي للمربي',
                onPressed: () => Get.toNamed(
                  AppRoutes.ownerAccountStatement,
                  arguments: item.ownerId,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'معاينة وطباعة الروشتة',
              onPressed: () => Get.toNamed(
                AppRoutes.prescriptionPreview,
                arguments: {
                  'consultation': item,
                  'scheduledSurgery': controller.scheduledSurgery.value,
                  'followUpSessions': controller.followUpSessions.toList(),
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.critical),
              tooltip: 'حذف الكشف',
              onPressed: () => controller.confirmDelete(context),
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
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text(
                    'طباعة الروشتة (PDF)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onPressed: () => Get.toNamed(
                    AppRoutes.prescriptionPreview,
                    arguments: {
                      'consultation': item,
                      'scheduledSurgery': controller.scheduledSurgery.value,
                      'followUpSessions': controller.followUpSessions.toList(),
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (item.ownerId != null) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text('كشف الحساب'),
                  onPressed: () => Get.toNamed(
                    AppRoutes.ownerAccountStatement,
                    arguments: item.ownerId,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.pets, size: 18),
                label: const Text('الملف'),
                onPressed: () =>
                    Get.toNamed(AppRoutes.patientDetail, arguments: item.petId),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Patient & Doctor Header Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.secondaryLight,
                            child: const Icon(
                              Icons.pets,
                              size: 28,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.petName ?? 'المريض',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.petSpecies ?? "حيوان أليف"} • المالك: ${item.ownerName ?? "غير محدد"}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () => Get.toNamed(
                                  AppRoutes.patientDetail,
                                  arguments: item.petId,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'الملف الطبي',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 9,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (item.ownerId != null) ...[
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => Get.toNamed(
                                    AppRoutes.ownerAccountStatement,
                                    arguments: item.ownerId,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1D3557)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.receipt_long_rounded,
                                          size: 12,
                                          color: Color(0xFF1D3557),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'كشف حساب المربي',
                                          style: TextStyle(
                                            color: Color(0xFF1D3557),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 15,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.visitDate.length >= 10
                                    ? item.visitDate.substring(0, 10)
                                    : item.visitDate,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Icon(
                                  Icons.medical_services_outlined,
                                  size: 15,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    item.doctorName ?? 'طبيب بيطري',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Vital Signs Strip
              Row(
                children: [
                  Expanded(
                    child: _buildVitalCard(
                      icon: Icons.thermostat,
                      title: 'حرارة الجسم',
                      value: item.temperature != null
                          ? '${item.temperature}°C'
                          : 'غير مسجلة',
                      color: (item.temperature != null &&
                              item.temperature! > 39.2)
                          ? AppColors.critical
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildVitalCard(
                      icon: Icons.favorite,
                      title: 'نبضات القلب',
                      value: item.heartRate != null
                          ? '${item.heartRate} bpm'
                          : 'غير مسجل',
                      color: Colors.pink.shade700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildVitalCard(
                      icon: Icons.payments,
                      title: 'رسوم الكشف (${item.paymentMethod})',
                      value:
                          '${item.visitCost.toStringAsFixed(0)} ${AppStringsAr.currencyShort}',
                      color: Colors.teal.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. SOAP Section
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'السجل السريري المنهجي (SOAP)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // S: Subjective
                      _buildSoapBlock(
                        letter: 'S',
                        letterTitle: 'الشكوى والأعراض الملاحظة (Subjective)',
                        content: (item.symptoms != null &&
                                item.symptoms!.isNotEmpty)
                            ? item.symptoms!
                            : 'لم يتم تسجيل شكوى محددة من المالك.',
                        color: Colors.amber.shade800,
                        bgColor: Colors.amber.shade50,
                      ),
                      const SizedBox(height: 14),

                      // O: Objective
                      _buildSoapBlock(
                        letter: 'O',
                        letterTitle:
                            'الفحص السريري والملاحظات البيطرية (Objective)',
                        content: (item.examinationFindings != null &&
                                item.examinationFindings!.isNotEmpty)
                            ? item.examinationFindings!
                            : 'فحص سريري عام ضمن المعدلات المعتادة.',
                        color: Colors.blue.shade800,
                        bgColor: Colors.blue.shade50,
                      ),
                      const SizedBox(height: 14),

                      // A: Assessment
                      _buildSoapBlock(
                        letter: 'A',
                        letterTitle: 'التشخيص الطبي المؤكد (Assessment)',
                        content: item.diagnosis,
                        isBold: true,
                        color: AppColors.critical,
                        bgColor: AppColors.criticalBackground,
                      ),
                      const SizedBox(height: 14),

                      // P: Plan
                      _buildSoapBlock(
                        letter: 'P',
                        letterTitle: 'الخطة العلاجية الشاملة (Plan)',
                        content: (item.treatmentPlan != null &&
                                item.treatmentPlan!.isNotEmpty)
                            ? item.treatmentPlan!
                            : 'تم صرف البروتوكول الدوائي الموضح أدناه.',
                        color: Colors.teal.shade800,
                        bgColor: Colors.teal.shade50,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // SECTION 1: In-Clinic Procedures (RTL Table: Medication Rightmost -> Notes Leftmost)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                              Icon(Icons.local_hospital_outlined, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '1. الإجراءات والعلاجات داخل العيادة',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${clinicRx.length} أصناف',
                              style: const TextStyle(fontSize: 12, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (clinicRx.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'لا توجد علاجات أو حقن تم إعطاؤها داخل العيادة.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
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
                                    _buildDetailTableHeader('الدواء / الإجراء'),
                                    _buildDetailTableHeader('الجرعة'),
                                    _buildDetailTableHeader('طريقة الإعطاء'),
                                    _buildDetailTableHeader('الكمية'),
                                    _buildDetailTableHeader('الملاحظات والإرشادات'),
                                  ],
                                ),
                                ...clinicRx.map((rx) => TableRow(
                                      children: [
                                        _buildDetailTableCell(
                                          '${rx.displayName} ${rx.medicineForm != null ? "(${rx.medicineForm})" : ""}',
                                          isBold: true,
                                        ),
                                        _buildDetailTableCell(rx.dosage),
                                        _buildDetailTableCell(rx.route ?? 'حقن / موضعي'),
                                        _buildDetailTableCell('${rx.quantityDispensed}'),
                                        _buildDetailTableCell(rx.instructions ?? '-'),
                                      ],
                                    )),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // SECTION 2: Home Treatment Prescription (RTL Table: Medication Rightmost -> Notes Leftmost)
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                              Icon(Icons.medication_outlined, color: AppColors.accent, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '2. روشتة العلاج المنزلي للمريض',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${homeRx.length} أصناف',
                              style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (homeRx.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'لم يتم وصف علاجات منزلية في هذه الزيارة.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
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
                                    _buildDetailTableHeader('الدواء الموصوف'),
                                    _buildDetailTableHeader('الجرعة'),
                                    _buildDetailTableHeader('التكرار'),
                                    _buildDetailTableHeader('المدة'),
                                    _buildDetailTableHeader('تعليمات الاستخدام'),
                                  ],
                                ),
                                ...homeRx.map((rx) => TableRow(
                                      children: [
                                        _buildDetailTableCell(
                                          '${rx.displayName} ${rx.medicineForm != null ? "(${rx.medicineForm})" : ""}',
                                          isBold: true,
                                        ),
                                        _buildDetailTableCell(rx.dosage),
                                        _buildDetailTableCell(rx.frequency),
                                        _buildDetailTableCell('لمدة ${rx.durationDays} يوم'),
                                        _buildDetailTableCell(rx.instructions ?? '-'),
                                      ],
                                    )),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // SECTION 3: Surgery Appointments (if scheduled)
              if (controller.scheduledSurgery.value != null) ...[
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.healing, color: Colors.deepOrange, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '3. مواعيد العمليات الجراحية المجدولة',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'العملية: ${controller.scheduledSurgery.value!.surgeryName} (${controller.scheduledSurgery.value!.surgeryCategory ?? "عام"})',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.brown.shade900),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      controller.scheduledSurgery.value!.scheduledDate,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.brown.shade900),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'الجراح المسؤول: ${controller.scheduledSurgery.value!.surgeonName ?? "الطبيب المعالج"}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  if (controller.scheduledSurgery.value!.estimatedCost != null &&
                                      controller.scheduledSurgery.value!.estimatedCost! > 0)
                                    Text(
                                      'التكلفة: ${controller.scheduledSurgery.value!.estimatedCost!.toStringAsFixed(0)} ${AppStringsAr.currencyShort}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark),
                                    ),
                                ],
                              ),
                              if (controller.scheduledSurgery.value!.postOpNotes?.isNotEmpty == true) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'تعليمات وتجهيزات ما قبل الجراحة: ${controller.scheduledSurgery.value!.postOpNotes}',
                                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade800),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // SECTION 4: Follow-Up Sessions (if scheduled)
              if (controller.followUpSessions.isNotEmpty) ...[
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                                Icon(Icons.event_repeat, color: Colors.indigo, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '4. جلسات المتابعة والمراجعات القادمة',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${controller.followUpSessions.length} جلسات',
                                style: TextStyle(fontSize: 12, color: Colors.indigo.shade900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Table(
                              border: TableBorder.all(color: Colors.grey.shade300),
                              columnWidths: const {
                                0: FlexColumnWidth(2.5), // Reason (Rightmost)
                                1: FlexColumnWidth(1.5), // Date
                                2: FlexColumnWidth(1.3), // Time
                                3: FlexColumnWidth(2.5), // Notes (Leftmost)
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1)),
                                  children: [
                                    _buildDetailTableHeader('الجلسة / سبب المراجعة'),
                                    _buildDetailTableHeader('تاريخ المراجعة'),
                                    _buildDetailTableHeader('الوقت المجدول'),
                                    _buildDetailTableHeader('الملاحظات والإرشادات'),
                                  ],
                                ),
                                ...controller.followUpSessions.map((f) => TableRow(
                                      children: [
                                        _buildDetailTableCell(f.reason, isBold: true),
                                        _buildDetailTableCell(f.scheduledDate),
                                        _buildDetailTableCell(f.scheduledTime?.isNotEmpty == true ? f.scheduledTime! : 'خلال الدوام'),
                                        _buildDetailTableCell(f.notes?.isNotEmpty == true ? f.notes! : '-'),
                                      ],
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 6. Consultation Financial & Owner Account Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
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
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'البيانات المالية للكشف',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: item.isFullyPaid
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : Colors.red.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.isFullyPaid
                                  ? 'مسدد بالكامل'
                                  : 'متبقي: ${item.remainingAmount.toStringAsFixed(0)} ر.ي',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: item.isFullyPaid
                                    ? AppColors.success
                                    : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFinancialInfoTile(
                              title: 'رسوم الكشف والخدمات',
                              value: '${item.visitCost.toStringAsFixed(0)} ر.ي',
                              color: Colors.blue.shade800,
                              bgColor: Colors.blue.shade50,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFinancialInfoTile(
                              title: 'المبلغ المسدد (${item.paymentMethod})',
                              value: '${item.paidAmount.toStringAsFixed(0)} ر.ي',
                              color: Colors.green.shade800,
                              bgColor: Colors.green.shade50,
                            ),
                          ),
                        ],
                      ),
                      if (item.ownerId != null) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D3557),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(
                              Icons.receipt_long_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'عرض كشف الحساب المالي للمربي (PDF & طباعة)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: () => Get.toNamed(
                              AppRoutes.ownerAccountStatement,
                              arguments: item.ownerId,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildFinancialInfoTile({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoapBlock({
    required String letter,
    required String letterTitle,
    required String content,
    required Color color,
    required Color bgColor,
    bool isBold = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: color,
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  letterTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: isBold ? color : AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDetailTableCell(String text, {bool isBold = false}) {
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
