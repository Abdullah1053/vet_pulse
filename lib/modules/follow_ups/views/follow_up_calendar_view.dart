import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../routes/app_routes.dart';
import '../controllers/follow_up_controller.dart';

class FollowUpCalendarView extends GetView<FollowUpController> {
  const FollowUpCalendarView({super.key});

  void _showScheduleDialog(BuildContext context, {bool isEdit = false}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'تعديل موعد المراجعة' : AppStringsAr.scheduleFollowUp),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => DropdownButtonFormField<int?>(
                    isExpanded: true,
                    initialValue: controller.selectedPet.value?.id,
                    decoration: const InputDecoration(labelText: 'اختر المريض'),
                    items: controller.pets.map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            '${p.name} (${p.ownerName ?? ""})',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        )).toList(),
                    onChanged: (id) {
                      if (id != null) {
                        controller.selectedPet.value = controller.pets.firstWhere((p) => p.id == id);
                      }
                    },
                  )),
              const SizedBox(height: 12),
              CustomTextField(
                label: AppStringsAr.followUpDate,
                hint: 'YYYY-MM-DD',
                controller: controller.scheduledDateController,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 3)),
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    controller.scheduledDateController.text = picked.toIso8601String().substring(0, 10);
                  }
                },
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'الوقت المحدد',
                hint: 'اختر الوقت',
                controller: controller.scheduledTimeController,
                readOnly: true,
                prefixIcon: const Icon(Icons.access_time),
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 10, minute: 0),
                  );
                  if (pickedTime != null) {
                    final hourStr = pickedTime.hourOfPeriod == 0 ? '12' : pickedTime.hourOfPeriod.toString();
                    final minStr = pickedTime.minute.toString().padLeft(2, '0');
                    final periodStr = pickedTime.period == DayPeriod.am ? 'ص' : 'م';
                    controller.scheduledTimeController.text = '$hourStr:$minStr $periodStr';
                  }
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: AppStringsAr.followUpReason,
                hint: 'مثال: فك غرز، جرعة تنشيطية، متابعة تحليل دم',
                controller: controller.reasonController,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'ملاحظات إضافية',
                hint: 'أي تعليمات للمربي قبل الحضور',
                controller: controller.notesController,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.clearForm();
              Navigator.of(ctx).pop();
            },
            child: const Text(AppStringsAr.cancel),
          ),
          ElevatedButton(
            onPressed: controller.scheduleFollowUp,
            child: Text(isEdit ? 'حفظ التعديل' : AppStringsAr.save),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, String petName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.critical),
            SizedBox(width: 8),
            Text('حذف الموعد'),
          ],
        ),
        content: Text('هل أنت متأكد من حذف موعد المراجعة الخاص بالمريض ($petName)؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStringsAr.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.critical, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.deleteFollowUp(id);
            },
            child: const Text(AppStringsAr.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStringsAr.followUps),
        actions: [
          IconButton(
            tooltip: AppStringsAr.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadFollowUps,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(AppStringsAr.scheduleFollowUp, style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          controller.clearForm();
          _showScheduleDialog(context, isEdit: false);
        },
      ),
      body: Column(
        children: [
          // Filter Tabs with Badges
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Obx(() => Row(
                  children: [
                    _buildTab(
                      label: 'اليوم (${controller.todayCount})',
                      value: 'today',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    _buildTab(
                      label: 'متأخرة (${controller.overdueCount})',
                      value: 'overdue',
                      color: AppColors.critical,
                    ),
                    const SizedBox(width: 6),
                    _buildTab(
                      label: 'القادمة (${controller.upcomingCount})',
                      value: 'upcoming',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    _buildTab(
                      label: 'الكل (${controller.allCount})',
                      value: 'all',
                      color: AppColors.accent,
                    ),
                  ],
                )),
          ),

          // Follow-Up Items List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.followUps.isEmpty) {
                return EmptyStateView(
                  icon: Icons.event_available,
                  title: 'لا توجد مراجعات في هذا القسم',
                  subtitle: 'يمكنك جدولة موعد مراجعة سريرية جديدة في أي وقت',
                  actionText: AppStringsAr.scheduleFollowUp,
                  onAction: () {
                    controller.clearForm();
                    _showScheduleDialog(context);
                  },
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.followUps.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = controller.followUps[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => Get.toNamed(AppRoutes.patientDetail, arguments: item.petId),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppColors.secondaryLight,
                                        child: const Icon(Icons.pets, size: 20, color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    '${item.petName ?? "المريض"} (${item.petSpecies ?? ""})',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primary),
                                              ],
                                            ),
                                            Text(
                                              'المالك: ${item.ownerName ?? "غير محدد"}',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  _buildStatusTag(item.statusDisplayArabic, item.isOverdue, item.isToday),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                                    onSelected: (action) {
                                      if (action == 'edit') {
                                        controller.initEdit(item);
                                        _showScheduleDialog(context, isEdit: true);
                                      } else if (action == 'delete') {
                                        _confirmDelete(context, item.id!, item.petName ?? 'المريض');
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18, color: AppColors.primary),
                                            SizedBox(width: 8),
                                            Text(AppStringsAr.edit),
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
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                item.scheduledDate,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (item.scheduledTime != null) ...[
                                const SizedBox(width: 12),
                                const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(item.scheduledTime!, style: const TextStyle(fontSize: 13)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'سبب المراجعة: ${item.reason}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkNeutral),
                          ),
                          if (item.notes != null && item.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'ملاحظات: ${item.notes}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Actions: One-Tap WhatsApp Reminder & Mark Done
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => controller.sendWhatsAppReminder(item),
                                icon: const Icon(Icons.chat, size: 16),
                                label: Text(
                                  item.reminderSent ? 'تم إرسال تذكير (إعادة)' : 'إرسال تذكير واتساب',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              Row(
                                children: [
                                  if (item.isPending)
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
                                      tooltip: 'إتمام المراجعة',
                                      onPressed: () => controller.markStatus(item.id!, 'completed'),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel_outlined, color: AppColors.critical),
                                    tooltip: 'إلغاء الموعد',
                                    onPressed: () => controller.markStatus(item.id!, 'cancelled'),
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
          ),
        ],
      ),
    );
  }

  Widget _buildTab({required String label, required String value, required Color color}) {
    final isSelected = controller.currentFilter.value == value;
    return Expanded(
      child: InkWell(
        onTap: () => controller.setFilter(value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color : AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppColors.darkNeutral,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTag(String label, bool isOverdue, bool isToday) {
    if (isOverdue) {
      return StatusChip(label: label, type: ChipStatusType.critical);
    } else if (isToday) {
      return StatusChip(label: label, type: ChipStatusType.warning);
    } else {
      return StatusChip(label: label, type: ChipStatusType.success);
    }
  }
}
