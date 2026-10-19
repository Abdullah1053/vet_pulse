import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/database_backup_service.dart';
import '../controllers/backup_controller.dart';

class DatabaseBackupView extends GetView<BackupController> {
  const DatabaseBackupView({super.key});

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
              child: Obx(
                () => Row(
                  children: List.generate(tabItems.length, (index) {
                    final isSelected =
                        controller.selectedTabIndex.value == index;
                    final item = tabItems[index];

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => controller.setTabIndex(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
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
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              // Loading Progress Bar
              Obx(() {
                if (!controller.isLoading.value) {
                  return const SizedBox.shrink();
                }
                return Container(
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
                          controller.statusMessage.value,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Active DB Status Banner
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: _buildActiveDbCard(),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: controller.tabController,
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
    return Obx(() {
      final active = controller.activeDbInfo.value;
      final internalCount = controller.internalBackups.length;
      final canRestore = controller.canRestore;

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
                            text: active?.fileName ?? 'vet_pulse.db',
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
                      'الحجم الحالي: ${active?.formattedSize ?? "جاري الحساب..."} | عدد النسخ المحلية: $internalCount',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: canRestore
                      ? AppColors.success.withValues(alpha: 0.15)
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: canRestore
                        ? AppColors.success
                        : Colors.orange.shade400,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      canRestore
                          ? Icons.admin_panel_settings
                          : Icons.lock_clock,
                      size: 14,
                      color: canRestore
                          ? AppColors.success
                          : Colors.orange.shade800,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      canRestore ? 'صلاحيات استعادة كاملة' : 'عرض فقط',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: canRestore
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
    });
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
                    child: Obx(
                      () => ElevatedButton.icon(
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.createInternalBackup,
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
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Internal Backups List Header
          Obx(() {
            final backups = controller.internalBackups;
            return Row(
              children: [
                Text(
                  'النسخ المتوفرة (${backups.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(width: 8),
                if (backups.isNotEmpty)
                  Expanded(
                    child: Text(
                      'المسار: ${backups.first.shortDirectoryPath}',
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
            );
          }),
          const SizedBox(height: 10),

          Obx(() {
            final backups = controller.internalBackups;
            if (backups.isEmpty) {
              return Container(
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
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: backups.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final b = backups[index];
                return _buildBackupItemCard(b);
              },
            );
          }),
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
            Obx(() {
              final canRestore = controller.canRestore;
              final loading = controller.isLoading.value;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: canRestore
                        ? 'استعادة هذه النسخة'
                        : 'تتطلب صلاحية Lead Doctor',
                    icon: Icon(
                      Icons.restore_page_rounded,
                      color: canRestore ? Colors.orange.shade800 : Colors.grey,
                      size: 20,
                    ),
                    onPressed: canRestore && !loading
                        ? () => controller.confirmAndRestore(b.path)
                        : null,
                  ),
                  IconButton(
                    tooltip: 'حذف من الجهاز',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.critical,
                      size: 20,
                    ),
                    onPressed: !loading
                        ? () => controller.confirmAndDelete(b.path)
                        : null,
                  ),
                ],
              );
            }),
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
                        child: Obx(
                          () => ElevatedButton.icon(
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.exportExternalBackup,
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
                      ),
                      const SizedBox(width: 8),
                      Obx(
                        () => OutlinedButton.icon(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.shareBackup,
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
                  Obx(
                    () => ElevatedButton(
                      onPressed: controller.canRestore &&
                              !controller.isLoading.value
                          ? () => controller.confirmAndRestore(null)
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
                          child: Obx(() {
                            final dest =
                                controller.config.value.externalDestinationPath;
                            return Text(
                              dest ??
                                  'لم يتم تعيين وجهة افتراضية بعد (سيتم طلبها عند التصدير)',
                              style: TextStyle(
                                fontSize: 11,
                                color: dest != null
                                    ? AppColors.darkNeutral
                                    : AppColors.textSecondary,
                              ),
                            );
                          }),
                        ),
                        TextButton(
                          onPressed: controller.pickExternalFolder,
                          child: const Text('تغيير المجلد'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Auto Backup Toggle
                  Obx(
                    () => SwitchListTile(
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
                      value: controller.config.value.autoBackupEnabled,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) =>
                          controller.updateAutoBackupEnabled(val),
                    ),
                  ),

                  Obx(() {
                    if (!controller.config.value.autoBackupEnabled) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
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
                              value: controller.config.value.autoBackupFrequency,
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
                              onChanged: (val) {
                                if (val != null) {
                                  controller.updateAutoBackupFrequency(val);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
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
    return Obx(() {
      final logs = controller.backupLogs;
      if (logs.isEmpty) {
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
        itemCount: logs.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final log = logs[index];
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
    });
  }
}
