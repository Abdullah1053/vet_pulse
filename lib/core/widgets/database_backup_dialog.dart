import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../../data/models/backup_log_model.dart';
import '../../data/services/database_backup_service.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../../modules/dashboard/controllers/dashboard_controller.dart';
import '../../modules/financials/controllers/financial_controller.dart';

class DatabaseBackupDialog extends StatefulWidget {
  const DatabaseBackupDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DatabaseBackupDialog(),
    );
  }

  @override
  State<DatabaseBackupDialog> createState() => _DatabaseBackupDialogState();
}

class _DatabaseBackupDialogState extends State<DatabaseBackupDialog> with SingleTickerProviderStateMixin {
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
      return Get.find<AuthController>().currentUser.value?.role ?? 'lead_doctor';
    }
    return 'lead_doctor';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final selectedDirectory = await FilePickerPlatform.instance.getDirectoryPath(
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
    // 1. Role Authorization Check
    if (_currentUserRole != 'lead_doctor' && _currentUserRole != 'admin') {
      Get.snackbar(
        'صلاحية غير كافية ⛔',
        'استعادة النسخ الاحتياطية تتطلب صلاحيات الطبيب المسؤول (Lead Doctor) لحماية البيانات.',
        backgroundColor: AppColors.criticalBackground,
        colorText: AppColors.critical,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    // 2. Explicit Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('تأكيد استعادة النسخة الاحتياطية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        msg = await _backupService.restoreFromFile(filePath, userRole: _currentUserRole);
      } else {
        msg = await _backupService.restoreFromBackupPicker(userRole: _currentUserRole);
      }

      if (!mounted) return;

      // Refresh running state controllers
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
      Navigator.of(context).pop();
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
        title: const Text('تأكيد حذف النسخة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('هل تريد بالتأكيد حذف ملف النسخة الاحتياطية المحدد من الذاكرة الداخلية؟'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.critical, foregroundColor: Colors.white),
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 650,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, color: AppColors.primary, size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إدارة النسخ الاحتياطي والأمان',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      Text(
                        'النسخ الداخلي، التصدير الخارجي، وسجل العمليات والتدقيق',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.storage, size: 20), text: 'النسخ الداخلي'),
                Tab(icon: Icon(Icons.usb, size: 20), text: 'النسخ الخارجي'),
                Tab(icon: Icon(Icons.history, size: 20), text: 'سجل العمليات'),
              ],
            ),
            const SizedBox(height: 12),

            // Loading Indicator
            if (_isLoading) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
    );
  }

  // --- TAB 1: INTERNAL BACKUP ---
  Widget _buildInternalTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Active DB Card
        Card(
          color: Colors.blue.shade50.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.data_usage, color: Colors.blue.shade800, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'قاعدة البيانات النشطة: ${_activeDbInfo?.formattedSize ?? "جاري الفحص..."}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade900),
                      ),
                      Text(
                        'آخر تعديل: ${_activeDbInfo?.formattedDate ?? "-"}',
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _createInternalBackup,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إنشاء نسخة الآن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // List Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'النسخ الاحتياطية الداخلية المتوفرة (${_internalBackups.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // List
        Expanded(
          child: _internalBackups.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off, size: 40, color: AppColors.textMuted),
                      SizedBox(height: 8),
                      Text('لا توجد نسخ احتياطية داخلية بعد', style: TextStyle(color: AppColors.textSecondary)),
                      Text('اضغط على "إنشاء نسخة الآن" لحفظ أول نسخة محلية', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _internalBackups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, idx) {
                    final b = _internalBackups[idx];
                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.backup_outlined, size: 18, color: AppColors.primary),
                        ),
                        title: Text(
                          b.fileName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'تاريخ الإنشاء: ${b.formattedDate} | الحجم: ${b.formattedSize}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: _isLoading ? null : () => _restoreBackup(b.path),
                              child: const Text('استعادة', style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.critical),
                              tooltip: 'حذف النسخة',
                              onPressed: _isLoading ? null : () => _deleteInternalBackup(b.path),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB 2: EXTERNAL BACKUP ---
  Widget _buildExternalTab() {
    final dest = _config.externalDestinationPath;
    final hasDest = dest != null && dest.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // External Destination Config Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.folder_shared_outlined, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'إعدادات وجهة النسخ الخارجي (فلاش / مجلد)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasDest ? Icons.usb : Icons.help_outline,
                          size: 18,
                          color: hasDest ? AppColors.success : AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hasDest ? dest : 'لم يتم تحديد وجهة خارجية بعد (فلاش ميموري أو مجلد)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: hasDest ? FontWeight.bold : FontWeight.normal,
                              color: hasDest ? AppColors.textPrimary : AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.primaryDark,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: _isLoading ? null : _pickExternalFolder,
                          child: const Text('تحديد وجهة', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // External Actions Row
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('عمليات النسخ والتصدير الخارجي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _exportExternalBackup,
                          icon: const Icon(Icons.save_alt, size: 18),
                          label: const Text('تصدير إلى فلاش / مجلد', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _shareBackup,
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('مشاركة عبر النظام', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : () => _restoreBackup(null),
                    icon: const Icon(Icons.upload_file, size: 18, color: Colors.orange),
                    label: const Text('استعادة من ملف خارجي (.db)', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.orange.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Automated Scheduling Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.schedule, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('الجدولة التلقائية للنسخ الاحتياطي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      Switch(
                        value: _config.autoBackupEnabled,
                        onChanged: (val) async {
                          final newConfig = BackupConfig(
                            externalDestinationPath: _config.externalDestinationPath,
                            autoBackupEnabled: val,
                            autoBackupFrequency: _config.autoBackupFrequency,
                            lastAutoBackupDate: _config.lastAutoBackupDate,
                          );
                          await _backupService.saveBackupConfig(newConfig);
                          setState(() => _config = newConfig);
                        },
                      ),
                    ],
                  ),
                  if (_config.autoBackupEnabled) ...[
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('تكرار النسخ الاحتياطي التلقائي:', style: TextStyle(fontSize: 12)),
                        DropdownButton<String>(
                          value: _config.autoBackupFrequency,
                          items: const [
                            DropdownMenuItem(value: 'daily', child: Text('يومياً (Daily)')),
                            DropdownMenuItem(value: 'weekly', child: Text('أسبوعياً (Weekly)')),
                          ],
                          onChanged: (val) async {
                            if (val != null) {
                              final newConfig = BackupConfig(
                                externalDestinationPath: _config.externalDestinationPath,
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
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 40, color: AppColors.textMuted),
            SizedBox(height: 8),
            Text('لا توجد سجلات نسخ أو استعادة سابقة', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _backupLogs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, idx) {
        final log = _backupLogs[idx];
        final isSuccess = log.isSuccess;
        final isRestore = log.backupType == 'restore';

        IconData icon;
        Color color;
        if (!isSuccess) {
          icon = Icons.error_outline;
          color = AppColors.critical;
        } else if (isRestore) {
          icon = Icons.settings_backup_restore;
          color = Colors.orange.shade800;
        } else {
          icon = Icons.check_circle_outline;
          color = AppColors.success;
        }

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, size: 18, color: color),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    log.backupName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log.typeDisplayArabic,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.createdAt} | الحجم: ${log.formattedSize}${log.destination != null ? ' | الوجهة: ${log.destination}' : ''}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
                if (log.errorMessage != null) ...[
                  Text(
                    'خطأ: ${log.errorMessage}',
                    style: const TextStyle(fontSize: 10, color: AppColors.critical),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
