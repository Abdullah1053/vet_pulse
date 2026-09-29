import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../data/models/consultation_model.dart';
import '../../../data/repositories/consultation_repository.dart';
import '../../../routes/app_routes.dart';

class ConsultationDetailsDialog extends StatelessWidget {
  final ConsultationModel consultation;
  final VoidCallback? onDeleted;

  const ConsultationDetailsDialog({
    super.key,
    required this.consultation,
    this.onDeleted,
  });

  static Future<void> show(
    BuildContext context, {
    required ConsultationModel consultation,
    VoidCallback? onDeleted,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => ConsultationDetailsDialog(
        consultation: consultation,
        onDeleted: onDeleted,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.critical),
            SizedBox(width: 8),
            Text('حذف الكشف السريري'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذا الكشف السريري بالكامل؟\nسيتم إرجاع كميات الأدوية المصروفة من العيادة إلى مخزون الصيدلية تلقائياً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStringsAr.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final nav = Navigator.of(context);
              Navigator.of(ctx).pop(); // Close confirm dialog
              if (consultation.id != null) {
                await ConsultationRepository().deleteConsultation(consultation.id!);
                Get.snackbar(
                  'تم الحذف',
                  'تم حذف الكشف السريري وإعادة مخزون الأدوية بنجاح',
                  backgroundColor: Colors.green.shade100,
                );
                nav.pop(); // Close details dialog
                onDeleted?.call();
              }
            },
            child: const Text(AppStringsAr.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clinicRx = consultation.prescriptions.where((p) => p.isClinicAdministered).toList();
    final homeRx = consultation.prescriptions.where((p) => !p.isClinicAdministered).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.medical_information_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تفاصيل الكشف السريري',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    consultation.visitDate.substring(0, 10),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Patient & Doctor Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${consultation.petName ?? "المريض"} (${consultation.petSpecies ?? ""})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'المالك: ${consultation.ownerName ?? "غير محدد"}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'الطبيب المعالج',
                          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                        Text(
                          consultation.doctorName ?? 'طبيب بيطري',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Clinical Findings (SOAP)
              const Text('التقييم السريري والتشخيص:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (consultation.symptoms != null && consultation.symptoms!.isNotEmpty)
                      Text('• شكوى المربي والأعراض: ${consultation.symptoms}', style: const TextStyle(fontSize: 12)),
                    if (consultation.examinationFindings != null && consultation.examinationFindings!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('• الفحص السريري: ${consultation.examinationFindings}', style: const TextStyle(fontSize: 12)),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '• التشخيص النهائي: ${consultation.diagnosis}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkNeutral),
                    ),
                    if (consultation.treatmentPlan != null && consultation.treatmentPlan!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('• خطة العلاج: ${consultation.treatmentPlan}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Vitals
              if (consultation.temperature != null || consultation.heartRate != null) ...[
                const Text('العلامات الحيوية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (consultation.temperature != null)
                      _buildVitalChip(Icons.thermostat, '${consultation.temperature}°C', 'الحرارة'),
                    if (consultation.heartRate != null)
                      _buildVitalChip(Icons.favorite_border, '${consultation.heartRate} bpm', 'النبض'),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Section 1: Clinic Administered Injections & Treatments
              if (clinicRx.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.vaccines, size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'إبر ومساعدات صرفت في العيادة (${clinicRx.length}):',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...clinicRx.map((rx) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rx.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text(
                                  'الجرعة: ${rx.dosage} • الطريق: ${rx.route ?? "تحت الجلد/عضلي"}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'صرف: ${rx.quantityDispensed}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.accent),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 10),
              ],

              // Section 2: Home Prescriptions for Owner
              if (homeRx.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.medication_liquid_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'روشتة علاج للمربي (${homeRx.length}):',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...homeRx.map((rx) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rx.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(
                            'طريقة الاستعمال: ${rx.dosage} • التكرار: ${rx.frequency} • المدة: ${rx.durationDays} يوم',
                            style: const TextStyle(fontSize: 11, color: AppColors.darkNeutral),
                          ),
                          if (rx.instructions != null && rx.instructions!.isNotEmpty)
                            Text(
                              'تعليمات: ${rx.instructions}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    )),
                const SizedBox(height: 10),
              ],

              // Total Fees in Yemeni Rial
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إجمالي أتعاب الكشف والعلاج:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      '${consultation.visitCost.toStringAsFixed(0)} ريال يمني',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.delete_outline, color: AppColors.critical, size: 18),
          label: const Text(AppStringsAr.delete, style: TextStyle(color: AppColors.critical)),
          onPressed: () => _confirmDelete(context),
        ),
        if (consultation.prescriptions.isNotEmpty)
          ElevatedButton.icon(
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('طباعة الروشتة (PDF)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              Get.toNamed(
                AppRoutes.prescriptionPreview,
                arguments: {
                  'consultation': consultation,
                  'prescriptions': consultation.prescriptions,
                },
              );
            },
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }

  Widget _buildVitalChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text('$label: $value', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
