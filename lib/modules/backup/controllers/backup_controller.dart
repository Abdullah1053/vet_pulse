import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/backup_log_model.dart';
import '../../../data/repositories/backup_repository.dart';
import '../../../data/services/database_backup_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../financials/controllers/financial_controller.dart';

class BackupController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final BackupRepository backupRepository;
  final DatabaseBackupService backupService;

  BackupController({
    BackupRepository? backupRepository,
    DatabaseBackupService? backupService,
  })  : backupRepository = backupRepository ?? Get.find<BackupRepository>(),
        backupService = backupService ?? DatabaseBackupService.instance;

  late TabController tabController;

  final activeDbInfo = Rxn<DatabaseBackupInfo>();
  final internalBackups = <DatabaseBackupInfo>[].obs;
  final backupLogs = <BackupLogModel>[].obs;
  final config = BackupConfig().obs;

  final isLoading = false.obs;
  final statusMessage = ''.obs;
  final selectedTabIndex = 0.obs;

  String get currentUserRole {
    if (Get.isRegistered<AuthController>()) {
      return Get.find<AuthController>().currentUser.value?.role ??
          'lead_doctor';
    }
    return 'lead_doctor';
  }

  bool get canRestore =>
      currentUserRole == 'lead_doctor' || currentUserRole == 'admin';

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(_onTabChanged);
    loadAllData();
  }

  void _onTabChanged() {
    if (!tabController.indexIsChanging) {
      selectedTabIndex.value = tabController.index;
    }
  }

  void setTabIndex(int index) {
    tabController.animateTo(index);
    selectedTabIndex.value = index;
  }

  @override
  void onClose() {
    tabController.removeListener(_onTabChanged);
    tabController.dispose();
    super.onClose();
  }

  Future<void> loadAllData() async {
    final active = await backupService.getDatabaseInfo();
    final internal = await backupService.listInternalBackups();
    final logs = await backupRepository.getBackupLogs();
    final currentConfig = await backupService.getBackupConfig();

    activeDbInfo.value = active;
    internalBackups.assignAll(internal);
    backupLogs.assignAll(logs);
    config.value = currentConfig;
  }

  Future<void> createInternalBackup() async {
    isLoading.value = true;
    statusMessage.value = 'جاري إنشاء وحفظ النسخة الاحتياطية الداخلية...';

    try {
      final log = await backupService.createInternalBackup();
      Get.snackbar(
        'تم إنشاء النسخة الاحتياطية بنجاح ✅',
        'تم حفظ النسخة: ${log.backupName} (${log.formattedSize})',
        backgroundColor: AppColors.success.withValues(alpha: 0.15),
        colorText: AppColors.success,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'خطأ أثناء النسخ الداخلي',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: AppColors.criticalBackground,
        colorText: AppColors.critical,
      );
    } finally {
      isLoading.value = false;
      statusMessage.value = '';
      await loadAllData();
    }
  }

  Future<void> exportExternalBackup() async {
    isLoading.value = true;
    statusMessage.value = 'جاري تصدير النسخة الاحتياطية إلى الوجهة الخارجية...';

    try {
      final log = await backupService.exportExternalBackup();
      Get.snackbar(
        'تم التصدير بنجاح ✅',
        'تم حفظ النسخة الخارجية في:\n${log.filePath}',
        backgroundColor: AppColors.success.withValues(alpha: 0.15),
        colorText: AppColors.success,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      Get.snackbar(
        'خطأ أثناء التصدير الخارجي',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: AppColors.criticalBackground,
        colorText: AppColors.critical,
      );
    } finally {
      isLoading.value = false;
      statusMessage.value = '';
      await loadAllData();
    }
  }

  Future<void> shareBackup() async {
    isLoading.value = true;
    statusMessage.value = 'جاري تجهيز النسخة الاحتياطية للمشاركة...';

    try {
      await backupService.shareBackupViaSystem();
    } catch (e) {
      Get.snackbar(
        'خطأ أثناء المشاركة',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: AppColors.criticalBackground,
        colorText: AppColors.critical,
      );
    } finally {
      isLoading.value = false;
      statusMessage.value = '';
    }
  }

  Future<void> pickExternalFolder() async {
    try {
      final selectedDirectory = await FilePickerPlatform.instance
          .getDirectoryPath(
            dialogTitle: 'اختر مجلد الفلاش ميموري أو القرص الخارجي لحفظ النسخ',
          );
      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        final newConfig = BackupConfig(
          externalDestinationPath: selectedDirectory,
          autoBackupEnabled: config.value.autoBackupEnabled,
          autoBackupFrequency: config.value.autoBackupFrequency,
          lastAutoBackupDate: config.value.lastAutoBackupDate,
        );
        await backupService.saveBackupConfig(newConfig);
        config.value = newConfig;
        Get.snackbar(
          'تم تحديث الوجهة الخارجية ✅',
          'تم تعيين المسار: $selectedDirectory',
          backgroundColor: AppColors.success.withValues(alpha: 0.15),
          colorText: AppColors.success,
        );
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر تحديد المجلد: $e');
    }
  }

  Future<void> updateAutoBackupEnabled(bool enabled) async {
    final newConfig = BackupConfig(
      externalDestinationPath: config.value.externalDestinationPath,
      autoBackupEnabled: enabled,
      autoBackupFrequency: config.value.autoBackupFrequency,
      lastAutoBackupDate: config.value.lastAutoBackupDate,
    );
    await backupService.saveBackupConfig(newConfig);
    config.value = newConfig;
  }

  Future<void> updateAutoBackupFrequency(String frequency) async {
    final newConfig = BackupConfig(
      externalDestinationPath: config.value.externalDestinationPath,
      autoBackupEnabled: config.value.autoBackupEnabled,
      autoBackupFrequency: frequency,
      lastAutoBackupDate: config.value.lastAutoBackupDate,
    );
    await backupService.saveBackupConfig(newConfig);
    config.value = newConfig;
  }

  Future<void> confirmAndRestore(String? filePath) async {
    if (!canRestore) {
      Get.snackbar(
        'صلاحية غير كافية ⛔',
        'استعادة النسخ الاحتياطية تتطلب صلاحيات الطبيب المسؤول (Lead Doctor) لحماية البيانات.',
        backgroundColor: AppColors.criticalBackground,
        colorText: AppColors.critical,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text(
              'تأكيد استعادة النسخة الاحتياطية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'تنبيه أمني هام:\nسيتم استبدال البيانات الحالية بالكامل بالبيانات المستعادة من ملف النسخة الاحتياطية.\n\nهل أنت متأكد من رغبتك بالاستعادة؟',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('نعم، استعادة البيانات الآن'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    isLoading.value = true;
    statusMessage.value = 'جاري فحص الملف واستعادة قاعدة البيانات...';

    try {
      String msg;
      if (filePath != null) {
        msg = await backupService.restoreFromFile(
          filePath,
          userRole: currentUserRole,
        );
      } else {
        msg = await backupService.restoreFromBackupPicker(
          userRole: currentUserRole,
        );
      }

      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().loadDashboardData();
      }
      if (Get.isRegistered<FinancialController>()) {
        Get.find<FinancialController>().loadFinancialData();
      }

      Get.snackbar(
        'تمت الاستعادة بنجاح ✅',
        msg,
        backgroundColor: AppColors.success.withValues(alpha: 0.15),
        colorText: AppColors.success,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar(
        'فشلت الاستعادة',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: AppColors.criticalBackground,
        colorText: AppColors.critical,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
      statusMessage.value = '';
      await loadAllData();
    }
  }

  Future<void> confirmAndDelete(String filePath) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'تأكيد حذف النسخة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل تريد بالتأكيد حذف ملف النسخة الاحتياطية المحدد من الذاكرة الداخلية؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await backupService.deleteInternalBackup(filePath);
      await loadAllData();
    }
  }
}
