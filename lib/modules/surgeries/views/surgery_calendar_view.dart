import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/surgery_model.dart';
import '../../../routes/app_routes.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/surgery_form_controller.dart';
import '../controllers/surgery_list_controller.dart';

class SurgeryCalendarView extends GetView<SurgeryListController> {
  const SurgeryCalendarView({super.key});

  void _confirmCancelSurgery(BuildContext context, int id, String surgeryName, {int? petId}) {
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
            Text('هل ترغب بإلغاء موعد عملية "$surgeryName"؟ سيتم حفظ العملية في السجل الطبي بحالة ملغية دون حذف البيانات.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'سبب الإلغاء (اختياري)',
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
              controller.cancelSurgery(
                id,
                cancelReason: reason.isNotEmpty ? reason : 'تم إلغاء العملية الجراحية بواسطة الطبيب',
                petId: petId,
              );
            },
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
  }

  void _confirmNoShow(BuildContext context, int id, String surgeryName, {int? petId}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_off_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('تسجيل عدم حضور المريض'),
          ],
        ),
        content: Text('تأكيد عدم حضور المريض لعملية "$surgeryName" في موعدها المحدد؟ سيتم تحديث الحالة إلى [متأخرة / لم يحضر].'),
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
              controller.markNoShow(id, petId: petId);
            },
            child: const Text('تسجيل لم يحضر'),
          ),
        ],
      ),
    );
  }

  ChipStatusType _getChipType(SurgeryModel item) {
    if (item.status == 'completed') return ChipStatusType.success;
    if (item.status == 'in_progress') return ChipStatusType.warning;
    if (item.isOverdue || item.isNoShow) return ChipStatusType.critical;
    if (item.status == 'cancelled') return ChipStatusType.neutral;
    return ChipStatusType.info;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStringsAr.surgeries),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(AppStringsAr.scheduleSurgery, style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          if (Get.isRegistered<AuthController>() &&
              !Get.find<AuthController>().checkPermission((u) => u.canPerformSurgeries, 'جدولة عملية جراحية متاح للأطباء فقط')) {
            return;
          }
          if (Get.isRegistered<SurgeryFormController>()) {
            Get.find<SurgeryFormController>().clearForm();
          }
          Get.toNamed(AppRoutes.newSurgery)?.then((_) => controller.loadSurgeries());
        },
      ),
      body: Column(
        children: [
          // Filter Tabs Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Obx(() {
              final active = controller.selectedFilter.value;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'الكل (${controller.surgeries.length})', active == 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'today',
                      'عمليات اليوم (${controller.surgeries.where((s) => s.isToday && s.status != "cancelled").length})',
                      active == 'today',
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'overdue',
                      'المتأخرة (${controller.surgeries.where((s) => s.isOverdue).length})',
                      active == 'overdue',
                      isAlert: controller.surgeries.any((s) => s.isOverdue),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'upcoming',
                      'القادمة (${controller.surgeries.where((s) => s.status == "scheduled" && !s.isToday && !s.isOverdue).length})',
                      active == 'upcoming',
                    ),
                  ],
                ),
              );
            }),
          ),
          const Divider(height: 1),

          // Surgeries List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final displayedList = controller.filteredSurgeries;

              if (displayedList.isEmpty) {
                return EmptyStateView(
                  icon: Icons.healing,
                  title: 'لا توجد عمليات جراحية في هذا التبويب',
                  subtitle: 'يمكنك جدولة عملية جديدة أو تغيير تصنيف الفلتر لمشاهدة بقية العمليات',
                  actionText: AppStringsAr.scheduleSurgery,
                  onAction: () {
                    if (Get.isRegistered<AuthController>() &&
                        !Get.find<AuthController>().checkPermission((u) => u.canPerformSurgeries, 'جدولة عملية جراحية متاح للأطباء فقط')) {
                      return;
                    }
                    if (Get.isRegistered<SurgeryFormController>()) {
                      Get.find<SurgeryFormController>().clearForm();
                    }
                    Get.toNamed(AppRoutes.newSurgery)?.then((_) => controller.loadSurgeries());
                  },
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: displayedList.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = displayedList[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Get.toNamed(AppRoutes.surgeryDetail, arguments: item)?.then((_) => controller.loadSurgeries());
                      },
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
                                      type: _getChipType(item),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                                      onSelected: (action) {
                                        if (action == 'details') {
                                          Get.toNamed(AppRoutes.surgeryDetail, arguments: item)?.then((_) => controller.loadSurgeries());
                                        } else if (action == 'edit') {
                                          if (Get.isRegistered<SurgeryFormController>()) {
                                            Get.find<SurgeryFormController>().initEditSurgery(item);
                                          }
                                          Get.toNamed(AppRoutes.newSurgery)?.then((_) => controller.loadSurgeries());
                                        } else if (action == 'cancel') {
                                          _confirmCancelSurgery(context, item.id!, item.surgeryName, petId: item.petId);
                                        } else if (action == 'no_show') {
                                          _confirmNoShow(context, item.id!, item.surgeryName, petId: item.petId);
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
                                              SizedBox(width: 8),
                                              const Text(AppStringsAr.edit),
                                            ],
                                          ),
                                        ),
                                        if (item.status == 'scheduled') ...[
                                          const PopupMenuItem(
                                            value: 'no_show',
                                            child: Row(
                                              children: [
                                                Icon(Icons.person_off_outlined, size: 18, color: Colors.orange),
                                                SizedBox(width: 8),
                                                Text('لم يحضر المريض'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'cancel',
                                            child: Row(
                                              children: [
                                                Icon(Icons.cancel_outlined, size: 18, color: AppColors.critical),
                                                SizedBox(width: 8),
                                                Text('إلغاء العملية'),
                                              ],
                                            ),
                                          ),
                                        ],
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
                                  if (item.status != 'completed' && item.status != 'cancelled')
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

                            // Cost badge and action buttons
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
                                        'التكلفة التقديرية: ${item.estimatedCost?.toInt()} ${AppStringsAr.currencyShort}',
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

                            // Action buttons in Wrap
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
                                  if (item.status == 'in_progress')
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, bool isSelected, {bool isAlert = false}) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: isAlert ? Colors.red.shade100 : AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected
            ? (isAlert ? AppColors.critical : AppColors.primary)
            : (isAlert ? AppColors.critical : AppColors.textSecondary),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected
            ? (isAlert ? AppColors.critical : AppColors.primary)
            : (isAlert ? Colors.red.shade200 : Colors.grey.shade300),
      ),
      onSelected: (_) => controller.setFilter(key),
    );
  }
}
