import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/surgery_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/surgery_controller.dart';

class SurgeryCalendarView extends GetView<SurgeryController> {
  const SurgeryCalendarView({super.key});

  void _confirmDeleteSurgery(BuildContext context, int id, String surgeryName, {int? petId}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.critical),
            SizedBox(width: 8),
            Text('حذف العملية الجراحية'),
          ],
        ),
        content: Text('هل أنت متأكد من حذف عملية "$surgeryName" بشكل نهائي؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStringsAr.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.critical, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.deleteSurgery(id, petId: petId);
            },
            child: const Text(AppStringsAr.delete),
          ),
        ],
      ),
    );
  }

  void _showSurgeryDetailsDialog(BuildContext context, SurgeryModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.surgeryName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            StatusChip(
              label: item.statusDisplayArabic,
              type: item.status == 'completed'
                  ? ChipStatusType.success
                  : (item.status == 'in_progress' ? ChipStatusType.warning : ChipStatusType.info),
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
                // Patient & Owner Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.pets, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'المريض: ${item.petName ?? "غير محدد"} (${item.petSpecies ?? ""})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'المالك: ${item.ownerName ?? "غير محدد"} ${item.ownerPhone != null ? "• ${item.ownerPhone}" : ""}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.medical_services_outlined, size: 18, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'الجراح: ${item.surgeonName ?? "طبيب بيطري"}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Timing & Category
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('الموعد: ${item.scheduledDate}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (item.surgeryCategory != null) ...[
                  const SizedBox(height: 6),
                  Text('تصنيف الجراحة: ${item.surgeryCategory}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
                const SizedBox(height: 14),

                // Pre-Op Safety Checklist Section
                const Text(
                  'معايير السلامة والجراحة:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkNeutral),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.preOpChecklistPassed ? AppColors.successBackground : AppColors.warningBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: item.preOpChecklistPassed ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                item.preOpChecklistPassed ? Icons.check_circle : Icons.pending_actions,
                                color: item.preOpChecklistPassed ? AppColors.success : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.preOpChecklistPassed ? 'تم استيفاء معايير الأمان' : 'المعايير معلقة / قيد التدقيق',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: item.preOpChecklistPassed ? AppColors.success : Colors.brown,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: item.preOpChecklistPassed ? Colors.grey.shade300 : AppColors.success,
                              foregroundColor: item.preOpChecklistPassed ? Colors.black87 : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            onPressed: () {
                              controller.toggleChecklist(item);
                              Navigator.of(ctx).pop();
                            },
                            child: Text(item.preOpChecklistPassed ? 'إلغاء الاعتماد' : 'اعتماد المعايير'),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '• الصيام عن الطعام والماء (12 ساعة)\n• تحاليل الدم الشاملة ووظائف الكبد والكلى\n• إقرار وتوقيع المالك بالموافقة على التخدير',
                          style: TextStyle(fontSize: 12, height: 1.5, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Anesthesia Protocol
                if (item.anesthesiaProtocol != null && item.anesthesiaProtocol!.isNotEmpty) ...[
                  const Text('بروتوكول التخدير:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Text(item.anesthesiaProtocol!, style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],

                // Post-op notes
                if (item.postOpNotes != null && item.postOpNotes!.isNotEmpty) ...[
                  const Text('ملاحظات بعد الجراحة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Text(item.postOpNotes!, style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                ],

                // Cost in Yemeni Rial
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'التكلفة التقديرية: ${item.estimatedCost?.toInt() ?? 0} ريال يمني',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.delete_outline, color: AppColors.critical, size: 18),
            label: const Text(AppStringsAr.delete, style: TextStyle(color: AppColors.critical)),
            onPressed: () {
              Navigator.of(ctx).pop();
              _confirmDeleteSurgery(context, item.id!, item.surgeryName, petId: item.petId);
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text(AppStringsAr.edit),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.initEditSurgery(item);
              Get.toNamed(AppRoutes.newSurgery);
            },
          ),
          if (item.status != 'completed')
            ElevatedButton.icon(
              icon: const Icon(Icons.task_alt, size: 18),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
              label: const Text('إتمام العملية'),
              onPressed: () {
                Navigator.of(ctx).pop();
                Get.toNamed(AppRoutes.completeSurgery, arguments: item)?.then((_) => controller.loadSurgeries());
              },
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStringsAr.surgeries),
        actions: [
          IconButton(
            tooltip: AppStringsAr.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadSurgeries,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(AppStringsAr.scheduleSurgery, style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          controller.clearForm();
          Get.toNamed(AppRoutes.newSurgery);
        },
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.surgeries.isEmpty) {
          return EmptyStateView(
            icon: Icons.healing,
            title: 'لا توجد عمليات جراحية مجدولة',
            subtitle: 'يمكنك جدولة عملية جديدة وإعداد قائمة التحقق وتفاصيل التخدير',
            actionText: AppStringsAr.scheduleSurgery,
            onAction: () {
              controller.clearForm();
              Get.toNamed(AppRoutes.newSurgery);
            },
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.surgeries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = controller.surgeries[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showSurgeryDetailsDialog(context, item),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.surgeryName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => Get.toNamed(AppRoutes.patientDetail, arguments: item.petId),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.pets, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item.petName ?? "المريض"} (${item.petSpecies ?? ""})',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '• المالك: ${item.ownerName ?? ""}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              StatusChip(
                                label: item.statusDisplayArabic,
                                type: item.status == 'completed'
                                    ? ChipStatusType.success
                                    : (item.status == 'in_progress' ? ChipStatusType.warning : ChipStatusType.info),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                                onSelected: (action) {
                                  if (action == 'details') {
                                    _showSurgeryDetailsDialog(context, item);
                                  } else if (action == 'edit') {
                                    controller.initEditSurgery(item);
                                    Get.toNamed(AppRoutes.newSurgery);
                                  } else if (action == 'delete') {
                                    _confirmDeleteSurgery(context, item.id!, item.surgeryName);
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 'details',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility, size: 18, color: AppColors.primary),
                                        SizedBox(width: 8),
                                        Text('عرض التفاصيل والمعايير'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 18, color: AppColors.accent),
                                        const SizedBox(width: 8),
                                        const Text(AppStringsAr.edit),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 18, color: AppColors.critical),
                                        SizedBox(width: 8),
                                        Text(AppStringsAr.delete),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                item.scheduledDate,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                          if (item.surgeryCategory != null)
                            StatusChip(
                              label: item.surgeryCategory!,
                              type: ChipStatusType.neutral,
                              fontSize: 10,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Text(
                        'الجراح المسؤول: ${item.surgeonName ?? "طبيب بيطري"}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      if (item.anesthesiaProtocol != null && item.anesthesiaProtocol!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'بروتوكول التخدير: ${item.anesthesiaProtocol}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Pre-op Checklist Card Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: item.preOpChecklistPassed ? AppColors.successBackground : AppColors.warningBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: item.preOpChecklistPassed ? AppColors.success : AppColors.warning,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    item.preOpChecklistPassed ? Icons.check_circle : Icons.pending_actions,
                                    size: 18,
                                    color: item.preOpChecklistPassed ? AppColors.success : AppColors.warning,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.preOpChecklistPassed
                                          ? 'تم استيفاء معايير الأمان قبل الجراحة'
                                          : 'معايير ما قبل الجراحة بحاجة للاعتماد',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: item.preOpChecklistPassed ? AppColors.success : Colors.brown,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => controller.toggleChecklist(item),
                              child: Text(
                                item.preOpChecklistPassed ? 'إلغاء' : 'اعتماد',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cost badge and action buttons (properly contained)
                      if (item.estimatedCost != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.payments_outlined, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'التكلفة التقديرية: ${item.estimatedCost?.toInt()} ريال يمني',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Action buttons in Wrap to prevent overflow
                      if (item.status == 'scheduled' || item.status == 'in_progress')
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            if (item.status == 'scheduled')
                              OutlinedButton.icon(
                                icon: const Icon(Icons.play_arrow, size: 16),
                                label: const Text('بدء العملية'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                ),
                                onPressed: () => controller.updateStatus(item.id!, 'in_progress', petId: item.petId),
                              ),
                            if (item.status == 'in_progress' || item.status == 'scheduled')
                              ElevatedButton.icon(
                                icon: const Icon(Icons.task_alt, size: 16),
                                label: const Text('إتمام وتخريج'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Get.toNamed(AppRoutes.completeSurgery, arguments: item)?.then((_) => controller.loadSurgeries()),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
