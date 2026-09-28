import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../routes/app_routes.dart';
import '../controllers/surgery_controller.dart';

class SurgeryCalendarView extends GetView<SurgeryController> {
  const SurgeryCalendarView({super.key});

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
                              const SizedBox(height: 2),
                              Text(
                                'المريض: ${item.petName ?? "غير محدد"} (${item.petSpecies ?? ""}) • المالك: ${item.ownerName ?? ""}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
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
                          Row(
                            children: [
                              Icon(
                                item.preOpChecklistPassed ? Icons.check_circle : Icons.pending_actions,
                                size: 18,
                                color: item.preOpChecklistPassed ? AppColors.success : AppColors.warning,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.preOpChecklistPassed
                                    ? 'تم التحقق من معايير السلامة قبل الجراحة (Pre-Op Passed)'
                                    : 'معايير ما قبل الجراحة بحاجة للاعتماد',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: item.preOpChecklistPassed ? AppColors.success : Colors.brown,
                                ),
                              ),
                            ],
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

                    // Change status dropdown / actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.estimatedCost != null ? 'التكلفة: ${item.estimatedCost} ${AppStringsAr.currencyShort}' : '',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        Row(
                          children: [
                            if (item.status == 'scheduled')
                              TextButton.icon(
                                icon: const Icon(Icons.play_arrow, size: 16),
                                label: const Text('بدء العملية'),
                                onPressed: () => controller.updateStatus(item.id!, 'in_progress'),
                              ),
                            if (item.status == 'in_progress')
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('إتمام العملية'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                onPressed: () => controller.updateStatus(item.id!, 'completed'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
