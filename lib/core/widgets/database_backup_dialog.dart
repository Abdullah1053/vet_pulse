import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../../data/services/database_backup_service.dart';
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

class _DatabaseBackupDialogState extends State<DatabaseBackupDialog> {
  final DatabaseBackupService _backupService = DatabaseBackupService.instance;
  DatabaseBackupInfo? _dbInfo;
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDbInfo();
  }

  Future<void> _loadDbInfo() async {
    final info = await _backupService.getDatabaseInfo();
    if (mounted) {
      setState(() => _dbInfo = info);
    }
  }

  Future<void> _exportToFile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري تحضير ونسخ قاعدة البيانات...';
    });

    try {
      final savedPath = await _backupService.exportBackupToFilePicker();
      if (savedPath != null) {
        if (!mounted) return;
        Get.snackbar(
          'تم حفظ النسخة الاحتياطية بنجاح ✅',
          'تم الحفظ في: $savedPath',
          backgroundColor: AppColors.success.withValues(alpha: 0.15),
          colorText: AppColors.success,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'خطأ أثناء الحفظ',
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
        _loadDbInfo();
      }
    }
  }

  Future<void> _shareBackup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'جاري تجهيز ملف النسخة الاحتياطية للمشاركة...';
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

  Future<void> _restoreBackup() async {
    // Show confirmation dialog before restoring
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
          'تنبيه: سيتم استبدال البيانات الحالية بالبيانات الموجودة في ملف النسخة الاحتياطية المختارة من الفلاش أو القرص الخارجي.\n\nهل أنت متأكد من المتابعة؟',
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
            child: const Text('نعم، استعادة البيانات'),
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
      final msg = await _backupService.restoreFromBackupPicker();
      if (!mounted) return;

      // Refresh running controllers
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
        'تعذر الاستعادة',
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
        _loadDbInfo();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storage_rounded, color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'النسخ الاحتياطي واستعادة البيانات',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'حفظ نسخة كاملة من قاعدة بيانات العيادة على فلاش أو قرص خارجي',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Active Database Status Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF475569), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'قاعدة البيانات النشطة: vet_pulse.db',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dbInfo != null
                                ? 'الحجم: ${_dbInfo!.formattedSize} | آخر تعديل: ${_dbInfo!.formattedDate}'
                                : 'جاري التحميل...',
                            style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Loading indicator if busy
              if (_isLoading) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 10),
                      Text(
                        _statusMessage,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Action 1: Export / Backup
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F6F4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2A9D8F).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.save_alt_rounded, color: Color(0xFF2A9D8F), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'حفظ نسخة احتياطية (تصدير)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1E3A3A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'حفظ ملف قاعدة البيانات (.db) كاملاً يحتوي على جميع المرضى والكشوفات والعمليات والحسابات.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF4A6B6B)),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _exportToFile,
                              icon: const Icon(Icons.usb, size: 18),
                              label: const Text(
                                'حفظ على فلاش / مجلد',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A9D8F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _shareBackup,
                            icon: const Icon(Icons.share, size: 16),
                            label: const Text('مشاركة', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2A9D8F),
                              side: const BorderSide(color: Color(0xFF2A9D8F)),
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Action 2: Restore
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.settings_backup_restore_rounded, color: Colors.orange.shade800, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'استعادة نسخة احتياطية (استيراد)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.orange.shade900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'استرجاع البيانات من ملف نسخة احتياطية (.db) مخزنة مسبقاً على الفلاش ميموري أو القرص.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF8A5A1A)),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _restoreBackup,
                          icon: const Icon(Icons.file_open_outlined, size: 18),
                          label: const Text(
                            'اختيار ملف النسخة (.db) واستعادة البيانات',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Bottom Cancel button
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('إغلاق النافذة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
