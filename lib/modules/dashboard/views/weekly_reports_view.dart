import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../controllers/weekly_reports_controller.dart';

class WeeklyReportsView extends StatelessWidget {
  const WeeklyReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(WeeklyReportsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقرير الأسبوعي الشامل للعيادة'),
        actions: [
          IconButton(
            tooltip: AppStringsAr.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadWeeklyReport,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Week Navigator
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 18),
                        tooltip: 'الأسبوع السابق',
                        onPressed: controller.previousWeek,
                      ),
                      Column(
                        children: [
                          Text(
                            controller.weekOffset.value == 0
                                ? 'الأسبوع الحالي'
                                : 'قبل ${controller.weekOffset.value} أسبوع',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            controller.weekRangeText.value,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          size: 18,
                          color: controller.weekOffset.value == 0 ? Colors.grey.shade400 : AppColors.darkNeutral,
                        ),
                        tooltip: 'الأسبوع اللاحق',
                        onPressed: controller.weekOffset.value == 0 ? null : controller.nextWeek,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // KPI Summary 2x2 Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildKpiCard(
                    title: 'الكشوفات السريرية',
                    value: '${controller.totalConsultations.value}',
                    subtitle: 'زيارة وفحص',
                    icon: Icons.assignment_turned_in_outlined,
                    color: AppColors.primary,
                    bgColor: AppColors.primaryLight.withValues(alpha: 0.15),
                  ),
                  _buildKpiCard(
                    title: 'مرضى جدد',
                    value: '${controller.newPatients.value}',
                    subtitle: 'ملف حيوان أليف جديد',
                    icon: Icons.pets,
                    color: const Color(0xFF264653),
                    bgColor: const Color(0xFF264653).withValues(alpha: 0.12),
                  ),
                  _buildKpiCard(
                    title: 'العمليات الجراحية',
                    value: '${controller.totalSurgeries.value}',
                    subtitle: 'عملية مسجلة',
                    icon: Icons.healing,
                    color: const Color(0xFFE76F51),
                    bgColor: const Color(0xFFE76F51).withValues(alpha: 0.12),
                  ),
                  _buildKpiCard(
                    title: 'إجمالي الإيرادات',
                    value: controller.totalRevenue.value.toStringAsFixed(0),
                    subtitle: 'ريال يمني',
                    icon: Icons.payments_outlined,
                    color: AppColors.success,
                    bgColor: AppColors.successBackground,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Section: Top Diagnoses
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.coronavirus_outlined, size: 20, color: AppColors.critical),
                          const SizedBox(width: 8),
                          const Text(
                            'أكثر الحالات والتشخيصات شيوعاً هذا الأسبوع',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (controller.topDiagnoses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('لا توجد بيانات كشوفات لهذا الأسبوع', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        )
                      else
                        ...controller.topDiagnoses.map((diag) {
                          final count = diag['count'] as int;
                          final total = controller.totalConsultations.value;
                          final pct = total > 0 ? (count / total) : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(diag['diagnosis'] as String? ?? 'عام', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    Text('$count حالة (${(pct * 100).toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: Colors.grey.shade200,
                                  color: AppColors.primary,
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Section: Most Administered Clinic Injections
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.vaccines, size: 20, color: AppColors.accent),
                          const SizedBox(width: 8),
                          const Text(
                            'أكثر الأدوية والإبر صرفاً من العيادة',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (controller.topClinicMedicines.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('لم يتم صرف إبر أو أدوية من العيادة في هذا الأسبوع', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        )
                      else
                        ...controller.topClinicMedicines.map((med) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    med['med_name'] as String? ?? 'دواء',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    '${med['total_qty']} جرعة / حقنة',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.accent),
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Section: Daily Activity Table
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_view_week, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'سجل النشاط اليومي خلال الأسبوع',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (controller.dailyActivity.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('لا توجد حركة مسجلة لهذا الأسبوع', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        )
                      else
                        Table(
                          border: TableBorder.all(color: AppColors.border, width: 0.8),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: Colors.grey.shade100),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('عدد الكشوفات', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('الإيراد (ريال يمني)', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                            ...controller.dailyActivity.map((day) => TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(day['day_date'] as String? ?? '', style: const TextStyle(fontSize: 12)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('${day['visits_count']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('${(day['day_revenue'] as num?)?.toInt() ?? 0}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                                    ),
                                  ],
                                )),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18),
              ),
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
