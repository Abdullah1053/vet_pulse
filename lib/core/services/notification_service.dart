import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../data/models/follow_up_model.dart';
import '../../data/models/surgery_model.dart';

class NotificationService extends GetxService {
  static NotificationService get to => Get.find<NotificationService>();

  static const String channelId = 'vet_pulse_clinical_alerts';
  static const String channelName = 'تنبيهات العمليات والمواعيد البيطرية';
  static const String channelDescription =
      'إشعارات وتنبيهات العمليات الجراحية ومواعيد المراجعات السريرية';

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final RxBool hasNotificationPermission = false.obs;
  final Set<String> _recordedKeys = <String>{};
  File? _dedupFile;

  static const AndroidNotificationDetails _androidNotificationDetails =
      AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: channelDescription,
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: _androidNotificationDetails,
  );

  @override
  void onInit() {
    super.onInit();
    _initLocalNotifications();
    checkPermissionStatus();
  }

  Future<void> _initLocalNotifications() async {
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Aden'));
      } catch (_) {
        try {
          tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('NotificationService: timezone init error: $e');
    }

    try {
      await _initDeduplicationTracker();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings();
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped with payload: ${response.payload}');
        },
      );

      // Create high-priority Android Notification Channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
      }
    } catch (e) {
      debugPrint('NotificationService: local notifications init error: $e');
    }
  }

  // --- Deduplication Tracker ---

  Future<void> _initDeduplicationTracker() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _dedupFile = File('${dir.path}/notification_dedup_keys.json');
      if (await _dedupFile!.exists()) {
        final content = await _dedupFile!.readAsString();
        final List<dynamic> list = jsonDecode(content) as List<dynamic>;
        _recordedKeys.addAll(list.map((e) => e.toString()));
      }
    } catch (e) {
      debugPrint('NotificationService: error loading deduplication file: $e');
    }
  }

  bool isNotificationRecorded(String key) => _recordedKeys.contains(key);

  Future<void> markNotificationRecorded(String key) async {
    if (_recordedKeys.contains(key)) return;
    _recordedKeys.add(key);
    await _persistRecordedKeys();
  }

  Future<void> removeNotificationKey(String key) async {
    if (_recordedKeys.remove(key)) {
      await _persistRecordedKeys();
    }
  }

  Future<void> _persistRecordedKeys() async {
    try {
      if (_dedupFile != null) {
        await _dedupFile!.writeAsString(jsonEncode(_recordedKeys.toList()));
      }
    } catch (e) {
      debugPrint('NotificationService: error persisting deduplication keys: $e');
    }
  }

  // --- Core Notification Methods ---

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        _notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('NotificationService: showInstantNotification error: $e');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) return;

    final tz.TZDateTime tzScheduledTime =
        tz.TZDateTime.from(scheduledTime, tz.local);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint(
          'NotificationService: exact alarm failed, falling back to inexact: $e');
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledTime,
          _notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (e2) {
        debugPrint('NotificationService: scheduleNotification fallback error: $e2');
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
    } catch (e) {
      debugPrint('NotificationService: cancelNotification error: $e');
    }
  }

  // --- Surgery Reminders (12h, 6h, 1h) ---

  Future<void> scheduleSurgeryReminders(SurgeryModel surgery) async {
    if (surgery.id == null) return;
    if (surgery.status != 'scheduled') {
      await cancelSurgeryReminders(surgery.id!);
      return;
    }

    final parsedDate = parseDateTime(surgery.scheduledDate, null);
    if (parsedDate == null) return;

    final now = DateTime.now();
    final remaining = parsedDate.difference(now);

    // If surgery date has passed by more than 2 hours, skip
    if (remaining < -const Duration(hours: 2)) return;

    final petName = surgery.petName?.isNotEmpty == true ? surgery.petName! : 'المريض';
    final surgeryName = surgery.surgeryName;

    final windows = [
      (
        duration: const Duration(hours: 12),
        idOffset: 1,
        keySuffix: '12h',
        title: 'تذكير موعد عملية جراحية (خلال 12 ساعة)',
        body: 'العملية: $surgeryName للمريض $petName - الموعد: ${surgery.scheduledDate}',
      ),
      (
        duration: const Duration(hours: 6),
        idOffset: 2,
        keySuffix: '6h',
        title: 'تنبيه موعد عملية جراحية (خلال 6 ساعات)',
        body: 'العملية: $surgeryName للمريض $petName - يرجى التأكد من صيام الحيوان وتجهيز المعدات',
      ),
      (
        duration: const Duration(hours: 1),
        idOffset: 3,
        keySuffix: '1h',
        title: 'عاجل: موعد عملية جراحية (خلال ساعة واحدة)',
        body: 'العملية: $surgeryName للمريض $petName ستبدأ قريباً!',
      ),
    ];

    for (final w in windows) {
      final reminderTime = parsedDate.subtract(w.duration);
      final notifId = surgery.id! * 10 + w.idOffset;
      final key = 'surgery_${surgery.id}_${w.keySuffix}';

      if (reminderTime.isAfter(now)) {
        // Future reminder: schedule OS notification
        await scheduleNotification(
          id: notifId,
          title: w.title,
          body: w.body,
          scheduledTime: reminderTime,
          payload: 'surgery_${surgery.id}',
        );
        await markNotificationRecorded(key);
      } else {
        // Window reminder time already reached.
        // Check if currently within active window and not sent yet.
        if (remaining <= w.duration && remaining > -const Duration(minutes: 30)) {
          if (!isNotificationRecorded(key)) {
            // Determine if a more urgent window also passed to prevent spamming multiple alerts at once
            final isSuperSeded = (w.keySuffix == '12h' && remaining <= const Duration(hours: 6)) ||
                (w.keySuffix == '6h' && remaining <= const Duration(hours: 1));

            if (!isSuperSeded) {
              await showInstantNotification(
                id: notifId,
                title: w.title,
                body: w.body,
                payload: 'surgery_${surgery.id}',
              );
            }
            await markNotificationRecorded(key);
          }
        }
      }
    }
  }

  Future<void> cancelSurgeryReminders(int surgeryId) async {
    await cancelNotification(surgeryId * 10 + 1);
    await cancelNotification(surgeryId * 10 + 2);
    await cancelNotification(surgeryId * 10 + 3);
    await removeNotificationKey('surgery_${surgeryId}_12h');
    await removeNotificationKey('surgery_${surgeryId}_6h');
    await removeNotificationKey('surgery_${surgeryId}_1h');
  }

  // --- Follow-Up Reminders ---

  Future<void> scheduleFollowUpReminder(FollowUpModel followUp) async {
    if (followUp.id == null) return;
    if (followUp.status != 'pending') {
      await cancelFollowUpReminder(followUp.id!);
      return;
    }

    final parsedDate = parseDateTime(followUp.scheduledDate, followUp.scheduledTime);
    if (parsedDate == null) return;

    final now = DateTime.now();
    final remaining = parsedDate.difference(now);
    final petName = followUp.petName?.isNotEmpty == true ? followUp.petName! : 'المريض';
    final reason = followUp.reason.isNotEmpty ? followUp.reason : 'متابعة سريرية';

    final notifId = followUp.id! * 10 + 4;
    final key = 'followup_${followUp.id}_due';

    if (parsedDate.isAfter(now)) {
      // Future follow-up: schedule OS notification
      await scheduleNotification(
        id: notifId,
        title: 'تذكير بموعد مراجعة سريرية',
        body: 'موعد مراجعة للمريض $petName - الموضوع: $reason',
        scheduledTime: parsedDate,
        payload: 'followup_${followUp.id}',
      );
      await markNotificationRecorded(key);
    } else {
      // Due today or overdue
      final isToday = parsedDate.year == now.year &&
          parsedDate.month == now.month &&
          parsedDate.day == now.day;

      if ((isToday || remaining.isNegative) && remaining > -const Duration(days: 3)) {
        if (!isNotificationRecorded(key)) {
          await showInstantNotification(
            id: notifId,
            title: isToday
                ? 'موعد مراجعة مستحق اليوم'
                : 'تنبيه: موعد مراجعة متأخر ومستحق',
            body: 'مراجعة للمريض $petName ($reason) - يرجى التواصل مع المالك',
            payload: 'followup_${followUp.id}',
          );
          await markNotificationRecorded(key);
        }
      }
    }
  }

  Future<void> cancelFollowUpReminder(int followUpId) async {
    await cancelNotification(followUpId * 10 + 4);
    await removeNotificationKey('followup_${followUpId}_due');
  }

  // --- Shared Date & Time Parser ---

  static DateTime? parseDateTime(String dateStr, String? timeStr) {
    try {
      final cleanDate = dateStr.trim().split(' ').first;
      final parts = cleanDate.split('-');
      if (parts.length != 3) return null;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      int hour = 9;
      int minute = 0;

      final checkTime = timeStr ??
          (dateStr.trim().contains(' ')
              ? dateStr.trim().split(' ').sublist(1).join(' ')
              : null);

      if (checkTime != null && checkTime.isNotEmpty) {
        final isPm =
            checkTime.contains('م') || checkTime.toLowerCase().contains('pm');
        final rawNumbers = RegExp(r'(\d+):(\d+)').firstMatch(checkTime);
        if (rawNumbers != null) {
          hour = int.parse(rawNumbers.group(1)!);
          minute = int.parse(rawNumbers.group(2)!);
          if (isPm && hour < 12) hour += 12;
          if (!isPm &&
              hour == 12 &&
              (checkTime.contains('ص') ||
                  checkTime.toLowerCase().contains('am'))) {
            hour = 0;
          }
        }
      }
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  // --- Permissions Management ---

  Future<void> checkPermissionStatus() async {
    try {
      final status = await Permission.notification.status;
      hasNotificationPermission.value = status.isGranted;
    } catch (_) {
      hasNotificationPermission.value = false;
    }
  }

  Future<bool> requestNotificationPermission({bool showDialogIfDenied = true}) async {
    try {
      final status = await Permission.notification.request();
      hasNotificationPermission.value = status.isGranted;

      // Request exact alarm permission if available on modern Android
      try {
        final exactStatus = await Permission.scheduleExactAlarm.status;
        if (exactStatus.isDenied) {
          await Permission.scheduleExactAlarm.request();
        }
      } catch (_) {}

      if (status.isGranted) {
        Get.snackbar(
          'تم تفعيل الإشعارات بنجاح',
          'ستصلك تنبيهات العمليات الجراحية ومواعيد المراجعات على هاتفك',
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          icon: const Icon(Icons.notifications_active, color: Colors.green),
          duration: const Duration(seconds: 3),
        );
        return true;
      } else if (status.isPermanentlyDenied && showDialogIfDenied) {
        _showOpenSettingsDialog();
        return false;
      } else {
        if (showDialogIfDenied) {
          Get.snackbar(
            'تنبيه الإشعارات',
            'يرجى السماح بصلاحية الإشعارات لتصلك تنبيهات العمليات والمراجعات البيطرية',
            backgroundColor: Colors.amber.shade100,
            colorText: Colors.brown.shade900,
            icon: const Icon(Icons.notifications_off, color: Colors.amber),
            duration: const Duration(seconds: 4),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('NotificationService: error requesting permission: $e');
      return false;
    }
  }

  void _showOpenSettingsDialog() {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_paused, color: Colors.orange),
            SizedBox(width: 8),
            Text('تفعيل إشعارات التطبيق'),
          ],
        ),
        content: const Text(
          'تم رفض صلاحية الإشعارات مسبقاً. للحصول على تذكيرات العمليات الجراحية ومواعيد المراجعات التلقائية، يرجى تفعيل الإشعارات من إعدادات الهاتف.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
  }
}
