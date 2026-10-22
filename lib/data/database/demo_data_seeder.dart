import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/services/data_sync_service.dart';
import 'database_helper.dart';
import 'database_tables.dart';

class DemoDataSeeder {
  DemoDataSeeder._();

  /// Check if the database has any owners/pets or financial records; if not, seed realistic demo data.
  static Future<void> seedIfEmpty() async {
    try {
      final db = await DatabaseHelper.instance.database;
      await DatabaseHelper.instance.ensureAllTablesExist(db);

      final ownerCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.tableOwners}'),
      ) ?? 0;

      final txCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.tableTransactions}'),
      ) ?? 0;

      final consultCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.tableConsultations}'),
      ) ?? 0;

      // If owners, transactions, or consultations are missing, seed complete demo data so all financial reports and owner accounts are fully populated!
      if (ownerCount == 0 || txCount == 0 || consultCount == 0) {
        await resetDemoData();
      }
    } catch (e, stack) {
      debugPrint('DemoDataSeeder.seedIfEmpty non-fatal note: $e\n$stack');
    }
  }

  /// Reset all patient, consultation, surgery, and appointment data back to pristine demo state.
  static Future<void> resetDemoData() async {
    final db = await DatabaseHelper.instance.database;
    await DatabaseHelper.instance.ensureAllTablesExist(db);

    await db.execute('PRAGMA foreign_keys = OFF;');
    try {
      await db.transaction((txn) async {
        for (final table in [
          DatabaseTables.tableCustomerPayments,
          DatabaseTables.tableBackupLogs,
          DatabaseTables.tableTransactions,
          DatabaseTables.tableExpenses,
          DatabaseTables.tablePrescriptions,
          DatabaseTables.tableFollowUps,
          DatabaseTables.tableSurgeries,
          DatabaseTables.tableConsultations,
          DatabaseTables.tablePetWeights,
          DatabaseTables.tablePets,
          DatabaseTables.tableOwners,
        ]) {
          try {
            await txn.delete(table);
          } catch (e) {
            debugPrint('Note clearing table $table: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('Warning during reset cleanup: $e');
    } finally {
      await db.execute('PRAGMA foreign_keys = ON;');
    }

    await populateDemoData();
    DataSyncService.notifyAllChanged();

    if (Get.context != null) {
      Get.snackbar(
        'تم تهيئة البيانات التجريبية الشاملة',
        'تم تحميل سجلات العيادة المتكاملة (المرضى، الكشوفات، العمليات، وحسابات المربين المالية)',
        backgroundColor: Colors.teal.shade100,
        colorText: Colors.teal.shade900,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Insert realistic clinic data for demonstration, showcasing all financial and clinical features
  static Future<void> populateDemoData() async {
    final db = await DatabaseHelper.instance.database;
    await DatabaseHelper.instance.ensureAllTablesExist(db);

    await db.execute('PRAGMA foreign_keys = OFF;');
    try {
      final now = DateTime.now();

      final todayStr = now.toIso8601String().substring(0, 10);
      final yesterdayStr = now.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
      final recentDate2 = now.subtract(const Duration(days: 2)).toIso8601String().substring(0, 10);
      final pastDate3 = now.subtract(const Duration(days: 3)).toIso8601String().substring(0, 10);
      final pastDate5 = now.subtract(const Duration(days: 5)).toIso8601String().substring(0, 10);
      final pastDate7 = now.subtract(const Duration(days: 7)).toIso8601String().substring(0, 10);
      final pastDate8 = now.subtract(const Duration(days: 8)).toIso8601String().substring(0, 10);
      final pastDate10 = now.subtract(const Duration(days: 10)).toIso8601String().substring(0, 10);
      final pastDate12 = now.subtract(const Duration(days: 12)).toIso8601String().substring(0, 10);
      final pastDate14 = now.subtract(const Duration(days: 14)).toIso8601String().substring(0, 10);
      final pastDate30 = now.subtract(const Duration(days: 30)).toIso8601String().substring(0, 10);
      final pastDate60 = now.subtract(const Duration(days: 60)).toIso8601String().substring(0, 10);

      await db.transaction((txn) async {
        // Query active doctor id
        final userList = await txn.query(DatabaseTables.tableUsers, limit: 1);
        final doctorId = userList.isNotEmpty ? (userList.first['id'] as int) : 1;

        // Query active medicines
        final medList = await txn.query(DatabaseTables.tableMedicines);
        final med1Id = medList.isNotEmpty ? (medList[0]['id'] as int) : null;
        final med2Id = medList.length > 1 ? (medList[1]['id'] as int) : med1Id;
        final med3Id = medList.length > 2 ? (medList[2]['id'] as int) : med1Id;

        // 1. Owners
      final owner1Id = await txn.insert(DatabaseTables.tableOwners, {
        'full_name': 'م. أحمد يحيى الشامي',
        'phone_primary': '0777123456',
        'address': 'صنعاء - حدة - خلف بريد حدة',
      });

      final owner2Id = await txn.insert(DatabaseTables.tableOwners, {
        'full_name': 'د. ريم محمد باعباد',
        'phone_primary': '0771987654',
        'address': 'صنعاء - الحي الدبلوماسي',
      });

      final owner3Id = await txn.insert(DatabaseTables.tableOwners, {
        'full_name': 'أ. طارق عبدالكريم الحميري',
        'phone_primary': '0733556677',
        'address': 'صنعاء - شارع بغداد',
      });

      final owner4Id = await txn.insert(DatabaseTables.tableOwners, {
        'full_name': 'فاطمة خالد اليماني',
        'phone_primary': '0775112233',
        'address': 'صنعاء - شارع الستين الجنوبي',
      });

      final owner5Id = await txn.insert(DatabaseTables.tableOwners, {
        'full_name': 'م. نبيل عبدالله الصنعاني',
        'phone_primary': '0770334455',
        'address': 'صنعاء - الأصبحي - جولة الرعد',
      });

      final owner6Id = await txn.insert(DatabaseTables.tableOwners, {
        'full_name': 'سارة عادل العريقي',
        'phone_primary': '0772667788',
        'address': 'صنعاء - شارع الزبيري - بجوار المستشفى الجمهوري',
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

      final pet5Id = await txn.insert(DatabaseTables.tablePets, {
        'owner_id': owner5Id,
        'name': 'بوبي (Bobby)',
        'species': 'dog',
        'breed': 'هاسكي سيبيري (Siberian Husky)',
        'gender': 'male',
        'is_neutered': 1,
        'date_of_birth': '2022-03-12',
        'microchip_number': '981098555666777',
        'allergies': 'تحسس جلدي من بعض الشامبوهات العطرية',
      });

      final pet6Id = await txn.insert(DatabaseTables.tablePets, {
        'owner_id': owner6Id,
        'name': 'كيتي (Kitty)',
        'species': 'cat',
        'breed': 'هملايا (Himalayan)',
        'gender': 'female',
        'is_neutered': 0,
        'date_of_birth': '2024-02-14',
        'microchip_number': null,
        'allergies': 'لا توجد',
      });

      final pet7Id = await txn.insert(DatabaseTables.tablePets, {
        'owner_id': owner2Id,
        'name': 'بيلا (Bella)',
        'species': 'cat',
        'breed': 'شيرازي أبيض (White Persian)',
        'gender': 'female',
        'is_neutered': 1,
        'date_of_birth': '2023-09-01',
        'microchip_number': null,
        'allergies': 'لا توجد',
      });

      final pet8Id = await txn.insert(DatabaseTables.tablePets, {
        'owner_id': owner5Id,
        'name': 'ماكس (Max)',
        'species': 'dog',
        'breed': 'روتوايلر (Rottweiler)',
        'gender': 'male',
        'is_neutered': 0,
        'date_of_birth': '2021-12-05',
        'microchip_number': '981098444333222',
        'allergies': 'لا توجد',
      });

      // 3. Weight Tracking
      await txn.insert(DatabaseTables.tablePetWeights, {'pet_id': pet1Id, 'weight': 3.8, 'recorded_date': pastDate60});
      await txn.insert(DatabaseTables.tablePetWeights, {'pet_id': pet1Id, 'weight': 4.0, 'recorded_date': pastDate30});
      await txn.insert(DatabaseTables.tablePetWeights, {'pet_id': pet1Id, 'weight': 4.25, 'recorded_date': todayStr});

      await txn.insert(DatabaseTables.tablePetWeights, {'pet_id': pet2Id, 'weight': 27.0, 'recorded_date': pastDate60});
      await txn.insert(DatabaseTables.tablePetWeights, {'pet_id': pet2Id, 'weight': 28.5, 'recorded_date': todayStr});

      await txn.insert(DatabaseTables.tablePetWeights, {'pet_id': pet5Id, 'weight': 22.0, 'recorded_date': pastDate30});
      await txn.insert(DatabaseTables.tablePetWeights, {'pet_id': pet5Id, 'weight': 23.4, 'recorded_date': yesterdayStr});

      // 4. Consultations (SOAP)
      // Consultation 1 for Simba
      final consult1Id = await txn.insert(DatabaseTables.tableConsultations, {
        'pet_id': pet1Id,
        'doctor_id': doctorId,
        'visit_date': '$todayStr 10:30 ص',
        'temperature': 39.2,
        'heart_rate': 145,
        'symptoms': 'خمول متزايد، فقدان للشهية منذ يومين، وتقيؤ متكرر بعد شرب الماء.',
        'examination_findings': 'جفاف خفيف (Dehydration ~5%)، ألم طفيف عند جس البطن، الأغشية المخاطية وردية شاحبة، لا توجد كتل مجسوسة.',
        'diagnosis': 'التهاب معوي حاد خفيف (Acute Mild Gastroenteritis)',
        'treatment_plan': 'إعطاء محاليل وريدية داعمة، مضاد قيء حقناً في العيادة، ومضاد حيوي واسع الطيف بالفم للمنزل مع حمية هضمية (Gastrointestinal Diet).',
        'visit_cost': 6500.0,
        'paid_amount': 4000.0,
        'payment_method': 'نقدا',
      });

      await txn.insert(DatabaseTables.tablePrescriptions, {
        'consultation_id': consult1Id,
        'medicine_id': med1Id,
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
        'medicine_id': med2Id,
        'dosage': '0.4 ml',
        'frequency': 'مرة واحدة بالعيادة',
        'duration_days': 1,
        'quantity_dispensed': 1,
        'instructions': 'حُقنت بالعيادة لتسكين الألم وخفض الحرارة.',
        'is_clinic_administered': 1,
        'route': 'حقن عضلي (IM)',
      });

      // Consultation 2 for Rocky
      final consult2Id = await txn.insert(DatabaseTables.tableConsultations, {
        'pet_id': pet2Id,
        'doctor_id': doctorId,
        'visit_date': '$pastDate14 04:00 م',
        'temperature': 38.6,
        'heart_rate': 88,
        'symptoms': 'فحص دوري سنوي وتجديد جدول التطعيمات والوقاية من الطفيليات.',
        'examination_findings': 'الوزن مثالي، المعطف لامع، العيون والأذنان نظيفة، الأسنان خالية من التكلس، فحص القلب والتنفس طبيعي.',
        'diagnosis': 'فحص سريري سليم + تطعيم خماسي دوري (DHPPi Routine Booster)',
        'treatment_plan': 'إعطاء اللقاح تحت الجلد، وإعطاء جرعة وقائية ضد الديدان المعوية، وموعد الجرعة التنشيطية بعد 3 أسابيع.',
        'visit_cost': 8000.0,
        'paid_amount': 0.0,
        'payment_method': 'نقدا',
      });

      await txn.insert(DatabaseTables.tablePrescriptions, {
        'consultation_id': consult2Id,
        'medicine_id': med3Id,
        'dosage': 'قرص ونصف',
        'frequency': 'جرعة واحدة',
        'duration_days': 1,
        'quantity_dispensed': 2,
        'instructions': 'تكرار الجرعة بعد أسبوعين في المنزل.',
        'is_clinic_administered': 0,
        'route': 'عن طريق الفم (Oral)',
      });

      // Consultation 3 for Louza
      final consult3Id = await txn.insert(DatabaseTables.tableConsultations, {
        'pet_id': pet4Id,
        'doctor_id': doctorId,
        'visit_date': '$pastDate3 11:15 ص',
        'temperature': 38.8,
        'heart_rate': 130,
        'symptoms': 'إفرازات دمعية واحمرار في العين اليمنى مع حك متكرر بالقدم.',
        'examination_findings': 'احتقان بالملتحمة بدون قرحة قرنية واضحة، تفاعل الحدقة طبيعي.',
        'diagnosis': 'التهاب ملتحمة عيني خفيف (Cat Conjunctivitis)',
        'treatment_plan': 'قطرة عينية مضادة للالتهاب 3 مرات يومياً لمدة أسبوع، مع تنظيف العين بماء معقم.',
        'visit_cost': 5500.0,
        'paid_amount': 3500.0,
        'payment_method': 'جوالي',
      });

      await txn.insert(DatabaseTables.tablePrescriptions, {
        'consultation_id': consult3Id,
        'medicine_id': med1Id,
        'custom_name': 'قطرة توبراميسين عينية (Tobrex Eye Drops)',
        'dosage': 'قطرة واحدة في العين المصابة',
        'frequency': '3 مرات يومياً',
        'duration_days': 7,
        'quantity_dispensed': 1,
        'instructions': 'تنظيف الإفرازات قبل التقطير.',
        'is_clinic_administered': 0,
        'route': 'قطرة عينية (Ophthalmic)',
      });

      // Consultation 4 for Bobby
      final consult4Id = await txn.insert(DatabaseTables.tableConsultations, {
        'pet_id': pet5Id,
        'doctor_id': doctorId,
        'visit_date': '$yesterdayStr 05:30 م',
        'temperature': 38.5,
        'heart_rate': 92,
        'symptoms': 'رائحة فم كريهة وتراكم طبقة صفراء على الأضراس الخلفية.',
        'examination_findings': 'تكلس سني من الدرجة الثانية (Grade 2 Dental Calculus) والتهاب لثة خفيف حول الأضراس.',
        'diagnosis': 'تنظيف أسنان وإزالة الجير بالموجات فوق الصوتية (Ultrasonic Scaling)',
        'treatment_plan': 'تنظيف وتلميع الأسنان تحت مهدئ خفيف، وصرف جل مطهر للثة.',
        'visit_cost': 12000.0,
        'paid_amount': 12000.0,
        'payment_method': 'جيب',
      });

      // Consultation 5 for Kitty
      final consult5Id = await txn.insert(DatabaseTables.tableConsultations, {
        'pet_id': pet6Id,
        'doctor_id': doctorId,
        'visit_date': '$pastDate5 02:45 م',
        'temperature': 38.7,
        'heart_rate': 140,
        'symptoms': 'تطعيم سنوي ثلاثي دوري + فحص سريري وقص مخالب.',
        'examination_findings': 'الحالة العامة ممتازة، الوزن طبيعي، تم إعطاء اللقاح تحت الجلد.',
        'diagnosis': 'تطعيم سنوي وقائي ثلاثي للقطط (FVRCP Booster)',
        'treatment_plan': 'راحة لمدة 24 ساعة، وإعطاء فيتامينات مقوية للمناعة.',
        'visit_cost': 9000.0,
        'paid_amount': 9000.0,
        'payment_method': 'فلوسك',
      });

      // Consultation 6 for Bella
      final consult6Id = await txn.insert(DatabaseTables.tableConsultations, {
        'pet_id': pet7Id,
        'doctor_id': doctorId,
        'visit_date': '$pastDate8 03:20 م',
        'temperature': 38.9,
        'heart_rate': 135,
        'symptoms': 'حك شديد في الأذنين مع وجود إفرازات شمعية سوداء داكنة.',
        'examination_findings': 'فحص الأذن بالأوتوسكوب أظهر وجود حلم الأذن (Otodectes cynotis).',
        'diagnosis': 'عث الأذن الطفيلي (Ear Mites Infestation)',
        'treatment_plan': 'تنظيف مجرى السمع بالعيادة ووضع قطرة مضادة للطفيليات.',
        'visit_cost': 7500.0,
        'paid_amount': 7500.0,
        'payment_method': 'كريمي',
      });

      // Consultation 7 for Max
      final consult7Id = await txn.insert(DatabaseTables.tableConsultations, {
        'pet_id': pet8Id,
        'doctor_id': doctorId,
        'visit_date': '$pastDate12 11:00 ص',
        'temperature': 39.0,
        'heart_rate': 110,
        'symptoms': 'عرج حاد بالطرف الخلفي الأيمن بعد السقوط.',
        'examination_findings': 'تورم وألم عند ثني مفصل الركبة، تصوير شعاعي أكد كسر بسيط في عظم الفخذ.',
        'diagnosis': 'كسر مغلق في عظم الفخذ الأيمن (Closed Femoral Fracture)',
        'treatment_plan': 'تثبيت مؤقت بالجبيرة وجدولة عملية تثبيت جراحي للشريحة.',
        'visit_cost': 15000.0,
        'paid_amount': 10000.0,
        'payment_method': 'نقدا',
      });

      // 5. Surgeries
      // Completed Surgery 1 for Simba
      final pastSurgeryDate = pastDate7;
      await txn.insert(DatabaseTables.tableSurgeries, {
        'pet_id': pet1Id,
        'lead_surgeon_id': doctorId,
        'surgery_name': 'استئصال حصوات المثانة (Cystotomy)',
        'surgery_category': 'جراحة مسالك بولية',
        'scheduled_date': '$pastSurgeryDate 09:00 ص',
        'anesthesia_protocol': 'Premed: Dexmedetomidine + Butorphanol | Ind: Propofol | Maint: Isoflurane 1.8%',
        'pre_op_checklist_passed': 1,
        'status': 'completed',
        'post_op_notes': 'تم استخراج 3 حصوات كروية بنجاح وإرسالها للتحليل المخبري. خياطة جدار المثانة بطبقتين محكمتين، التعافي من التخدير سلس وطبيعي دون أي مضاعفات.',
        'estimated_cost': 35000.0,
      });

      // Completed Surgery 2 for Max
      final maxSurgeryDate = pastDate10;
      await txn.insert(DatabaseTables.tableSurgeries, {
        'pet_id': pet8Id,
        'lead_surgeon_id': doctorId,
        'surgery_name': 'تثبيت كسر عظم الفخذ بشرائح تيتانيوم (Femur Osteosynthesis)',
        'surgery_category': 'جراحة عظام ومفاصل',
        'scheduled_date': '$maxSurgeryDate 10:00 ص',
        'anesthesia_protocol': 'تخدير كلي استنشاقي مع تسكين متقدم مستمر (CRI Fentanyl)',
        'pre_op_checklist_passed': 1,
        'status': 'completed',
        'post_op_notes': 'تم تثبيت الكسر بنجاح تام وإجراء أشعة تأكيدية، استقرار العظم 100%.',
        'estimated_cost': 60000.0,
      });

      // Scheduled Surgery for Louza
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowStr = tomorrow.toIso8601String().substring(0, 10);
      await txn.insert(DatabaseTables.tableSurgeries, {
        'pet_id': pet4Id,
        'lead_surgeon_id': doctorId,
        'surgery_name': 'تعقيم وقائي للمبيض والرحم (Ovariohysterectomy)',
        'surgery_category': 'جراحة وقائية',
        'scheduled_date': '$tomorrowStr 11:00 ص',
        'anesthesia_protocol': 'تخدير استنشاقي Sevoflurane مع مراقبة حيوية كاملة (SPO2, ECG, Capnography)',
        'pre_op_checklist_passed': 1,
        'status': 'scheduled',
        'post_op_notes': 'تم إبلاغ المالك بالصيام التام عن الطعام لمدة 8 ساعات قبل العملية.',
        'estimated_cost': 22000.0,
      });

      // 6. Follow-up Appointments
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

      // 7. Clinic Expenses
      final exp1Id = await txn.insert(DatabaseTables.tableExpenses, {
        'title': 'فاتورة استهلاك الكهرباء والطاقة للعيادة',
        'category': 'operating',
        'amount': 65000.0,
        'expense_date': pastDate10,
        'notes': 'فاتورة شهرية مدفوعة نقداً',
      });

      final exp2Id = await txn.insert(DatabaseTables.tableExpenses, {
        'title': 'طلبية مستلزمات طبية وتخدير وشاش معقم',
        'category': 'medical_supplies',
        'amount': 120000.0,
        'expense_date': pastDate5,
        'notes': 'شراء مستلزمات الجراحة والتعقيم من شركة الأدوية الطبية',
      });

      final exp3Id = await txn.insert(DatabaseTables.tableExpenses, {
        'title': 'صيانة دورية ومعايرة جهاز السونار والمختبر',
        'category': 'maintenance',
        'amount': 30000.0,
        'expense_date': recentDate2,
        'notes': 'فحص دوري ومعايرة مجسات الموجات فوق الصوتية',
      });

      final exp4Id = await txn.insert(DatabaseTables.tableExpenses, {
        'title': 'طلبية أدوية ومضادات حيوية للصيدلية',
        'category': 'medicines',
        'amount': 85000.0,
        'expense_date': todayStr,
        'notes': 'تعزيز رصيد الصيدلية بالأدوية سريعة الحركة',
      });

      final exp5Id = await txn.insert(DatabaseTables.tableExpenses, {
        'title': 'اشتراك إنترنت فايبر مخصص للعيادة',
        'category': 'operating',
        'amount': 18000.0,
        'expense_date': pastDate14,
        'notes': 'اشتراك شهري للأرشفة السحابية والربط',
      });

      final exp6Id = await txn.insert(DatabaseTables.tableExpenses, {
        'title': 'إيجار ممر العيادة والمواقف الخاصة',
        'category': 'operating',
        'amount': 45000.0,
        'expense_date': pastDate30,
        'notes': 'إيجار مواقف سيارات العملاء',
      });

      final exp7Id = await txn.insert(DatabaseTables.tableExpenses, {
        'title': 'تطعيمات ولقاحات سنوية مستوردة للقطط والكلاب',
        'category': 'medicines',
        'amount': 52000.0,
        'expense_date': pastDate8,
        'notes': 'دفعة لقاحات خماسية وثلاثية مبردة',
      });

      // 8. Financial Transactions (Ledger)
      // Transaction 1: Simba Consultation (Partially paid: 4,000 paid, 2,500 remaining deferred)
      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'income',
        'category': 'consultation',
        'owner_id': owner1Id,
        'pet_id': pet1Id,
        'reference_id': consult1Id,
        'reference_type': 'consultation',
        'amount': 6500.0,
        'paid_amount': 4000.0,
        'remaining_amount': 2500.0,
        'payment_method': 'نقدا',
        'transaction_date': todayStr,
        'notes': 'كشف سريري - التهاب معوي حاد (مسدد جزئياً 4,000 والباقي آجل 2,500)',
      });

      // Transaction 2: Simba Surgery (Fully paid: 35,000 via Kuraimi)
      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'income',
        'category': 'surgery',
        'owner_id': owner1Id,
        'pet_id': pet1Id,
        'reference_id': 1,
        'reference_type': 'surgery',
        'amount': 35000.0,
        'paid_amount': 35000.0,
        'remaining_amount': 0.0,
        'payment_method': 'كريمي',
        'transaction_date': pastSurgeryDate,
        'notes': 'عملية استئصال حصوات المثانة (مسدد بالكامل عبر كريمي)',
      });

      // Transaction 3: Rocky Consultation (Unpaid/Deferred: 0 paid, 8,000 remaining deferred)
      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'income',
        'category': 'consultation',
        'owner_id': owner2Id,
        'pet_id': pet2Id,
        'reference_id': consult2Id,
        'reference_type': 'consultation',
        'amount': 8000.0,
        'paid_amount': 0.0,
        'remaining_amount': 8000.0,
        'payment_method': 'نقدا',
        'transaction_date': pastDate14,
        'notes': 'فحص دوري سنوي وتطعيم خماسي (مبلغ آجل مستحق بالكامل)',
      });

      // Transaction 4: Misho Pharmacy (Fully paid: 4,500 via Cash)
      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'income',
        'category': 'pharmacy',
        'owner_id': owner3Id,
        'pet_id': pet3Id,
        'reference_id': null,
        'reference_type': 'pharmacy',
        'amount': 4500.0,
        'paid_amount': 4500.0,
        'remaining_amount': 0.0,
        'payment_method': 'نقدا',
        'transaction_date': recentDate2,
        'notes': 'مستلزمات وفيتامينات شعر وأوميغا 3 (مسدد بالكامل)',
      });

      // Transaction 5: Louza Consultation (5,500 - Paid 3,500 via Jawali, Remaining 2,000)
      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'income',
        'category': 'consultation',
        'owner_id': owner4Id,
        'pet_id': pet4Id,
        'reference_id': consult3Id,
        'reference_type': 'consultation',
        'amount': 5500.0,
        'paid_amount': 3500.0,
        'remaining_amount': 2000.0,
        'payment_method': 'جوالي',
        'transaction_date': pastDate3,
        'notes': 'فحص عيون وعلاج تحسس قرنية (مسدد 3,500 عبر جوالي والباقي آجل 2,000)',
      });

      // Transaction 6: Bobby Dental (12,000 - Paid 12,000 via Jeeb)
      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'income',
        'category': 'consultation',
        'owner_id': owner5Id,
        'pet_id': pet5Id,
        'reference_id': consult4Id,
        'reference_type': 'consultation',
        'amount': 12000.0,
        'paid_amount': 12000.0,
        'remaining_amount': 0.0,
        'payment_method': 'جيب',
        'transaction_date': yesterdayStr,
        'notes': 'تنظيف أسنان وإزالة الجير بالموجات فوق الصوتية (مسدد عبر جيب)',
      });

      // Transaction 7: Kitty Vaccination (9,000 - Paid 9,000 via Floosak)
      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'income',
        'category': 'consultation',
        'owner_id': owner6Id,
        'pet_id': pet6Id,
        'reference_id': consult5Id,
        'reference_type': 'consultation',
        'amount': 9000.0,
        'paid_amount': 9000.0,
        'remaining_amount': 0.0,
        'payment_method': 'فلوسك',
        'transaction_date': pastDate5,
        'notes': 'تطعيم سنوي ثلاثي وقص مخالب (مسدد عبر فلوسك)',
      });

      // Transaction 8: Bella Ear Treatment (7,500 - Paid 7,500 via Kuraimi)
      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'income',
        'category': 'consultation',
        'owner_id': owner2Id,
        'pet_id': pet7Id,
        'reference_id': consult6Id,
        'reference_type': 'consultation',
        'amount': 7500.0,
        'paid_amount': 7500.0,
        'remaining_amount': 0.0,
        'payment_method': 'كريمي',
        'transaction_date': pastDate8,
        'notes': 'علاج عث الأذن وتنظيف مجرى السمع (مسدد عبر كريمي)',
      });

      // Transaction 9: Max Orthopedic Surgery (60,000 - Paid 60,000 via Kuraimi)
      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'income',
        'category': 'surgery',
        'owner_id': owner5Id,
        'pet_id': pet8Id,
        'reference_id': 2,
        'reference_type': 'surgery',
        'amount': 60000.0,
        'paid_amount': 60000.0,
        'remaining_amount': 0.0,
        'payment_method': 'كريمي',
        'transaction_date': maxSurgeryDate,
        'notes': 'تثبيت كسر عظم الفخذ بشرائح تيتانيوم (مسدد بالكامل عبر كريمي)',
      });

      // Transaction 10: Max Consultation & X-Ray (15,000 - Paid 10,000 Cash, Remaining 5,000)
      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'income',
        'category': 'consultation',
        'owner_id': owner5Id,
        'pet_id': pet8Id,
        'reference_id': consult7Id,
        'reference_type': 'consultation',
        'amount': 15000.0,
        'paid_amount': 10000.0,
        'remaining_amount': 5000.0,
        'payment_method': 'نقدا',
        'transaction_date': pastDate12,
        'notes': 'كشف سريري وتصوير شعاعي للكسر (دفعة 10,000 والباقي آجل 5,000)',
      });

      // Transaction 11: Bobby Pharmacy items (8,500 - Paid 8,500 via Jeeb)
      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'income',
        'category': 'pharmacy',
        'owner_id': owner5Id,
        'pet_id': pet5Id,
        'reference_id': null,
        'reference_type': 'pharmacy',
        'amount': 8500.0,
        'paid_amount': 8500.0,
        'remaining_amount': 0.0,
        'payment_method': 'جيب',
        'transaction_date': yesterdayStr,
        'notes': 'شامبو طبي ومحلول تنظيف أذن وبخاخ حشرات وقائي (مسدد عبر جيب)',
      });

      // Transaction 12: Simba Urinary Prescription Food (14,000 - Paid 14,000 via Kuraimi)
      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'income',
        'category': 'pharmacy',
        'owner_id': owner1Id,
        'pet_id': pet1Id,
        'reference_id': null,
        'reference_type': 'pharmacy',
        'amount': 14000.0,
        'paid_amount': 14000.0,
        'remaining_amount': 0.0,
        'payment_method': 'كريمي',
        'transaction_date': pastDate7,
        'notes': 'أغذية علاجية رويال كانين للمسالك البولية (مسدد عبر كريمي)',
      });

      // 9. Customer Payments & Receipt Vouchers (سندات القبض المستقلة لسداد الحسابات)
      final pay1Id = await txn.insert(DatabaseTables.tableCustomerPayments, {
        'owner_id': owner1Id,
        'transaction_id': null,
        'amount': 1000.0,
        'payment_method': 'نقدا',
        'payment_date': todayStr,
        'receipt_number': 'REC-PAY-101',
        'notes': 'سند قبض وتحصيل دفعة نقدية لحساب العميل (سداد جزئي من متبقي كشف سمبا)',
      });

      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'payment',
        'category': 'direct_payment',
        'owner_id': owner1Id,
        'pet_id': pet1Id,
        'reference_id': pay1Id,
        'reference_type': 'customer_payment',
        'amount': 1000.0,
        'paid_amount': 1000.0,
        'remaining_amount': 0.0,
        'payment_method': 'نقدا',
        'transaction_date': todayStr,
        'notes': 'سند قبض وتحصيل دفعة نقدية لحساب العميل (سند رقم: REC-PAY-101)',
      });

      final pay2Id = await txn.insert(DatabaseTables.tableCustomerPayments, {
        'owner_id': owner2Id,
        'transaction_id': null,
        'amount': 3000.0,
        'payment_method': 'كريمي',
        'payment_date': pastDate8,
        'receipt_number': 'REC-PAY-102',
        'notes': 'سند قبض وتحصيل عبر بنك الكريمي (سداد جزئي من مديونية كشف روكي)',
      });

      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'payment',
        'category': 'direct_payment',
        'owner_id': owner2Id,
        'pet_id': pet2Id,
        'reference_id': pay2Id,
        'reference_type': 'customer_payment',
        'amount': 3000.0,
        'paid_amount': 3000.0,
        'remaining_amount': 0.0,
        'payment_method': 'كريمي',
        'transaction_date': pastDate8,
        'notes': 'سند قبض وتحصيل عبر بنك الكريمي (سند رقم: REC-PAY-102)',
      });

      // Expense transactions in ledger
      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'expense',
        'category': 'operating',
        'owner_id': null,
        'pet_id': null,
        'reference_id': exp1Id,
        'reference_type': 'expense',
        'amount': 65000.0,
        'paid_amount': 65000.0,
        'remaining_amount': 0.0,
        'payment_method': 'نقدا',
        'transaction_date': pastDate10,
        'notes': 'فاتورة استهلاك الكهرباء والطاقة للعيادة',
      });

      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'expense',
        'category': 'medical_supplies',
        'owner_id': null,
        'pet_id': null,
        'reference_id': exp2Id,
        'reference_type': 'expense',
        'amount': 120000.0,
        'paid_amount': 120000.0,
        'remaining_amount': 0.0,
        'payment_method': 'نقدا',
        'transaction_date': pastDate5,
        'notes': 'طلبية مستلزمات طبية وتخدير وشاش معقم',
      });

      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'expense',
        'category': 'maintenance',
        'owner_id': null,
        'pet_id': null,
        'reference_id': exp3Id,
        'reference_type': 'expense',
        'amount': 30000.0,
        'paid_amount': 30000.0,
        'remaining_amount': 0.0,
        'payment_method': 'نقدا',
        'transaction_date': recentDate2,
        'notes': 'صيانة دورية ومعايرة جهاز السونار والمختبر',
      });

      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'expense',
        'category': 'medicines',
        'owner_id': null,
        'pet_id': null,
        'reference_id': exp4Id,
        'reference_type': 'expense',
        'amount': 85000.0,
        'paid_amount': 85000.0,
        'remaining_amount': 0.0,
        'payment_method': 'نقدا',
        'transaction_date': todayStr,
        'notes': 'طلبية أدوية ومضادات حيوية للصيدلية',
      });

      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'expense',
        'category': 'operating',
        'owner_id': null,
        'pet_id': null,
        'reference_id': exp5Id,
        'reference_type': 'expense',
        'amount': 18000.0,
        'paid_amount': 18000.0,
        'remaining_amount': 0.0,
        'payment_method': 'نقدا',
        'transaction_date': pastDate14,
        'notes': 'اشتراك إنترنت فايبر مخصص للعيادة',
      });

      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'expense',
        'category': 'operating',
        'owner_id': null,
        'pet_id': null,
        'reference_id': exp6Id,
        'reference_type': 'expense',
        'amount': 45000.0,
        'paid_amount': 45000.0,
        'remaining_amount': 0.0,
        'payment_method': 'نقدا',
        'transaction_date': pastDate30,
        'notes': 'إيجار ممر العيادة والمواقف الخاصة',
      });

      await txn.insert(DatabaseTables.tableTransactions, {
        'transaction_type': 'expense',
        'category': 'medicines',
        'owner_id': null,
        'pet_id': null,
        'reference_id': exp7Id,
        'reference_type': 'expense',
        'amount': 52000.0,
        'paid_amount': 52000.0,
        'remaining_amount': 0.0,
        'payment_method': 'نقدا',
        'transaction_date': pastDate8,
        'notes': 'تطعيمات ولقاحات سنوية مستوردة للقطط والكلاب',
      });
    });
    } finally {
      await db.execute('PRAGMA foreign_keys = ON;');
    }
  }
}
