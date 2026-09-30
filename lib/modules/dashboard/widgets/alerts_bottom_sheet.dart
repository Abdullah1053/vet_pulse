import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../services/alerts_service.dart';

class AlertsBottomSheet extends StatefulWidget {
  const AlertsBottomSheet({super.key});

  static void show(BuildContext context) {
    final alertsCtrl = Get.find<AlertsController>();
    alertsCtrl.refreshAlerts();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AlertsBottomSheet(),
    );
  }

  @override
  State<AlertsBottomSheet> createState() => _AlertsBottomSheetState();
}

class _AlertsBottomSheetState extends State<AlertsBottomSheet> {
  String selectedFilter = 'all'; // all, 1h, 6h, 12h

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AlertsController>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مركز التنبيهات والتذكيرات المسبقة',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'التذكير الآلي قبل المواعيد والعمليات (12س / 6س / 1س)',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
          ),
          const Divider(height: 1),
          // Notification Permission Banner
          Obx(() {
            final notifService = Get.find<NotificationService>();
            if (notifService.hasNotificationPermission.value) {
              return const SizedBox.shrink();
            }
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_paused_outlined, color: Colors.amber.shade800, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'إشعارات الهاتف غير مفعلة. اضغط لتفعيل وصول التنبيهات المباشرة لهاتفك',
                      style: TextStyle(fontSize: 11, color: Colors.brown.shade800, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: () => notifService.requestNotificationPermission(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('تفعيل الآن', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }),

          // Urgency Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterTab('all', 'الكل'),
                  const SizedBox(width: 8),
                  _buildFilterTab('1h', 'أقل من ساعة (حرج ⚠️)'),
                  const SizedBox(width: 8),
                  _buildFilterTab('6h', 'خلال 6 ساعات'),
                  const SizedBox(width: 8),
                  _buildFilterTab('12h', 'خلال 12 ساعة'),
                ],
              ),
            ),
          ),

          // Alerts List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              var list = controller.alerts;
              if (selectedFilter == '1h') {
                list = list.where((a) => a.urgency == AlertUrgency.oneHour).toList().obs;
              } else if (selectedFilter == '6h') {
                list = list.where((a) => a.urgency == AlertUrgency.sixHours).toList().obs;
              } else if (selectedFilter == '12h') {
                list = list.where((a) => a.urgency == AlertUrgency.twelveHours).toList().obs;
              }

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: AppColors.success.withValues(alpha: 0.7)),
                      const SizedBox(height: 12),
                      const Text(
                        'لا توجد تنبيهات عاجلة في هذا النطاق',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'جميع المواعيد والعمليات مجدولة ومستقرة',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = list[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: item.urgencyColor.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: item.urgencyColor.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.urgencyColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.urgencyLabelArabic,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: item.urgencyColor,
                                ),
                              ),
                            ),
                            Text(
                              item.remainingTextArabic,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: item.urgencyColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'المريض: ${item.petName} (${item.petSpecies}) • المالك: ${item.ownerName}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => controller.sendWhatsAppAlert(item),
                                icon: const Icon(Icons.chat, size: 16),
                                label: const Text('إرسال تذكير واتساب', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),
                            if (item.ownerPhone != null && item.ownerPhone!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.call, color: AppColors.success, size: 20),
                                tooltip: 'اتصال هاتفي',
                                onPressed: () => controller.callOwner(item.ownerPhone!),
                              ),
                            ],
                          ],
                        ),
                      ],
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

  Widget _buildFilterTab(String key, String label) {
    final isSelected = selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => selectedFilter = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.darkNeutral,
          ),
        ),
      ),
    );
  }
}
