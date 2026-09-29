import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/database/database_tables.dart';

enum AlertUrgency {
  oneHour,   // <= 1 hour remaining
  sixHours,  // <= 6 hours remaining
  twelveHours, // <= 12 hours remaining
  pastDue,   // Time already passed but still pending
}

class ClinicAlertItem {
  final int id;
  final String type; // 'surgery' or 'follow_up'
  final String title;
  final String petName;
  final String petSpecies;
  final String ownerName;
  final String? ownerPhone;
  final DateTime scheduledDateTime;
  final Duration remaining;
  final AlertUrgency urgency;

  ClinicAlertItem({
    required this.id,
    required this.type,
    required this.title,
    required this.petName,
    required this.petSpecies,
    required this.ownerName,
    required this.ownerPhone,
    required this.scheduledDateTime,
    required this.remaining,
    required this.urgency,
  });

  String get remainingTextArabic {
    if (remaining.isNegative) {
      return 'متأخر';
    }
    if (remaining.inMinutes < 60) {
      return 'متبقي ${remaining.inMinutes} دقيقة';
    }
    final hours = remaining.inHours;
    final mins = remaining.inMinutes % 60;
    return mins > 0 ? 'متبقي $hours ساعة و $mins د' : 'متبقي $hours ساعة';
  }

  Color get urgencyColor {
    switch (urgency) {
      case AlertUrgency.oneHour:
        return AppColors.critical;
      case AlertUrgency.sixHours:
        return Colors.orange.shade800;
      case AlertUrgency.twelveHours:
        return AppColors.accent;
      case AlertUrgency.pastDue:
        return Colors.red.shade900;
    }
  }

  String get urgencyLabelArabic {
    switch (urgency) {
      case AlertUrgency.oneHour:
        return 'عاجل جداً (أقل من ساعة)';
      case AlertUrgency.sixHours:
        return 'تنبيه موعد (خلال 6 ساعات)';
      case AlertUrgency.twelveHours:
        return 'تذكير مسبق (خلال 12 ساعة)';
      case AlertUrgency.pastDue:
        return 'موعد متأخر';
    }
  }
}

class AlertsController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  final RxList<ClinicAlertItem> alerts = <ClinicAlertItem>[].obs;
  final RxInt activeAlertsCount = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshAlerts();
  }

  Future<void> refreshAlerts() async {
    isLoading.value = true;
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();
      final List<ClinicAlertItem> list = [];

      // 1. Follow-Ups
      final followUpRows = await db.rawQuery('''
        SELECT 
          f.*, 
          p.name AS pet_name, 
          p.species AS pet_species,
          o.full_name AS owner_name, 
          o.phone_primary AS owner_phone
        FROM ${DatabaseTables.tableFollowUps} f
        INNER JOIN ${DatabaseTables.tablePets} p ON f.pet_id = p.id
        INNER JOIN ${DatabaseTables.tableOwners} o ON p.owner_id = o.id
        WHERE f.status = 'pending'
      ''');

      for (final row in followUpRows) {
        final dateStr = row['scheduled_date'] as String;
        final timeStr = row['scheduled_time'] as String?;
        final parsed = _parseDateTime(dateStr, timeStr);
        if (parsed != null) {
          final diff = parsed.difference(now);
          final alert = _categorizeAlert(
            id: row['id'] as int,
            type: 'follow_up',
            title: row['reason'] as String? ?? 'موعد مراجعة',
            petName: row['pet_name'] as String? ?? 'المريض',
            petSpecies: row['pet_species'] as String? ?? '',
            ownerName: row['owner_name'] as String? ?? '',
            ownerPhone: row['owner_phone'] as String?,
            target: parsed,
            diff: diff,
          );
          if (alert != null) list.add(alert);
        }
      }

      // 2. Surgeries
      final surgeryRows = await db.rawQuery('''
        SELECT 
          s.*, 
          p.name AS pet_name, 
          p.species AS pet_species,
          o.full_name AS owner_name, 
          o.phone_primary AS owner_phone
        FROM ${DatabaseTables.tableSurgeries} s
        INNER JOIN ${DatabaseTables.tablePets} p ON s.pet_id = p.id
        INNER JOIN ${DatabaseTables.tableOwners} o ON p.owner_id = o.id
        WHERE s.status = 'scheduled'
      ''');

      for (final row in surgeryRows) {
        final fullDate = row['scheduled_date'] as String;
        final parsed = _parseDateTime(fullDate, null);
        if (parsed != null) {
          final diff = parsed.difference(now);
          final alert = _categorizeAlert(
            id: row['id'] as int,
            type: 'surgery',
            title: 'عملية جراحية: ${row['surgery_name']}',
            petName: row['pet_name'] as String? ?? 'المريض',
            petSpecies: row['pet_species'] as String? ?? '',
            ownerName: row['owner_name'] as String? ?? '',
            ownerPhone: row['owner_phone'] as String?,
            target: parsed,
            diff: diff,
          );
          if (alert != null) list.add(alert);
        }
      }

      // Sort by urgency: shortest remaining time first
      list.sort((a, b) => a.remaining.compareTo(b.remaining));
      alerts.assignAll(list);
      activeAlertsCount.value = list.length;
    } finally {
      isLoading.value = false;
    }
  }

  ClinicAlertItem? _categorizeAlert({
    required int id,
    required String type,
    required String title,
    required String petName,
    required String petSpecies,
    required String ownerName,
    required String? ownerPhone,
    required DateTime target,
    required Duration diff,
  }) {
    AlertUrgency? urgency;
    if (diff.isNegative && diff.inHours.abs() <= 24) {
      urgency = AlertUrgency.pastDue;
    } else if (!diff.isNegative && diff.inMinutes <= 60) {
      urgency = AlertUrgency.oneHour;
    } else if (!diff.isNegative && diff.inHours <= 6) {
      urgency = AlertUrgency.sixHours;
    } else if (!diff.isNegative && diff.inHours <= 12) {
      urgency = AlertUrgency.twelveHours;
    }

    if (urgency != null) {
      return ClinicAlertItem(
        id: id,
        type: type,
        title: title,
        petName: petName,
        petSpecies: petSpecies,
        ownerName: ownerName,
        ownerPhone: ownerPhone,
        scheduledDateTime: target,
        remaining: diff,
        urgency: urgency,
      );
    }
    return null;
  }

  DateTime? _parseDateTime(String dateStr, String? timeStr) {
    try {
      final cleanDate = dateStr.trim().split(' ').first;
      final parts = cleanDate.split('-');
      if (parts.length != 3) return null;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      int hour = 9;
      int minute = 0;

      final checkTime = timeStr ?? (dateStr.trim().contains(' ') ? dateStr.trim().split(' ').sublist(1).join(' ') : null);

      if (checkTime != null && checkTime.isNotEmpty) {
        final isPm = checkTime.contains('م') || checkTime.toLowerCase().contains('pm');
        final rawNumbers = RegExp(r'(\d+):(\d+)').firstMatch(checkTime);
        if (rawNumbers != null) {
          hour = int.parse(rawNumbers.group(1)!);
          minute = int.parse(rawNumbers.group(2)!);
          if (isPm && hour < 12) hour += 12;
          if (!isPm && hour == 12 && (checkTime.contains('ص') || checkTime.toLowerCase().contains('am'))) {
            hour = 0;
          }
        }
      }
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  Future<void> sendWhatsAppAlert(ClinicAlertItem item) async {
    if (item.ownerPhone == null || item.ownerPhone!.isEmpty) {
      Get.snackbar('تنبيه', 'رقم الهاتف غير مسجل للمالك', backgroundColor: Colors.amber.shade100);
      return;
    }
    final cleanPhone = item.ownerPhone!.replaceAll(RegExp(r'\D'), '');

    final msg = StringBuffer();
    msg.writeln('🐾 *تذكير عاجل من العيادة البيطرية*');
    msg.writeln('--------------------------------');
    msg.writeln('عزيزي المربي: نود تذكيركم بموعد حيوانكم الأليف *(${item.petName})*.');
    msg.writeln('📌 *النوع:* ${item.type == "surgery" ? "عملية جراحية" : "كشف ومراجعة سريرية"}');
    msg.writeln('🩺 *الموضوع:* ${item.title}');
    msg.writeln('⏰ *الوقت المتبقي:* ${item.remainingTextArabic}');
    msg.writeln('يرجى الالتزام بالموعد والحضور في الوقت المحدد.');

    final encoded = Uri.encodeComponent(msg.toString());
    final uri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar('تنبيه', 'تعذر فتح تطبيق واتساب', backgroundColor: Colors.amber.shade100);
    }
  }

  Future<void> callOwner(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
