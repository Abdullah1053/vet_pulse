import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import '../../data/database/database_helper.dart';
import '../../data/database/database_tables.dart';
import '../constants/app_colors.dart';

class DemoConfig {
  DemoConfig._();

  /// Flag to switch between Demo Edition and Full Commercial Edition
  static const bool isDemoMode = true;

  /// Maximum allowed records per feature in the Demo Edition (5 in everything)
  static const int maxLimit = 5;

  /// Developer & Sales Contact Details
  static const String developerName = 'مهندس برمجيات / عبدالله عبدالمغني الأديمي';
  static const String developerRole = 'استشاري ومطور الحلول البرمجية والأنظمة الطبية';
  static const String contactPhone = '777123456';
  static const String demoWatermark = 'نسخة تجريبية • VetPulse Demo Edition • إعداد: م. عبدالله عبدالمغني الأديمي';

  /// Helper to check if a new patient can be registered
  static Future<bool> canAddPatient() async {
    if (!isDemoMode) return true;
    final db = await DatabaseHelper.instance.database;
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.tablePets}'),
        ) ??
        0;

    if (count >= maxLimit) {
      showDemoLimitDialog(
        featureName: 'مرضى (سجلات حيوانات أليفة)',
        currentCount: count,
      );
      return false;
    }
    return true;
  }

  /// Helper to check if a new consultation (SOAP) can be registered
  static Future<bool> canAddConsultation() async {
    if (!isDemoMode) return true;
    final db = await DatabaseHelper.instance.database;
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.tableConsultations}'),
        ) ??
        0;

    if (count >= maxLimit) {
      showDemoLimitDialog(
        featureName: 'كشوفات سريرية (SOAP)',
        currentCount: count,
      );
      return false;
    }
    return true;
  }

  /// Helper to check if a new surgery can be booked
  static Future<bool> canAddSurgery() async {
    if (!isDemoMode) return true;
    final db = await DatabaseHelper.instance.database;
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.tableSurgeries}'),
        ) ??
        0;

    if (count >= maxLimit) {
      showDemoLimitDialog(
        featureName: 'عمليات جراحية',
        currentCount: count,
      );
      return false;
    }
    return true;
  }

  /// Helper to check if a new follow-up appointment can be booked
  static Future<bool> canAddFollowUp() async {
    if (!isDemoMode) return true;
    final db = await DatabaseHelper.instance.database;
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.tableFollowUps}'),
        ) ??
        0;

    if (count >= maxLimit) {
      showDemoLimitDialog(
        featureName: 'مواعيد ومراجعات',
        currentCount: count,
      );
      return false;
    }
    return true;
  }

  /// Helper to check if a new medicine can be added to pharmacy
  static Future<bool> canAddMedicine() async {
    if (!isDemoMode) return true;
    final db = await DatabaseHelper.instance.database;
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.tableMedicines}'),
        ) ??
        0;

    if (count >= maxLimit) {
      showDemoLimitDialog(
        featureName: 'أصناف دوائية في الصيدلية',
        currentCount: count,
      );
      return false;
    }
    return true;
  }

  /// Elegant Modal Dialog explaining the Demo Quota Limit
  static void showDemoLimitDialog({
    required String featureName,
    int currentCount = maxLimit,
  }) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.shade300, width: 2),
                ),
                child: const Icon(
                  Icons.lock_clock_outlined,
                  color: Colors.amber,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'الحد الأقصى للنسخة التجريبية (Demo)',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'لقد استنفدت السعة التجريبية المسموحة ($maxLimit $featureName).\n'
                'هذه النسخة مخصصة للاختبار السريري واستكشاف المميزات.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'لترقية النظام لمركزكم البيطري بدون أي قيود:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      developerName,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      developerRole,
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text('فهمت ذلك', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
