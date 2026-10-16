import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vet_pulse/data/database/database_helper.dart';
import 'package:vet_pulse/data/database/database_tables.dart';
import 'package:vet_pulse/data/database/demo_data_seeder.dart';
import 'package:vet_pulse/data/models/follow_up_model.dart';
import 'package:vet_pulse/data/models/surgery_model.dart';
import 'package:vet_pulse/data/repositories/appointment_repository.dart';
import 'package:vet_pulse/data/repositories/auth_repository.dart';
import 'package:vet_pulse/data/repositories/pet_repository.dart';
import 'package:vet_pulse/data/repositories/surgery_repository.dart';
import 'package:vet_pulse/modules/surgeries/bindings/surgery_binding.dart';
import 'package:vet_pulse/modules/surgeries/controllers/complete_surgery_controller.dart';
import 'package:vet_pulse/modules/surgeries/controllers/surgery_follow_up_controller.dart';
import 'package:vet_pulse/modules/surgeries/controllers/surgery_form_controller.dart';
import 'package:vet_pulse/modules/surgeries/controllers/surgery_list_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    Get.testMode = true;
    await DemoDataSeeder.resetDemoData();
  });

  tearDown(() {
    Get.reset();
  });

  group('SurgeryBinding Tests', () {
    test('properly registers repositories and controllers', () {
      final binding = SurgeryBinding();
      binding.dependencies();

      expect(Get.isRegistered<SurgeryRepository>(), isTrue);
      expect(Get.isRegistered<PetRepository>(), isTrue);
      expect(Get.isRegistered<AuthRepository>(), isTrue);
      expect(Get.isRegistered<AppointmentRepository>(), isTrue);
      expect(Get.isRegistered<SurgeryListController>(), isTrue);
      expect(Get.isRegistered<SurgeryFormController>(), isTrue);
      expect(Get.isRegistered<CompleteSurgeryController>(), isTrue);
      expect(Get.isRegistered<SurgeryFollowUpController>(), isTrue);
    });
  });

  group('Surgery Financial Ledger Atomicity Tests', () {
    final surgeryRepo = SurgeryRepository();

    test('completeSurgeryWithBilling atomically records financial transactions and customer payments', () async {
      final db = await DatabaseHelper.instance.database;
      final petRows = await db.query(DatabaseTables.tablePets, limit: 1);
      final petId = petRows.first['id'] as int;

      final userRows = await db.query(DatabaseTables.tableUsers, limit: 1);
      final surgeonId = userRows.first['id'] as int;

      // 1. Insert a scheduled surgery
      final surgeryId = await surgeryRepo.insertSurgery(SurgeryModel(
        petId: petId,
        leadSurgeonId: surgeonId,
        scheduledDate: '2026-10-20 10:00 ص',
        surgeryName: 'استئصال ورم دهني حميد (Lipoma Excision)',
        surgeryCategory: 'جراحة أنسجة رخوة',
        estimatedCost: 45000.0,
      ));

      final insertedSurgery = await surgeryRepo.getSurgeryById(surgeryId);
      expect(insertedSurgery, isNotNull);
      expect(insertedSurgery!.status, equals('scheduled'));

      // 2. Complete the surgery with billing (45000 total, 25000 paid)
      final followUp = FollowUpModel(
        petId: petId,
        scheduledDate: '2026-10-27',
        scheduledTime: '11:00 ص',
        reason: 'معاينة مكان الجرح وفك الغرز',
        notes: 'إحضار الحيوان بعد 7 أيام',
      );

      final updatedModel = insertedSurgery.copyWith(
        status: 'completed',
        postOpNotes: 'تم الاستئصال بنجاح وإغلاق الجرح بغرز تجميلية',
        estimatedCost: 45000.0,
      );

      await surgeryRepo.completeSurgeryWithBilling(
        surgery: updatedModel,
        finalCost: 45000.0,
        paidAmount: 25000.0,
        paymentMethod: 'كريمي',
        followUp: followUp,
      );

      // 3. Verify surgery record updated
      final completedSurgery = await surgeryRepo.getSurgeryById(surgeryId);
      expect(completedSurgery!.status, equals('completed'));
      expect(completedSurgery.postOpNotes, contains('تم الاستئصال بنجاح'));

      // 4. Verify financial transaction in database
      final txRows = await db.query(
        DatabaseTables.tableTransactions,
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: ['surgery', surgeryId],
      );

      expect(txRows.length, equals(1));
      final tx = txRows.first;
      expect(tx['transaction_type'], equals('income'));
      expect(tx['category'], equals('surgery'));
      expect(tx['amount'], equals(45000.0));
      expect(tx['paid_amount'], equals(25000.0));
      expect(tx['remaining_amount'], equals(20000.0));
      expect(tx['payment_method'], equals('كريمي'));

      // 5. Verify customer payment recorded
      final paymentRows = await db.query(
        DatabaseTables.tableCustomerPayments,
        where: 'transaction_id = ?',
        whereArgs: [tx['id']],
      );

      expect(paymentRows.length, equals(1));
      final payment = paymentRows.first;
      expect(payment['amount'], equals(25000.0));
      expect(payment['payment_method'], equals('كريمي'));
      expect(payment['receipt_number'], equals('REC-SURG-$surgeryId-1'));

      // 6. Verify follow-up was created
      final followUpRows = await db.query(
        DatabaseTables.tableFollowUps,
        where: 'pet_id = ? AND scheduled_date = ?',
        whereArgs: [petId, '2026-10-27'],
      );
      expect(followUpRows.isNotEmpty, isTrue);
    });
  });

  group('Surgery Controllers Logic Tests', () {
    final surgeryRepo = SurgeryRepository();

    test('SurgeryListController loads surgeries and toggles checklist', () async {
      final listController = SurgeryListController(surgeryRepo);
      await listController.loadSurgeries();

      expect(listController.surgeries.isNotEmpty, isTrue);
      final first = listController.surgeries.first;
      final initialChecklist = first.preOpChecklistPassed;

      await listController.toggleChecklist(first);
      final updated = await surgeryRepo.getSurgeryById(first.id!);
      expect(updated!.preOpChecklistPassed, equals(!initialChecklist));

      listController.onClose();
    });

    test('SurgeryFollowUpController builds valid FollowUpModel', () {
      final followUpController = SurgeryFollowUpController();
      followUpController.onInit();

      expect(followUpController.needFollowUp.value, isTrue);
      expect(followUpController.followUpDateController.text.isNotEmpty, isTrue);

      final model = followUpController.buildFollowUp(1);
      expect(model, isNotNull);
      expect(model!.petId, equals(1));
      expect(model.reason, contains('معاينة'));

      followUpController.needFollowUp.value = false;
      expect(followUpController.buildFollowUp(1), isNull);

      followUpController.onClose();
    });
  });
}
