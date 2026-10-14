import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/backup_log_model.dart';
import '../../../data/services/database_backup_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../financials/controllers/financial_controller.dart';

class DatabaseBackupView extends StatefulWidget {
  const DatabaseBackupView({super.key});

  @override
  State<DatabaseBackupView> createState() => _DatabaseBackupViewState();
}

class _DatabaseBackupViewState extends State<DatabaseBackupView>
    with SingleTickerProviderStateMixin {
  final DatabaseBackupService _backupService = DatabaseBackupService.instance;
  late TabController _tabController;

  DatabaseBackupInfo? _activeDbInfo;
  List<DatabaseBackupInfo> _internalBackups = [];
  List<BackupLogModel> _backupLogs = [];
  BackupConfig _config = BackupConfig();

  bool _isLoading = false;
  String _statusMessage = '';

  String get _currentUserRole {
    if (Get.isRegistered<AuthController>()) {
      return Get.find<AuthController>().currentUser.value?.role ??
          'lead_doctor';
    }
    return 'lead_doctor';
  }

  bool get _canRestore =>
      _currentUserRole == 'lead_doctor' || _currentUserRole == 'admin';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final active = await _backupService.getDatabaseInfo();
    final internal = await _backupService.listInternalBackups();
    final logs = await _backupService.getBackupLogs();
    final config = await _backupService.getBackupConfig();

    if (mounted) {
      setState(() {
        _activeDbInfo = active;
        _internalBackups = internal;
        _backupLogs = logs;
        _config = config;
      });
    }
  }

  // --- ACTIONS ---

  Future<void> _createInternalBackup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري إنشاء وحفظ النسخة الاحتياطية الداخلية...';
    });

    try {
      final log = await _backupService.createInternalBackup();
      if (!mounted) return;
      Get.snackbar(
        'تم إنشاء النسخة الاحتياطية بنجاح ✅',
        'تم حفظ النسخة: ${log.backupName} (${log.formattedSize})',
        backgroundColor: AppColors.success.withValues(alpha: 0.15),
        colorText: AppColors.success,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'خطأ أثناء النسخ الداخلي',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: AppColors.criticalBackground,
        colorText: AppColors.critical,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });
        _loadAllData();
      }
    }
  }

  Future<void> _exportExternalBackup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري تصدير النسخة الاحتياطية إلى الوجهة الخارجية...';
    });

    try {
      final log = await _backupService.exportExternalBackup();
      if (!mounted) return;
      Get.snackbar(
        'تم التصدير بنجاح ✅',
        'تم حفظ النسخة الخارجية في:\n${log.filePath}',
        backgroundColor: AppColors.success.withValues(alpha: 0.15),
        colorText: AppColors.success,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'خطأ أثناء التصدير الخارجي',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: AppColors.criticalBackground,
        colorText: AppColors.critical,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });
        _loadAllData();
      }
    }
  }

  Future<void> _shareBackup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري تجهيز النسخة الاحتياطية للمشاركة...';
    });

    try {
      await _backupService.shareBackupViaSystem();
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'خطأ أثناء المشاركة',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: AppColors.criticalBackground,
        colorText: AppColors.critical,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });
      }
    }
  }

  Future<void> _pickExternalFolder() async {
    try {
      final selectedDirectory = await FilePickerPlatform.instance
          .getDirectoryPath(
            dialogTitle: 'اختر مجلد الفلاش ميموري أو القرص الخارجي لحفظ النسخ',
          );
      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        final newConfig = BackupConfig(
          externalDestinationPath: selectedDirectory,
          autoBackupEnabled: _config.autoBackupEnabled,
          autoBackupFrequency: _config.autoBackupFrequency,
          lastAutoBackupDate: _config.lastAutoBackupDate,
        );
        await _backupService.saveBackupConfig(newConfig);
        setState(() => _config = newConfig);
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

  Future<void> _restoreBackup(String? filePath) async {
    if (!_canRestore) {
      Get.snackbar(
        'صلاحية غير كافية ⛔',
        'استعادة النسخ الاحتياطية تتطلب صلاحيات الطبيب المسؤول (Lead Doctor) لحماية البيانات.',
        backgroundColor: AppColors.criticalBackground,
        colorText: AppColors.critical,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('نعم، استعادة البيانات الآن'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري فحص الملف واستعادة قاعدة البيانات...';
    });

    try {
      String msg;
      if (filePath != null) {
        msg = await _backupService.restoreFromFile(
          filePath,
          userRole: _currentUserRole,
        );
      } else {
        msg = await _backupService.restoreFromBackupPicker(
          userRole: _currentUserRole,
        );
      }

      if (!mounted) return;

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
      if (!mounted) return;
      Get.snackbar(
        'فشلت الاستعادة',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: AppColors.criticalBackground,
        colorText: AppColors.critical,
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });
        _loadAllData();
      }
    }
  }

  Future<void> _deleteInternalBackup(String filePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _backupService.deleteInternalBackup(filePath);
      _loadAllData();
    }
  }

  // --- BUILD UI ---

  @override
  Widget build(BuildContext context) {
    final tabItems = const [
      (icon: Icons.storage_rounded, title: 'نسخ داخلي'),
      (icon: Icons.usb_rounded, title: 'نسخ خارجي'),
      (icon: Icons.history_rounded, title: 'سجل العمليات'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'النسخ والاستعادة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadAllData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: Container(
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: AppColors.primary,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: List.generate(tabItems.length, (index) {
                  final isSelected = _tabController.index == index;
                  final item = tabItems[index];

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _tabController.animateTo(index);
                        setState(() {});
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: 16,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white.withValues(alpha: 0.95),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              // Loading Progress Bar
              if (_isLoading) ...[
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Active DB Status Banner
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: _buildActiveDbCard(),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInternalTab(),
                    _buildExternalTab(),
                    _buildLogsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ACTIVE DB CARD ---
  Widget _buildActiveDbCard() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.dns_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: 'قاعدة البيانات النشطة: ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      children: [
                        TextSpan(
                          text: _activeDbInfo?.fileName ?? 'vet_pulse.db',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'الحجم الحالي: ${_activeDbInfo?.formattedSize ?? "جاري الحساب..."} | عدد النسخ المحلية: ${_internalBackups.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _canRestore
                    ? AppColors.success.withValues(alpha: 0.15)
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _canRestore
                      ? AppColors.success
                      : Colors.orange.shade400,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _canRestore ? Icons.admin_panel_settings : Icons.lock_clock,
                    size: 14,
                    color: _canRestore
                        ? AppColors.success
                        : Colors.orange.shade800,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _canRestore ? 'صلاحيات استعادة كاملة' : 'عرض فقط',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _canRestore
                          ? AppColors.success
                          : Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: INTERNAL BACKUP ---
  Widget _buildInternalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Create Backup CTA Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            color: Colors.blue.shade50.withValues(alpha: 0.4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_to_photos_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إنشاء نسخة احتياطية جديدة',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'يتم حفظ النسخة داخل مجلد التطبيق المحلي المشفر والمخصص مع ختم زمني دقيق',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createInternalBackup,
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text(
                        'إنشاء نسخة احتياطية محلية الآن',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Internal Backups List Header
          Row(
            children: [
              Text(
                'النسخ المتوفرة (${_internalBackups.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(width: 8),
              if (_internalBackups.isNotEmpty)
                Expanded(
                  child: Text(
                    'المسار: ${_internalBackups.first.shortDirectoryPath}',
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (_internalBackups.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 40,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'لا توجد نسخ احتياطية داخلية محفوظة بعد',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNeutral,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'اضغط على زر "إنشاء نسخة احتياطية محلية الآن" بالأعلى لبدء أول نسخة',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _internalBackups.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final b = _internalBackups[index];
                return _buildBackupItemCard(b);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackupItemCard(DatabaseBackupInfo b) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_zip_rounded,
                color: Colors.blue.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${b.formattedDate} | الحجم: ${b.formattedSize}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: _canRestore
                      ? 'استعادة هذه النسخة'
                      : 'تتطلب صلاحية Lead Doctor',
                  icon: Icon(
                    Icons.restore_page_rounded,
                    color: _canRestore ? Colors.orange.shade800 : Colors.grey,
                    size: 20,
                  ),
                  onPressed: _canRestore && !_isLoading
                      ? () => _restoreBackup(b.path)
                      : null,
                ),
                IconButton(
                  tooltip: 'حذف من الجهاز',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.critical,
                    size: 20,
                  ),
                  onPressed: !_isLoading
                      ? () => _deleteInternalBackup(b.path)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: EXTERNAL BACKUP ---
  Widget _buildExternalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Export CTA Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            color: Colors.teal.shade50.withValues(alpha: 0.35),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.usb_rounded,
                          color: Colors.teal.shade800,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تصدير لقناة خارجية / فلاش ميموري',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'تصدير نسخة كاملة لقاعدة البيانات وحفظها على قرص خارجي، فلاش USB، أو مجلد سحابي',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _exportExternalBackup,
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text(
                            'تصدير نسخة احتياطية خارجية',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _shareBackup,
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('مشاركة'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Restore from File CTA
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.file_open_rounded,
                      color: Colors.orange.shade800,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'استعادة من ملف خارجي (.db)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'اختر ملف نسخة احتياطية من فلاش ميموري أو مجلد خارجي لاستعادته',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _canRestore && !_isLoading
                        ? () => _restoreBackup(null)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('اختيار ملف'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // External Config & Auto Schedule Card
          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'إعدادات الوجهة الخارجية والجدولة التلقائية',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Destination Folder
                  const Text(
                    'مجلد الوجهة الافتراضية (الفلاش ميموري أو القرص الخارجي):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _config.externalDestinationPath ??
                                'لم يتم تعيين وجهة افتراضية بعد (سيتم طلبها عند التصدير)',
                            style: TextStyle(
                              fontSize: 11,
                              color: _config.externalDestinationPath != null
                                  ? AppColors.darkNeutral
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _pickExternalFolder,
                          child: const Text('تغيير المجلد'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Auto Backup Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'تفعيل النسخ الاحتياطي التلقائي المجدول',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'إنشاء نسخة احتياطية دورية بالخلفية وحفظها في الوجهة المحددة',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    value: _config.autoBackupEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) async {
                      final newConfig = BackupConfig(
                        externalDestinationPath:
                            _config.externalDestinationPath,
                        autoBackupEnabled: val,
                        autoBackupFrequency: _config.autoBackupFrequency,
                        lastAutoBackupDate: _config.lastAutoBackupDate,
                      );
                      await _backupService.saveBackupConfig(newConfig);
                      setState(() => _config = newConfig);
                    },
                  ),

                  if (_config.autoBackupEnabled) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'تكرار الجدولة:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _config.autoBackupFrequency,
                          items: const [
                            DropdownMenuItem(
                              value: 'daily',
                              child: Text('يومياً (عند إغلاق الوردية)'),
                            ),
                            DropdownMenuItem(
                              value: 'weekly',
                              child: Text('أسبوعياً'),
                            ),
                            DropdownMenuItem(
                              value: 'monthly',
                              child: Text('شهرياً'),
                            ),
                          ],
                          onChanged: (val) async {
                            if (val != null) {
                              final newConfig = BackupConfig(
                                externalDestinationPath:
                                    _config.externalDestinationPath,
                                autoBackupEnabled: _config.autoBackupEnabled,
                                autoBackupFrequency: val,
                                lastAutoBackupDate: _config.lastAutoBackupDate,
                              );
                              await _backupService.saveBackupConfig(newConfig);
                              setState(() => _config = newConfig);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: AUDIT LOGS ---
  Widget _buildLogsTab() {
    if (_backupLogs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'لا توجد سجلات نسخ أو استعادة سابقة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.darkNeutral,
              ),
            ),
            Text(
              'جميع عمليات النسخ الداخلي والخارجي والاستعادة ستوثق هنا تلقائياً',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _backupLogs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final log = _backupLogs[index];
        final isSuccess = log.status == 'success';
        final color = isSuccess ? AppColors.success : AppColors.critical;

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              log.backupName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              log.typeDisplayArabic,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${log.createdAt} | الحجم: ${log.formattedSize}${log.destination != null ? ' | الوجهة: ${log.destination}' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (log.errorMessage != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'خطأ: ${log.errorMessage}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.critical,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
