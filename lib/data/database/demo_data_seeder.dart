import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/services/data_sync_service.dart';
import 'database_helper.dart';
import 'database_tables.dart';

class DemoDataSeeder {
  DemoDataSeeder._();

  /// Check if the database has any owners/pets; if not, seed realistic demo data.
  static Future<void> seedIfEmpty() async {
    final db = await DatabaseHelper.instance.database;
    final ownerCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.tableOwners}'),
    ) ?? 0;

    if (ownerCount == 0) {
      await populateDemoData();
    }
  }

  /// Reset all patient, consultation, surgery, and appointment data back to pristine demo state.
  static Future<void> resetDemoData() async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      await txn.delete(DatabaseTables.tablePrescriptions);
      await txn.delete(DatabaseTables.tableFollowUps);
      await txn.delete(DatabaseTables.tableSurgeries);
      await txn.delete(DatabaseTables.tableConsultations);
      await txn.delete(DatabaseTables.tablePetWeights);
      await txn.delete(DatabaseTables.tablePets);
      await txn.delete(DatabaseTables.tableOwners);
    });

    await populateDemoData();
    DataSyncService.notifyAllChanged();

    if (Get.context != null) {
      Get.snackbar(
        'تم إعادة تهيئة بيانات العرض',
        'تم تحميل بيانات العيادة التجريبية المتكاملة بنجاح (مرضى، كشوفات، عمليات، ومواعيد)',
        backgroundColor: Colors.teal.shade100,
        colorText: Colors.teal.shade900,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Insert realistic clinic data for demonstration and sales presentations
  static Future<void> populateDemoData() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      // 1. Owners
      final owner1Id = await txn.insert(DatabaseTables.tableOwners, {
        'full_name': 'م. أحمد يحيى الشامي',
        'phone_primary': '0777123456',
        'phone_secondary': '0733123456',
        'address': 'صنعاء - حدة - خلف بريد حدة',
        'notes': 'عميل مميز - مهتم جداً بجدول التطعيمات ومواعيد العناية',
      });

      final owner2Id = await txn.insert(DatabaseTables.tableOwners, {
        'full_name': 'د. ريم محمد باعباد',
        'phone_primary': '0771987654',
        'phone_secondary': null,
        'address': 'صنعاء - الحي الدبلوماسي',
        'notes': 'طبيبة بشرية - تفضل إرسال التقارير والروشتات بصيغة PDF عبر واتساب',
      });

      final owner3Id = await txn.insert(DatabaseTables.tableOwners, {
        'full_name': 'أ. طارق عبدالكريم الحميري',
        'phone_primary': '0733556677',
        'phone_secondary': '0770556677',
        'address': 'صنعاء - شارع بغداد',
        'notes': 'مربي قطط شيرازية محترف',
      });

      final owner4Id = await txn.insert(DatabaseTables.tableOwners, {
        'full_name': 'فاطمة خالد اليماني',
        'phone_primary': '0775112233',
        'phone_secondary': null,
        'address': 'صنعاء - شارع الستين الجنوبي',
        'notes': 'عميلة جديدة - تم عمل فحص وقائي شامل للحيوان',
      });

      // 2. Pets
      final pet1Id = await txn.insert(DatabaseTables.tablePets, {
        'owner_id': owner1Id,
        'name': 'سيمبا (Simba)',
        'species': 'cat',
        'breed': 'شيرازي (Persian)',
        'gender': 'male',
        'is_neutered': 1,
        'date_of_birth': '2023-04-15',
        'microchip_number': '981098123456789',
        'allergies': 'تحسس من مشتقات البنسلين غير المحمية (Penicillin allergy)',
      });

      final pet2Id = await txn.insert(DatabaseTables.tablePets, {
        'owner_id': owner2Id,
        'name': 'روكي (Rocky)',
        'species': 'dog',
        'breed': 'جيرمن شيبرد (German Shepherd)',
        'gender': 'male',
        'is_neutered': 0,
        'date_of_birth': '2022-08-10',
        'microchip_number': '981098987654321',
        'allergies': 'لا توجد حساسيات معروفة',
      });

      final pet3Id = await txn.insert(DatabaseTables.tablePets, {
        'owner_id': owner3Id,
        'name': 'ميشو (Misho)',
        'species': 'cat',
        'breed': 'بريطاني قصير الشعر (British Shorthair)',
        'gender': 'male',
        'is_neutered': 1,
        'date_of_birth': '2024-01-20',
        'microchip_number': null,
        'allergies': 'حساسية طعام خفيفة من الدواجن المصنعة',
      });

      final pet4Id = await txn.insert(DatabaseTables.tablePets, {
        'owner_id': owner4Id,
        'name': 'لوزة (Louza)',
        'species': 'cat',
        'breed': 'سيامي (Siamese)',
        'gender': 'female',
        'is_neutered': 0,
        'date_of_birth': '2023-11-05',
        'microchip_number': null,
        'allergies': 'لا توجد',
      });

      // 3. Weight Tracking
      final pastDate1 = now.subtract(const Duration(days: 60)).toIso8601String().substring(0, 10);
      final pastDate2 = now.subtract(const Duration(days: 30)).toIso8601String().substring(0, 10);
      final todayStr = now.toIso8601String().substring(0, 10);

      await txn.insert(DatabaseTables.tablePetWeights, {'pet_id': pet1Id, 'weight': 3.8, 'recorded_date': pastDate1});
      await txn.insert(DatabaseTables.tablePetWeights, {'pet_id': pet1Id, 'weight': 4.0, 'recorded_date': pastDate2});
      await txn.insert(DatabaseTables.tablePetWeights, {'pet_id': pet1Id, 'weight': 4.25, 'recorded_date': todayStr});

      await txn.insert(DatabaseTables.tablePetWeights, {'pet_id': pet2Id, 'weight': 27.0, 'recorded_date': pastDate1});
      await txn.insert(DatabaseTables.tablePetWeights, {'pet_id': pet2Id, 'weight': 28.5, 'recorded_date': todayStr});

      // 4. Consultations (SOAP)
      // Consultation 1 for Simba
      final consult1Id = await txn.insert(DatabaseTables.tableConsultations, {
        'pet_id': pet1Id,
        'doctor_id': 1,
        'visit_date': '$todayStr 10:30 ص',
        'temperature': 39.2,
        'heart_rate': 145,
        'symptoms': 'خمول متزايد، فقدان للشهية منذ يومين، وتقيؤ متكرر بعد شرب الماء.',
        'examination_findings': 'جفاف خفيف (Dehydration ~5%)، ألم طفيف عند جس البطن، الأغشية المخاطية وردية شاحبة، لا توجد كتل مجسوسة.',
        'diagnosis': 'التهاب معوي حاد خفيف (Acute Mild Gastroenteritis)',
        'treatment_plan': 'إعطاء محاليل وريدية داعمة، مضاد قيء حقناً في العيادة، ومضاد حيوي واسع الطيف بالفم للمنزل مع حمية هضمية (Gastrointestinal Diet).',
        'visit_cost': 6500.0,
      });

      // Prescriptions for Consult 1
      await txn.insert(DatabaseTables.tablePrescriptions, {
        'consultation_id': consult1Id,
        'medicine_id': 1, // Synulox
        'dosage': 'نصف قرص (125mg)',
        'frequency': 'مرتين يومياً (كل 12 ساعة)',
        'duration_days': 5,
        'quantity_dispensed': 5,
        'instructions': 'يُعطى بعد وجبة طعام خفيفة لتقليل تهيج المعدة. إكمال كامل الكورس العلاجي.',
        'is_clinic_administered': 0,
        'route': 'عن طريق الفم (Oral)',
      });

      await txn.insert(DatabaseTables.tablePrescriptions, {
        'consultation_id': consult1Id,
        'medicine_id': 2, // Metacam
        'dosage': '0.4 ml',
        'frequency': 'مرة واحدة بالعيادة',
        'duration_days': 1,
        'quantity_dispensed': 1,
        'instructions': 'حُقنت بالعيادة لتسكين الألم وخفض الحرارة.',
        'is_clinic_administered': 1,
        'route': 'حقن عضلي (IM)',
      });

      // Consultation 2 for Rocky
      final pastConsultDate = now.subtract(const Duration(days: 14)).toIso8601String().substring(0, 10);
      final consult2Id = await txn.insert(DatabaseTables.tableConsultations, {
        'pet_id': pet2Id,
        'doctor_id': 1,
        'visit_date': '$pastConsultDate 04:00 م',
        'temperature': 38.6,
        'heart_rate': 88,
        'symptoms': 'فحص دوري سنوي وتجديد جدول التطعيمات والوقاية من الطفيليات.',
        'examination_findings': 'الوزن مثالي، المعطف لامع، العيون والأذنان نظيفة، الأسنان خالية من التكلس، فحص القلب والتنفس طبيعي.',
        'diagnosis': 'فحص سريري سليم + تطعيم خماسي دوري (DHPPi Routine Booster)',
        'treatment_plan': 'إعطاء اللقاح تحت الجلد، وإعطاء جرعة وقائية ضد الديدان المعوية، وموعد الجرعة التنشيطية بعد 3 أسابيع.',
        'visit_cost': 8000.0,
      });

      await txn.insert(DatabaseTables.tablePrescriptions, {
        'consultation_id': consult2Id,
        'medicine_id': 3, // Doxycycline or Dewormer
        'dosage': 'قرص ونصف',
        'frequency': 'جرعة واحدة',
        'duration_days': 1,
        'quantity_dispensed': 2,
        'instructions': 'تكرار الجرعة بعد أسبوعين في المنزل.',
        'is_clinic_administered': 0,
        'route': 'عن طريق الفم (Oral)',
      });

      // 5. Surgeries
      // Completed Surgery for Simba (Demonstrating post-op outcome and discharge records)
      final pastSurgeryDate = now.subtract(const Duration(days: 7)).toIso8601String().substring(0, 10);
      await txn.insert(DatabaseTables.tableSurgeries, {
        'pet_id': pet1Id,
        'lead_surgeon_id': 1,
        'surgery_name': 'استئصال حصوات المثانة (Cystotomy)',
        'surgery_category': 'جراحة مسالك بولية',
        'scheduled_date': '$pastSurgeryDate 09:00 ص',
        'anesthesia_protocol': 'Premed: Dexmedetomidine + Butorphanol | Ind: Propofol | Maint: Isoflurane 1.8%',
        'pre_op_checklist_passed': 1,
        'status': 'completed',
        'post_op_notes': 'تم استخراج 3 حصوات كروية بنجاح وإرسالها للتحليل المخبري. خياطة جدار المثانة بطبقتين محكمتين، التعافي من التخدير سلس وطبيعي دون أي مضاعفات.',
        'estimated_cost': 35000.0,
      });

      // Scheduled Surgery for Louza (Scheduled for today/tomorrow)
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowStr = tomorrow.toIso8601String().substring(0, 10);
      await txn.insert(DatabaseTables.tableSurgeries, {
        'pet_id': pet4Id,
        'lead_surgeon_id': 1,
        'surgery_name': 'تعقيم وقائي للمبيض والرحم (Ovariohysterectomy)',
        'surgery_category': 'جراحة وقائية',
        'scheduled_date': '$tomorrowStr 11:00 ص',
        'anesthesia_protocol': 'تخدير استنشاقي Sevoflurane مع مراقبة حيوية كاملة (SPO2, ECG, Capnography)',
        'pre_op_checklist_passed': 1,
        'status': 'scheduled',
        'post_op_notes': 'تم إبلاغ المالك بالصيام التام عن الطعام لمدة 8 ساعات قبل العملية.',
        'estimated_cost': 22000.0,
      });

      // 6. Follow-up Appointments (Critical for demonstrating the 1h, 6h, 12h alerts!)
      // Alert 1: Urgent within 1 hour (للاختبار الفوري للتنبيه الحرج ⚠️)
      final alert1Time = now.add(const Duration(minutes: 45));
      final alert1TimeStr = alert1Time.toIso8601String().substring(11, 16);
      await txn.insert(DatabaseTables.tableFollowUps, {
        'pet_id': pet1Id,
        'consultation_id': consult1Id,
        'scheduled_date': todayStr,
        'scheduled_time': alert1TimeStr,
        'reason': 'مراجعة سريرية وفحص خياطة الجراحة وإزالة الأنبوب (حرج ⚠️)',
        'status': 'pending',
        'reminder_sent': 0,
        'notes': 'فحص موضع الجرح والتأكد من عدم وجود تورم أو إفرازات، ومراقبة التبول الطبيعي.',
      });

      // Alert 2: Within 6 hours
      final alert2Time = now.add(const Duration(hours: 4));
      final alert2TimeStr = alert2Time.toIso8601String().substring(11, 16);
      await txn.insert(DatabaseTables.tableFollowUps, {
        'pet_id': pet2Id,
        'consultation_id': consult2Id,
        'scheduled_date': todayStr,
        'scheduled_time': alert2TimeStr,
        'reason': 'معاينة استجابة التطعيم وقياس الوزن الدوري',
        'status': 'pending',
        'reminder_sent': 0,
        'notes': 'التأكد من عدم حدوث أي تحسس بعد التطعيم وتسجيل الوزن في البطاقة الصحية.',
      });

      // Alert 3: Within 12 hours
      final alert3Time = now.add(const Duration(hours: 9));
      final alert3TimeStr = alert3Time.toIso8601String().substring(11, 16);
      await txn.insert(DatabaseTables.tableFollowUps, {
        'pet_id': pet3Id,
        'consultation_id': null,
        'scheduled_date': todayStr,
        'scheduled_time': alert3TimeStr,
        'reason': 'فحص الأسنان وتنظيف الجير بالموجات فوق الصوتية',
        'status': 'pending',
        'reminder_sent': 0,
        'notes': 'تقييم اللثة وتحديد موعد جلسة التلميع.',
      });
    });
  }
}
