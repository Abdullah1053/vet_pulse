import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../routes/app_routes.dart';
import '../controllers/consultations_list_controller.dart';
import '../widgets/consultation_details_dialog.dart';

class ConsultationsListView extends StatelessWidget {
  const ConsultationsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ConsultationsListController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الكشوفات السريرية'),
        actions: [
          IconButton(
            tooltip: AppStringsAr.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadConsultations,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(AppStringsAr.newVisitAction, style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => Get.toNamed(AppRoutes.newConsultation)?.then((_) => controller.loadConsultations()),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                CustomTextField(
                  label: 'بحث في الكشوفات',
                  hint: 'ابحث باسم المريض، المربي، أو التشخيص الطبي...',
                  controller: controller.searchController,
                  prefixIcon: const Icon(Icons.search),
                  onChanged: controller.onSearchChanged,
                ),
                const SizedBox(height: 12),
                Obx(() => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(controller, 'all', 'الكل (${controller.allConsultations.length})'),
                          const SizedBox(width: 8),
                          _buildFilterChip(controller, 'today', 'كشوفات اليوم'),
                          const SizedBox(width: 8),
                          _buildFilterChip(controller, 'this_week', 'هذا الأسبوع'),
                          const SizedBox(width: 8),
                          _buildFilterChip(controller, 'this_month', 'هذا الشهر'),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          const Divider(height: 1),

          // Consultations List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredConsultations.isEmpty) {
                return EmptyStateView(
                  icon: Icons.assignment_outlined,
                  title: 'لا توجد كشوفات مطابقة للبحث',
                  subtitle: 'يمكنك إنشاء كشف وفحص سريري جديد للمريض',
                  actionText: AppStringsAr.newVisitAction,
                  onAction: () => Get.toNamed(AppRoutes.newConsultation)?.then((_) => controller.loadConsultations()),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.filteredConsultations.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final visit = controller.filteredConsultations[index];
                  final clinicCount = visit.prescriptions.where((p) => p.isClinicAdministered).length;
                  final homeCount = visit.prescriptions.where((p) => !p.isClinicAdministered).length;

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => ConsultationDetailsDialog.show(
                        context,
                        consultation: visit,
                        onDeleted: controller.loadConsultations,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.secondaryLight,
                                      child: const Icon(Icons.pets, color: AppColors.primary, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${visit.petName ?? "المريض"} (${visit.petSpecies ?? ""})',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        Text(
                                          'المالك: ${visit.ownerName ?? "غير محدد"}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    StatusChip(
                                      label: '${visit.visitCost.toStringAsFixed(0)} ريال يمني',
                                      type: ChipStatusType.success,
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                                      onSelected: (action) {
                                        if (action == 'details') {
                                          ConsultationDetailsDialog.show(
                                            context,
                                            consultation: visit,
                                            onDeleted: controller.loadConsultations,
                                          );
                                        } else if (action == 'print') {
                                          Get.toNamed(
                                            AppRoutes.prescriptionPreview,
                                            arguments: {
                                              'consultation': visit,
                                              'prescriptions': visit.prescriptions,
                                            },
                                          );
                                        } else if (action == 'delete') {
                                          ConsultationDetailsDialog.show(
                                            context,
                                            consultation: visit,
                                            onDeleted: controller.loadConsultations,
                                          );
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'details',
                                          child: Row(
                                            children: [
                                              Icon(Icons.visibility, size: 18, color: AppColors.primary),
                                              SizedBox(width: 8),
                                              Text('عرض التفاصيل'),
                                            ],
                                          ),
                                        ),
                                        if (visit.prescriptions.isNotEmpty)
                                          PopupMenuItem(
                                            value: 'print',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.print, size: 18, color: AppColors.accent),
                                                const SizedBox(width: 8),
                                                const Text('طباعة الروشتة'),
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
                            const Divider(height: 16),

                            Text(
                              'التشخيص: ${visit.diagnosis}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkNeutral),
                            ),
                            if (visit.symptoms != null && visit.symptoms!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'الأعراض والشكوى: ${visit.symptoms}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    if (clinicCount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        margin: const EdgeInsets.only(left: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: Colors.amber.shade200),
                                        ),
                                        child: Text(
                                          '$clinicCount إبر/مساعدات عيادة',
                                          style: TextStyle(fontSize: 11, color: Colors.brown.shade800, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    if (homeCount > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryLight.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          '$homeCount أدوية منزلية',
                                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 12, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      visit.visitDate.substring(0, 10),
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
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

  Widget _buildFilterChip(ConsultationsListController controller, String key, String label) {
    final isSelected = controller.selectedFilter.value == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.setFilter(key),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.darkNeutral,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}
