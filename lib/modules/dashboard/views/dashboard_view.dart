import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../routes/app_routes.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pets, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              AppStringsAr.appName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: AppStringsAr.lockApp,
            icon: const Icon(Icons.lock_outline, color: AppColors.darkNeutral),
            onPressed: authController.lockScreen,
          ),
          IconButton(
            tooltip: AppStringsAr.refresh,
            icon: const Icon(Icons.refresh, color: AppColors.darkNeutral),
            onPressed: controller.loadDashboardData,
          ),
        ],
      ),
      drawer: _buildDrawer(context, authController),
      body: RefreshIndicator(
        onRefresh: controller.loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clinic & Doctor Welcome Card
              _buildDoctorHeader(context, authController),
              const SizedBox(height: 16),

              // KPI Metric Cards
              _buildKpiGrid(context),
              const SizedBox(height: 20),

              // Quick Clinical Actions
              Text(
                AppStringsAr.quickActions,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNeutral,
                    ),
              ),
              const SizedBox(height: 12),
              _buildQuickActionButtons(context),
              const SizedBox(height: 24),

              // Recent Consultations & Medical Alerts
              Text(
                'آخر الكشوفات السريرية',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNeutral,
                    ),
              ),
              const SizedBox(height: 12),
              _buildRecentVisitsList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorHeader(BuildContext context, AuthController authController) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medical_services_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                      authController.clinicInfo.value?.clinicName ?? 'عيادة بيطرية متقدمة',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                const SizedBox(height: 4),
                Obx(() {
                  final user = authController.currentUser.value;
                  return Text(
                    user != null
                        ? '${user.fullName} (${user.roleDisplayArabic})'
                        : (authController.clinicInfo.value?.doctorName ?? 'مرحباً دكتور'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                  );
                }),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'محلي بالكامل',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          _buildKpiCard(
            title: AppStringsAr.todayVisits,
            count: '${controller.todayVisits.value}',
            icon: Icons.medical_services_outlined,
            color: AppColors.primary,
            bgColor: AppColors.secondaryLight,
            onTap: () => Get.toNamed(AppRoutes.patientList),
          ),
          _buildKpiCard(
            title: AppStringsAr.todaySurgeries,
            count: '${controller.todaySurgeries.value}',
            icon: Icons.healing,
            color: const Color(0xFF2A9D8F),
            bgColor: const Color(0xFFEAF8F6),
            onTap: () => Get.toNamed(AppRoutes.surgeries),
          ),
          _buildKpiCard(
            title: AppStringsAr.pendingFollowUps,
            count: '${controller.pendingFollowUps.value}',
            icon: Icons.calendar_today,
            color: const Color(0xFFE76F51),
            bgColor: const Color(0xFFFFEFEA),
            onTap: () => Get.toNamed(AppRoutes.followUps),
          ),
          _buildKpiCard(
            title: 'تنبيهات الصيدلية',
            count: '${controller.lowStockCount.value + controller.expiringMedsCount.value}',
            icon: Icons.medication_liquid,
            color: controller.expiringMedsCount.value > 0 ? AppColors.critical : AppColors.warning,
            bgColor: controller.expiringMedsCount.value > 0
                ? AppColors.criticalBackground
                : AppColors.warningBackground,
            onTap: () => Get.toNamed(AppRoutes.inventoryList),
          ),
        ],
      );
    });
  }

  Widget _buildKpiCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.darkNeutral,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: AppStringsAr.newVisitAction,
                icon: Icons.add_circle_outline,
                color: AppColors.primary,
                onPressed: () => Get.toNamed(AppRoutes.newConsultation),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                label: AppStringsAr.newPetAction,
                icon: Icons.person_add_alt_1_outlined,
                color: const Color(0xFF264653),
                onPressed: () => Get.toNamed(AppRoutes.addPatient),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: AppStringsAr.pharmacy,
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF2A9D8F),
                onPressed: () => Get.toNamed(AppRoutes.inventoryList),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                label: AppStringsAr.followUps,
                icon: Icons.event_note,
                color: const Color(0xFFE76F51),
                onPressed: () => Get.toNamed(AppRoutes.followUps),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildRecentVisitsList(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SizedBox.shrink();
      }

      if (controller.recentConsultations.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.notes_outlined, size: 36, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'لا توجد كشوفات مسجلة مؤخراً',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.recentConsultations.length,
        itemBuilder: (context, index) {
          final visit = controller.recentConsultations[index];
          return Card(
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.secondaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets, color: AppColors.primary, size: 22),
              ),
              title: Text(
                '${visit.petName ?? "مريض"} (${visit.petSpecies ?? ""})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                'التشخيص: ${visit.diagnosis}\nالمالك: ${visit.ownerName ?? "غير محدد"}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(
                    label: '${visit.visitCost.toStringAsFixed(0)} ${AppStringsAr.currencyShort}',
                    type: ChipStatusType.success,
                    fontSize: 10,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    visit.visitDate.substring(0, 10),
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildDrawer(BuildContext context, AuthController authController) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, right: 20, left: 20),
            width: double.infinity,
            color: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.pets, color: Colors.white, size: 40),
                const SizedBox(height: 12),
                Text(
                  AppStringsAr.appName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  authController.clinicInfo.value?.clinicName ?? '',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined, color: AppColors.primary),
            title: const Text(AppStringsAr.dashboard),
            onTap: () => Get.back(),
          ),
          ListTile(
            leading: const Icon(Icons.pets_outlined, color: AppColors.primary),
            title: const Text(AppStringsAr.patients),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.patientList);
            },
          ),
          ListTile(
            leading: const Icon(Icons.medication_outlined, color: AppColors.primary),
            title: const Text(AppStringsAr.pharmacy),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.inventoryList);
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined, color: AppColors.primary),
            title: const Text(AppStringsAr.followUps),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.followUps);
            },
          ),
          ListTile(
            leading: const Icon(Icons.healing_outlined, color: AppColors.primary),
            title: const Text(AppStringsAr.surgeries),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.surgeries);
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_outlined, color: AppColors.primary),
            title: const Text(AppStringsAr.usersManagement),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.usersManagement);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: AppColors.primary),
            title: const Text(AppStringsAr.clinicSetupTitle),
            onTap: () {
              Get.back();
              Get.toNamed(AppRoutes.clinicSetup);
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.critical),
            title: const Text(AppStringsAr.logout, style: TextStyle(color: AppColors.critical)),
            onTap: authController.logout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
