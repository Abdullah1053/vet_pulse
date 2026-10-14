import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceContactService {
  /// Saves an owner's name and phone number to the native device contacts.
  /// Handles platform check and contacts runtime permissions.
  static Future<bool> saveOwnerToContacts({
    required String name,
    required String phone,
    bool showFeedback = true,
  }) async {
    // Only supported on mobile devices (Android / iOS)
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      if (showFeedback) {
        Get.snackbar(
          'غير مدعوم',
          'ميزة حفظ جهات الاتصال متاحة على أجهزة الهاتف المحمول فقط',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.amber.shade100,
          colorText: Colors.amber.shade900,
          icon: const Icon(Icons.info_outline, color: Colors.amber),
        );
      }
      return false;
    }

    try {
      // Request permission using flutter_contacts
      bool permissionGranted = await FlutterContacts.requestPermission(readonly: false);

      if (!permissionGranted) {
        // Fallback check with permission_handler
        final status = await Permission.contacts.request();
        permissionGranted = status.isGranted;
      }

      if (!permissionGranted) {
        if (showFeedback) {
          Get.snackbar(
            'الإذن مطلوب',
            'يرجى منح إذن الوصول لجهات الاتصال لحفظ بيانات المربي في هاتفك',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.shade100,
            colorText: Colors.orange.shade900,
            icon: const Icon(Icons.contact_phone_outlined, color: Colors.orange),
            mainButton: TextButton(
              onPressed: () => openAppSettings(),
              child: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        }
        return false;
      }

      // Check if contact already exists with this phone number to avoid duplicates
      try {
        final existingContacts = await FlutterContacts.getContacts(
          withProperties: true,
          sorted: false,
        );
        final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
        final alreadyExists = existingContacts.any((c) =>
            c.phones.any((p) => p.number.replaceAll(RegExp(r'[^0-9+]'), '') == cleanPhone));

        if (alreadyExists) {
          if (showFeedback) {
            Get.snackbar(
              'جهة الاتصال موجودة بالفعل',
              'الرقم $phone مسجل مسبقاً في جهات اتصال هاتفك',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.blue.shade100,
              colorText: Colors.blue.shade900,
              icon: const Icon(Icons.info_outline, color: Colors.blue),
            );
          }
          return true;
        }
      } catch (_) {
        // If checking existing contacts fails, proceed with insertion
      }

      // Create new contact
      final newContact = Contact()
        ..name.first = name.trim()
        ..phones = [Phone(phone.trim(), label: PhoneLabel.mobile)];

      await newContact.insert();

      if (showFeedback) {
        Get.snackbar(
          'تم الحفظ في الهاتف',
          'تم حفظ "$name" بنجاح في جهات اتصال هاتفك 📱',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          colorText: Colors.green.shade900,
          icon: const Icon(Icons.check_circle, color: Colors.green),
          duration: const Duration(seconds: 3),
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error saving contact: $e');
      if (showFeedback) {
        Get.snackbar(
          'خطأ في الحفظ',
          'تعذر حفظ جهة الاتصال: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
      }
      return false;
    }
  }
}
