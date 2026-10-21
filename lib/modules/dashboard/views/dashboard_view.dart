import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/database/demo_data_seeder.dart';
import '../../../routes/app_routes.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../services/alerts_service.dart';
import '../widgets/alerts_bottom_sheet.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final alertsController = Get.find<AlertsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              AppStringsAr.appName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          // Notification Bell with Multi-Stage Alerts (12h, 6h, 1h)
          Obx(() {
            final count = alertsController.activeAlertsCount.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'مركز التنبيهات والتذكيرات',
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () => AlertsBottomSheet.show(context),
                ),
                if (count > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.critical,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
          IconButton(
            tooltip: AppStringsAr.lockApp,
            icon: const Icon(Icons.lock_outline, color: Colors.white),
            onPressed: authController.lockScreen,
          ),
        ],
      ),
      drawer: _buildDrawer(context, authController),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.loadDashboardData();
          await alertsController.refreshAlerts();
        },
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
              _buildKpiGrid(context, authController),
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
              _buildQuickActionButtons(context, authController),
              const SizedBox(height: 24),

              // Recent Consultations & Medical Alerts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'آخر الكشوفات السريرية',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNeutral,
                        ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('عرض جميع الكشوفات'),
                    onPressed: () {
                      if (!authController.checkPermission((u) => u.canPerformConsultation, 'سجل الكشوفات السريرية متاح للأطباء فقط')) return;
                      Get.toNamed(AppRoutes.consultations);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRecentVisitsList(context, authController),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

  Widget _buildKpiGrid(BuildContext context, AuthController authController) {
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
            onTap: () {
              if (!authController.checkPermission((u) => u.canPerformConsultation, 'سجل الكشوفات السريرية متاح للأطباء فقط')) return;
              Get.toNamed(AppRoutes.patientList);
            },
          ),
          _buildKpiCard(
            title: AppStringsAr.todaySurgeries,
            count: '${controller.todaySurgeries.value}',
            icon: Icons.healing,
            color: const Color(0xFF2A9D8F),
            bgColor: const Color(0xFFEAF8F6),
            onTap: () {
              if (!authController.checkPermission((u) => u.canPerformSurgeries, 'سجل العمليات الجراحية متاح للأطباء فقط')) return;
              Get.toNamed(AppRoutes.surgeries);
            },
          ),
          _buildKpiCard(
            title: AppStringsAr.pendingFollowUps,
            count: '${controller.pendingFollowUps.value}',
            icon: Icons.calendar_today,
            color: const Color(0xFFE76F51),
            bgColor: const Color(0xFFFFEFEA),
            onTap: () {
              if (!authController.checkPermission((u) => u.canManagePatientsAndAppointments, 'المراجعات والمواعيد متاحة للأطباء وموظف الاستقبال فقط')) return;
              Get.toNamed(AppRoutes.followUps);
            },
          ),
          _buildKpiCard(
            title: 'تنبيهات الصيدلية',
            count: '${controller.lowStockCount.value + controller.expiringMedsCount.value}',
            icon: Icons.medication_liquid,
            color: controller.expiringMedsCount.value > 0 ? AppColors.critical : AppColors.warning,
            bgColor: controller.expiringMedsCount.value > 0
                ? AppColors.criticalBackground
                : AppColors.warningBackground,
            onTap: () {
              if (!authController.checkPermission((u) => u.canModifyInventory, 'الصيدلية والمخزون متاح للطبيب الرئيسي وأمين المستودع فقط')) return;
              Get.toNamed(AppRoutes.inventoryList);
            },
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

  Widget _buildQuickActionButtons(BuildContext context, AuthController authController) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: AppStringsAr.newVisitAction,
                icon: Icons.add_circle_outline,
                color: AppColors.primary,
                onPressed: () {
                  if (!authController.checkPermission((u) => u.canPerformConsultation, 'تسجيل كشف سريري جديد متاح للأطباء فقط')) return;
                  Get.toNamed(AppRoutes.newConsultation);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                label: AppStringsAr.newPetAction,
                icon: Icons.person_add_alt_1_outlined,
                color: const Color(0xFF264653),
                onPressed: () {
                  if (!authController.checkPermission((u) => u.canManagePatientsAndAppointments, 'إضافة مريض جديد متاح للأطباء وموظف الاستقبال فقط')) return;
                  Get.toNamed(AppRoutes.addPatient);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'الصيدلية والمخزون',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF2A9D8F),
                onPressed: () {
                  if (!authController.checkPermission((u) => u.canModifyInventory, 'الصيدلية والمخزون متاح للطبيب الرئيسي وأمين المستودع فقط')) return;
                  Get.toNamed(AppRoutes.inventoryList);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                label: 'المراجعات والمواعيد',
                icon: Icons.event_note,
                color: const Color(0xFFE76F51),
                onPressed: () {
                  if (!authController.checkPermission((u) => u.canManagePatientsAndAppointments, 'المراجعات والمواعيد متاحة للأطباء وموظف الاستقبال فقط')) return;
                  Get.toNamed(AppRoutes.followUps);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: 'الإدارة المالية وكشوفات الحسابات',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF1D3557),
                onPressed: () {
                  if (!authController.checkPermission((u) => u.canAccessFinancials, 'الإدارة المالية متاحة للطبيب الرئيسي وموظف الاستقبال فقط')) return;
                  Get.toNamed(AppRoutes.financialDashboard);
                },
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
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        fixedSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildRecentVisitsList(BuildContext context, AuthController authController) {
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
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (!authController.checkPermission((u) => u.canPerformConsultation, 'تفاصيل الكشف السريري متاحة للأطباء فقط')) return;
                Get.toNamed(AppRoutes.consultationDetail, arguments: visit)?.then((_) => controller.loadDashboardData());
              },
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
                      label: '${visit.visitCost.toStringAsFixed(0)} ريال يمني',
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
            ),
          );
        },
      );
    });
  }

  Widget _buildDrawer(BuildContext context, AuthController authController) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Modern Rich Gradient Header
          _buildDrawerHeader(topPadding, authController),
          // Scrollable Categorized Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerSectionHeader('الرئيسية والعيادة'),
                _buildDrawerItem(
                  icon: Icons.dashboard_rounded,
                  title: AppStringsAr.dashboard,
                  isSelected: true,
                  onTap: () => Get.back(),
                ),
                _buildDrawerItem(
                  icon: Icons.storefront_rounded,
                  title: AppStringsAr.clinicSetupTitle,
                  onTap: () {
                    if (!authController.checkPermission((u) => u.isLeadDoctor, 'إعدادات وهوية العيادة مخصصة للطبيب الرئيسي فقط')) return;
                    Get.back();
                    Get.toNamed(AppRoutes.clinicSetup);
                  },
                ),

                _buildDrawerSectionHeader('الرعاية السريرية والجراحة'),
                _buildDrawerItem(
                  icon: Icons.assignment_rounded,
                  title: 'سجل الكشوفات السريرية',
                  onTap: () {
                    if (!authController.checkPermission((u) => u.canPerformConsultation, 'سجل الكشوفات السريرية متاح للأطباء فقط')) return;
                    Get.back();
                    Get.toNamed(AppRoutes.consultations);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.pets_rounded,
                  title: AppStringsAr.patients,
                  onTap: () {
                    if (!authController.checkPermission((u) => u.canManagePatientsAndAppointments, 'سجل المرضى متاح للأطباء وموظف الاستقبال فقط')) return;
                    Get.back();
                    Get.toNamed(AppRoutes.patientList);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people_alt_rounded,
                  title: 'دليل المربين والعملاء',
                  onTap: () {
                    if (!authController.checkPermission((u) => u.canManagePatientsAndAppointments, 'دليل المربين متاح للأطباء وموظف الاستقبال فقط')) return;
                    Get.back();
                    Get.toNamed(AppRoutes.owners);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_month_rounded,
                  title: AppStringsAr.followUps,
                  onTap: () {
                    if (!authController.checkPermission((u) => u.canManagePatientsAndAppointments, 'المواعيد والمراجعات متاحة للأطباء وموظف الاستقبال فقط')) return;
                    Get.back();
                    Get.toNamed(AppRoutes.followUps);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.healing_rounded,
                  title: AppStringsAr.surgeries,
                  onTap: () {
                    if (!authController.checkPermission((u) => u.canPerformSurgeries, 'سجل العمليات الجراحية متاح للأطباء فقط')) return;
                    Get.back();
                    Get.toNamed(AppRoutes.surgeries);
                  },
                ),

                _buildDrawerSectionHeader('الصيدلية والمالية'),
                _buildDrawerItem(
                  icon: Icons.medication_rounded,
                  title: AppStringsAr.pharmacy,
                  onTap: () {
                    if (!authController.checkPermission((u) => u.canModifyInventory, 'الصيدلية والمخزون متاح للطبيب الرئيسي وأمين المستودع فقط')) return;
                    Get.back();
                    Get.toNamed(AppRoutes.inventoryList);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'الإدارة المالية والحسابات',
                  onTap: () {
                    if (!authController.checkPermission((u) => u.canAccessFinancials, 'الإدارة المالية والحسابات متاحة للطبيب الرئيسي وموظف الاستقبال فقط')) return;
                    Get.back();
                    Get.toNamed(AppRoutes.financialDashboard);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.bar_chart_rounded,
                  title: 'التقارير الأسبوعية الشاملة',
                  onTap: () {
                    if (!authController.checkPermission((u) => u.canAccessFinancials, 'التقارير الشاملة متاحة للطبيب الرئيسي وموظف الاستقبال فقط')) return;
                    Get.back();
                    Get.toNamed(AppRoutes.weeklyReports);
                  },
                ),

                _buildDrawerSectionHeader('الإدارة والأمان'),
                _buildDrawerItem(
                  icon: Icons.notifications_active_rounded,
                  title: 'مركز التنبيهات والتذكيرات',
                  onTap: () {
                    Get.back();
                    AlertsBottomSheet.show(context);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.admin_panel_settings_rounded,
                  title: AppStringsAr.usersManagement,
                  onTap: () {
                    if (!authController.checkPermission((u) => u.canManageUsers, 'إدارة الموظفين والصلاحيات متاحة للطبيب الرئيسي فقط')) return;
                    Get.back();
                    Get.toNamed(AppRoutes.usersManagement);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.storage_rounded,
                  title: 'النسخ الاحتياطي واستعادة البيانات',
                  subtitle: 'حفظ واسترجاع على فلاش ميموري',
                  onTap: () {
                    if (!authController.checkPermission((u) => u.canManageBackups, 'النسخ الاحتياطي واستعادة البيانات متاح للطبيب الرئيسي فقط')) return;
                    Get.back();
                    Get.toNamed(AppRoutes.databaseBackup);
                  },
                ),
                if (DemoConfig.isDemoMode) ...[
                  _buildDrawerItem(
                    icon: Icons.restart_alt_rounded,
                    title: 'إعادة تهيئة بيانات العرض التجريبي',
                    subtitle: 'استعادة البيانات السريرية النموذجية',
                    iconColor: Colors.teal,
                    onTap: () async {
                      if (!authController.checkPermission((u) => u.isLeadDoctor, 'إعادة تهيئة بيانات العرض متاح للطبيب الرئيسي فقط')) return;
                      Get.back();
                      await DemoDataSeeder.resetDemoData();
                      controller.loadDashboardData();
                    },
                  ),
                ],
              ],
            ),
          ),
          // Footer Quick Actions (Lock Screen & Logout)
          const Divider(height: 1),
          _buildDrawerFooter(bottomPadding, authController),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(double topPadding, AuthController authController) {
    return Container(
      padding: EdgeInsets.only(
        top: topPadding > 0 ? topPadding + 14 : 36,
        bottom: 18,
        right: 18,
        left: 18,
      ),
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Obx(() {
        final clinic = authController.clinicInfo.value;
        final clinicName = clinic?.clinicName.isNotEmpty == true
            ? clinic!.clinicName
            : AppStringsAr.appName;
        final docName = clinic?.doctorName.isNotEmpty == true
            ? clinic!.doctorName
            : (authController.currentUser.value?.fullName ?? 'طبيب بيطري');
        final logoPath = authController.clinicLogoPath.value ?? clinic?.logoPath;
        final roleBadge = authController.currentUser.value?.roleDisplayArabic ?? 'طبيب بيطري';

        final hasCustomLogo = logoPath != null &&
            logoPath.isNotEmpty &&
            File(logoPath).existsSync();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasCustomLogo
                        ? Image.file(
                            File(logoPath),
                            fit: BoxFit.cover,
                            width: 54,
                            height: 54,
                          )
                        : Container(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            child: const Icon(
                              Icons.pets_rounded,
                              color: AppColors.primary,
                              size: 30,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clinicName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.person_pin_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              docName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shield_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    roleBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDrawerSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 18, left: 18, top: 14, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    bool isSelected = false,
  }) {
    final effectiveBg = isSelected
        ? AppColors.primary.withValues(alpha: 0.08)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1.5),
      child: Material(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.primary).withValues(alpha: isSelected ? 0.16 : 0.09),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: iconColor ?? AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerFooter(double bottomPadding, AuthController authController) {
    return Container(
      color: Colors.grey.shade50,
      padding: EdgeInsets.only(
        top: 10,
        bottom: bottomPadding > 0 ? bottomPadding + 10 : 16,
        left: 12,
        right: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: Colors.grey.shade300),
                foregroundColor: AppColors.textSecondary,
              ),
              icon: const Icon(Icons.lock_outline_rounded, size: 16),
              label: const Text(
                'قفل الشاشة',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Get.back();
                authController.lockScreen();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(color: AppColors.critical.withValues(alpha: 0.3)),
                foregroundColor: AppColors.critical,
                backgroundColor: AppColors.critical.withValues(alpha: 0.05),
              ),
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text(
                AppStringsAr.logout,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Get.back();
                authController.logout();
              },
            ),
          ),
        ],
      ),
    );
  }

}
