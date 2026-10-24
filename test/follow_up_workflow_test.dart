import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vet_pulse/data/database/database_helper.dart';
import 'package:vet_pulse/data/database/database_tables.dart';
import 'package:vet_pulse/data/models/follow_up_model.dart';
import 'package:vet_pulse/data/models/prescription_model.dart';
import 'package:vet_pulse/data/repositories/appointment_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Follow-Up Examination & Workflow Tests', () {
    late Database db;
    late AppointmentRepository appointmentRepo;
    int testPetId = 1;
    int testMedicineId = 1;

    setUp(() async {
      db = await DatabaseHelper.instance.database;
      appointmentRepo = AppointmentRepository();

      // Ensure a clean test owner and pet
      final ownerId = await db.insert(DatabaseTables.tableOwners, {
        'full_name': 'مربي تجريبي للمتابعة',
        'phone_primary': '777000111',
      });

      testPetId = await db.insert(DatabaseTables.tablePets, {
        'owner_id': ownerId,
        'name': 'بيكسل',
        'species': 'كلب',
      });

      // Insert test medicine with 10 units clinic stock
      testMedicineId = await db.insert(DatabaseTables.tableMedicines, {
        'trade_name': 'أمبيسيلين حقن',
        'scientific_name': 'Ampicillin',
        'form': 'حقن',
        'clinic_stock': 10,
        'warehouse_stock': 50,
        'expiry_date': '2027-12-31',
      });
    });

    test('completeFollowUpWithTreatment updates status, deducts stock, and records financial transaction atomically', () async {
      // 1. Insert pending follow-up
      final followUpId = await appointmentRepo.insertFollowUp(FollowUpModel(
        petId: testPetId,
        scheduledDate: DateTime.now().toIso8601String().substring(0, 10),
        scheduledTime: '11:00 ص',
        reason: 'إعطاء الجرعة الثانية ومتابعة الجرح',
        status: 'pending',
      ));

      final followUp = await appointmentRepo.getFollowUpById(followUpId);
      expect(followUp, isNotNull);
      expect(followUp!.status, equals('pending'));

      // 2. Complete follow-up with treatment
      final treatment = PrescriptionModel(
        consultationId: 0,
        medicineId: testMedicineId,
        customName: 'أمبيسيلين حقن',
        dosage: '1 مل',
        frequency: 'مرة واحدة',
        durationDays: 1,
        quantityDispensed: 2,
        isClinicAdministered: true,
        route: 'حقن عضل',
      );

      final nextFollowUp = FollowUpModel(
        petId: testPetId,
        scheduledDate: '2026-10-30',
        scheduledTime: '10:00 ص',
        reason: 'فك الغرز النهائية',
      );

      await appointmentRepo.completeFollowUpWithTreatment(
        followUp: followUp,
        clinicalNotes: 'الجرح ملتئم بصورة ممتازة ولا توجد التهابات',
        administeredTreatments: [treatment],
        followUpCost: 5000.0,
        paidAmount: 3000.0,
        remainingAmount: 2000.0,
        paymentMethod: 'نقدا',
        nextFollowUp: nextFollowUp,
      );

      // 3. Verify follow-up updated to completed
      final completed = await appointmentRepo.getFollowUpById(followUpId);
      expect(completed!.status, equals('completed'));
      expect(completed.notes, contains('الجرح ملتئم'));
      expect(completed.notes, contains('أمبيسيلين حقن'));

      // 4. Verify inventory deduction (10 - 2 = 8)
      final medRows = await db.query(
        DatabaseTables.tableMedicines,
        where: 'id = ?',
        whereArgs: [testMedicineId],
      );
      expect(medRows.first['clinic_stock'], equals(8));

      // 5. Verify financial transaction and customer payment
      final txRows = await db.query(
        DatabaseTables.tableTransactions,
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: ['follow_up', followUpId],
      );
      expect(txRows.length, equals(1));
      final tx = txRows.first;
      expect(tx['amount'], equals(5000.0));
      expect(tx['paid_amount'], equals(3000.0));
      expect(tx['remaining_amount'], equals(2000.0));

      final paymentRows = await db.query(
        DatabaseTables.tableCustomerPayments,
        where: 'transaction_id = ?',
        whereArgs: [tx['id']],
      );
      expect(paymentRows.length, equals(1));
      expect(paymentRows.first['amount'], equals(3000.0));
      expect(paymentRows.first['receipt_number'], equals('REC-FU-$followUpId-1'));

      // 6. Verify next follow-up created
      final nextRows = await db.query(
        DatabaseTables.tableFollowUps,
        where: 'pet_id = ? AND scheduled_date = ?',
        whereArgs: [testPetId, '2026-10-30'],
      );
      expect(nextRows.isNotEmpty, isTrue);
    });

    test('markFollowUpMissed updates status to missed and preserves history', () async {
      final followUpId = await appointmentRepo.insertFollowUp(FollowUpModel(
        petId: testPetId,
        scheduledDate: '2026-10-20',
        reason: 'متابعة ما بعد العملية',
        status: 'pending',
      ));

      await appointmentRepo.markFollowUpMissed(followUpId, missedNote: 'تغيب المربي لظروف السفر');

      final missed = await appointmentRepo.getFollowUpById(followUpId);
      expect(missed!.status, equals('missed'));
      expect(missed.statusDisplayArabic, equals('فائتة / لم يحضر'));
      expect(missed.notes, contains('تغيب المربي لظروف السفر'));
    });

    test('resumeFollowUpSchedule creates new consecutive appointments while keeping missed record', () async {
      final followUpId = await appointmentRepo.insertFollowUp(FollowUpModel(
        petId: testPetId,
        scheduledDate: '2026-10-20',
        reason: 'جلسة غسيل ومضاد حيوي',
        status: 'missed',
        notes: '[لم يحضر الموعد]',
      ));

      final missed = await appointmentRepo.getFollowUpById(followUpId);
      expect(missed, isNotNull);

      final newIds = await appointmentRepo.resumeFollowUpSchedule(
        missedFollowUp: missed!,
        newStartDate: '2026-10-25',
        scheduledTime: '04:00 م',
        newDaysCount: 3,
      );

      expect(newIds.length, equals(3));

      // Verify the missed record was updated to indicate resumption
      final updatedMissed = await appointmentRepo.getFollowUpById(followUpId);
      expect(updatedMissed!.notes, contains('تم استئناف الجدولة بتاريخ 2026-10-25'));

      // Verify new sessions exist
      final petFollowUps = await appointmentRepo.getFollowUpsForPet(testPetId);
      final resumedSessions = petFollowUps.where((f) => f.reason.contains('استئناف الجلسات')).toList();
      expect(resumedSessions.length, equals(3));
    });
  });
}
