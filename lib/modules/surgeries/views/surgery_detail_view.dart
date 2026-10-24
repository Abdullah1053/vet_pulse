import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/surgery_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/surgery_detail_controller.dart';

class SurgeryDetailView extends GetView<SurgeryDetailController> {
  const SurgeryDetailView({super.key});

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.critical),
            SizedBox(width: 8),
            Text('إلغاء العملية الجراحية'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('يرجى ذكر سبب إلغاء موعد العملية:'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'مثال: طلب المالك تأجيل العملية، عدم استقرار الحالة...',
              ),
              maxLines: 2,
            ),
          ],
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
            onPressed: () {
              final reason = reasonController.text.trim();
              Navigator.of(ctx).pop();
              controller.cancelSurgery(reason.isNotEmpty ? reason : 'تم إلغاء الموعد بناءً على طلب الطبيب');
            },
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
  }

  void _showNoShowDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_off_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('تأكيد عدم حضور المريض'),
          ],
        ),
        content: const Text('هل ترغب بتسجيل عدم حضور المريض للعملية الجراحية؟ سيتم الاحتفاظ بالسجل في التاريخ الطبي للحيوان.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStringsAr.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.markNoShow();
            },
            child: const Text('تسجيل عدم الحضور'),
          ),
        ],
      ),
    );
  }

  ChipStatusType _getChipType(SurgeryModel s) {
    if (s.status == 'completed') return ChipStatusType.success;
    if (s.status == 'in_progress') return ChipStatusType.warning;
    if (s.isOverdue || s.isNoShow) return ChipStatusType.critical;
    if (s.status == 'cancelled') return ChipStatusType.neutral;
    return ChipStatusType.info;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Scaffold(
          appBar: AppBar(title: const Text('تفاصيل العملية الجراحية')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      final surgery = controller.surgery.value;
      if (surgery == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('تفاصيل العملية الجراحية')),
          body: EmptyStateView(
            icon: Icons.healing,
            title: 'لم يتم العثور على العملية الجراحية',
            subtitle: 'قد تكون العملية غير متوفرة أو تم تعديل معرفها',
            actionText: 'العودة',
            onAction: () => Get.back(),
          ),
        );
      }

      final fin = controller.financialSummary.value;
      final double totalCost = (fin?['amount'] as num?)?.toDouble() ?? surgery.estimatedCost ?? 0.0;
      final double paidAmount = (fin?['paid_amount'] as num?)?.toDouble() ?? (surgery.status == 'completed' ? totalCost : 0.0);
      final double remainingAmount = (fin?['remaining_amount'] as num?)?.toDouble() ?? 0.0;
      final String paymentMethod = (fin?['payment_method'] as String?) ?? 'نقدا';

      return Scaffold(
        appBar: AppBar(
          title: Text(surgery.surgeryName),
          actions: [
            if (surgery.status == 'completed') ...[
              IconButton(
                icon: const Icon(Icons.print_outlined),
                tooltip: 'طباعة التقرير الجراحي',
                onPressed: controller.printReport,
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'مشاركة التقرير (PDF)',
                onPressed: controller.shareReportPdf,
              ),
              IconButton(
                icon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
                tooltip: 'إرسال التقرير عبر واتساب',
                onPressed: controller.shareOnWhatsApp,
              ),
            ],
            if (surgery.status == 'scheduled')
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: AppStringsAr.edit,
                onPressed: controller.navigateToEdit,
              ),
          ],
        ),
        bottomNavigationBar: _buildBottomActions(context, surgery),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Patient & Owner Info Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.pets, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              '${surgery.petName ?? "المريض"} (${surgery.petSpecies ?? ""})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => Get.toNamed(AppRoutes.patientDetail, arguments: surgery.petId),
                          child: const Row(
                            children: [
                              Text('الملف الطبي', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 11, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'المالك: ${surgery.ownerName ?? "غير محدد"} ${surgery.ownerPhone != null ? "• ${surgery.ownerPhone}" : ""}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Get.toNamed(AppRoutes.ownerAccountStatement, arguments: surgery.petId);
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('كشف الحساب', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Surgery Status, Timing & Category Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                surgery.surgeryName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          StatusChip(
                            label: surgery.statusDisplayArabic,
                            type: _getChipType(surgery),
                          ),
                        ],
                      ),
                      const Divider(height: 18),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('الموعد: ${surgery.scheduledDate}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.category_outlined, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text('التصنيف: ${surgery.surgeryCategory ?? "جراحة عامة"}', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Text('الجراح: ${surgery.surgeonName ?? "طبيب بيطري"}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Pre-Op Safety Checklist Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                surgery.preOpChecklistPassed ? Icons.check_circle : Icons.pending_actions,
                                color: surgery.preOpChecklistPassed ? AppColors.success : Colors.orange,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                surgery.preOpChecklistPassed ? 'تم استيفاء معايير الأمان قبل الجراحة' : 'معايير ما قبل الجراحة معلقة',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: surgery.preOpChecklistPassed ? AppColors.success : Colors.brown,
                                ),
                              ),
                            ],
                          ),
                          if (surgery.status != 'completed' && surgery.status != 'cancelled')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: surgery.preOpChecklistPassed ? Colors.grey.shade300 : AppColors.success,
                                foregroundColor: surgery.preOpChecklistPassed ? Colors.black87 : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              onPressed: controller.togglePreOpChecklist,
                              child: Text(surgery.preOpChecklistPassed ? 'إلغاء الاعتماد' : 'اعتماد المعايير'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Text(
                          '• صيام الحيوان عن الأكل والشرب لمدة 12 ساعة قبل التخدير.\n• مراجعة نتائج تحاليل الدم الشاملة ووظائف الأعضاء.\n• توقيع المالك على استمارة الموافقة الخطية للجراحة والتخدير.',
                          style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 4. Anesthesia Protocol Card
              if (surgery.anesthesiaProtocol != null && surgery.anesthesiaProtocol!.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.vaccines_outlined, color: AppColors.accent, size: 20),
                            SizedBox(width: 8),
                            Text('بروتوكول التخدير المتبع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(surgery.anesthesiaProtocol!, style: const TextStyle(fontSize: 13, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 5. Post-Op Notes / Clinical Outcome Card
              if (surgery.postOpNotes != null && surgery.postOpNotes!.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notes, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text('تقرير العملية وإرشادات ما بعد الجراحة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            surgery.postOpNotes!,
                            style: const TextStyle(fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 6. Follow-up Sessions
              if (controller.followUps.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.event_repeat, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Text('جلسات المتابعة والمراجعة المسجلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...controller.followUps.map((f) => Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(f.reason, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('${f.scheduledDate} ${f.scheduledTime ?? ""}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                  StatusChip(
                                    label: f.status == 'completed' ? 'مكتملة' : 'قيد الانتظار',
                                    type: f.status == 'completed' ? ChipStatusType.success : ChipStatusType.warning,
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 7. Financial Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.payments_outlined, color: Colors.teal, size: 20),
                          SizedBox(width: 8),
                          Text('الملخص المالي للعملية الجراحية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('التكلفة الإجمالية:', style: TextStyle(fontSize: 13)),
                          Text(
                            '${totalCost.toStringAsFixed(0)} ${AppStringsAr.currencyShort}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('المبلغ المسدد ($paymentMethod):', style: const TextStyle(fontSize: 13)),
                          Text(
                            '${paidAmount.toStringAsFixed(0)} ${AppStringsAr.currencyShort}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('المتبقي آجل:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(
                            remainingAmount > 0
                                ? '${remainingAmount.toStringAsFixed(0)} ${AppStringsAr.currencyShort}'
                                : 'خالص ومسدد',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: remainingAmount > 0 ? AppColors.critical : AppColors.success,
                            ),
                          ),
                        ],
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

  Widget? _buildBottomActions(BuildContext context, SurgeryModel s) {
    if (s.status == 'scheduled') {
      return Container(
        padding: const EdgeInsets.all(12),
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
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow, size: 18),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              label: const Text('بدء العملية (جارية الآن)'),
              onPressed: controller.startSurgery,
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.person_off_outlined, size: 18),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange)),
              label: const Text('لم يحضر المريض'),
              onPressed: () => _showNoShowDialog(context),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined, size: 18),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.critical, side: const BorderSide(color: AppColors.critical)),
              label: const Text('إلغاء العملية'),
              onPressed: () => _showCancelDialog(context),
            ),
            TextButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text(AppStringsAr.edit),
              onPressed: controller.navigateToEdit,
            ),
          ],
        ),
      );
    }

    if (s.status == 'in_progress') {
      return Container(
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
        child: ElevatedButton.icon(
          icon: const Icon(Icons.task_alt, size: 20),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          label: const Text(
            'إدخال تفاصيل الجراحة وإتمام العملية والتخريج',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          onPressed: controller.navigateToComplete,
        ),
      );
    }

    if (s.status == 'completed') {
      return Container(
        padding: const EdgeInsets.all(14),
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
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                label: const Text('طباعة ومشاركة التقرير الجراحي والروشتة'),
                onPressed: controller.printReport,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 26),
              tooltip: 'واتساب',
              onPressed: controller.shareOnWhatsApp,
            ),
          ],
        ),
      );
    }

    return null;
  }
}
