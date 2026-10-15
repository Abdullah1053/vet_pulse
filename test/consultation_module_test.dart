import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vet_pulse/data/database/demo_data_seeder.dart';
import 'package:vet_pulse/data/models/medicine_model.dart';
import 'package:vet_pulse/data/repositories/appointment_repository.dart';
import 'package:vet_pulse/data/repositories/auth_repository.dart';
import 'package:vet_pulse/data/repositories/consultation_repository.dart';
import 'package:vet_pulse/data/repositories/inventory_repository.dart';
import 'package:vet_pulse/data/repositories/pet_repository.dart';
import 'package:vet_pulse/data/repositories/surgery_repository.dart';
import 'package:vet_pulse/modules/consultations/controllers/consultation_detail_controller.dart';
import 'package:vet_pulse/modules/consultations/controllers/new_consultation_controller.dart';
import 'package:vet_pulse/modules/consultations/controllers/prescription_item_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    await DemoDataSeeder.resetDemoData();
  });

  group('PrescriptionItemController Tests', () {
    test('adds and removes home prescriptions properly', () {
      Get.reset();
      final controller = PrescriptionItemController(
        inventoryRepo: InventoryRepository(),
      );

      controller.homeMedNameController.text = 'أموكسيسيلين';
      controller.homeDosageController.text = '1 قرص';
      controller.homeFrequencyController.text = 'مرتين يومياً';
      controller.homeDurationController.text = '7';

      controller.addHomePrescription();

      expect(controller.homePrescriptions.length, equals(1));
      expect(controller.homePrescriptions.first.displayName, equals('أموكسيسيلين'));
      expect(controller.homePrescriptions.first.dosage, equals('1 قرص'));
      expect(controller.homePrescriptions.first.durationDays, equals(7));

      controller.removeHomePrescription(0);
      expect(controller.homePrescriptions.isEmpty, isTrue);

      controller.onClose();
    });

    test('adds and removes clinic treatments properly', () {
      Get.reset();
      final controller = PrescriptionItemController(
        inventoryRepo: InventoryRepository(),
      );

      final med = MedicineModel(
        id: 999,
        tradeName: 'حقنة مهدئ',
        scientificName: 'Sedative',
        form: 'Vial',
        concentration: '10mg/ml',
        clinicStock: 10,
        warehouseStock: 20,
        minStockAlert: 3,
        unitCostPrice: 100,
        unitSalePrice: 200,
        expiryDate: '2028-12-31',
      );

      controller.selectedClinicMed.value = med;
      controller.clinicDoseController.text = '2 مل';
      controller.clinicQtyController.text = '1';
      controller.clinicRouteController.text = 'حقن عضلي (IM)';

      controller.addClinicTreatment();

      expect(controller.clinicTreatments.length, equals(1));
      expect(controller.clinicTreatments.first.medicineName, equals('حقنة مهدئ'));
      expect(controller.clinicTreatments.first.isClinicAdministered, isTrue);

      controller.removeClinicTreatment(0);
      expect(controller.clinicTreatments.isEmpty, isTrue);

      controller.onClose();
    });

    test('calculates dosage accurately', () {
      Get.reset();
      final controller = PrescriptionItemController(
        inventoryRepo: InventoryRepository(),
      );

      controller.calcWeightController.text = '10'; // 10 kg
      controller.calcDoseRateController.text = '5'; // 5 mg/kg => 50 mg total
      controller.calcConcentrationController.text = '25'; // 25 mg/ml => 2 ml

      controller.calculateDosage();

      expect(controller.calculatedDose.value, equals(2.0));
      expect(controller.clinicDoseController.text, equals('2.0 مل'));

      controller.onClose();
    });
  });

  group('NewConsultationController Tests', () {
    test('calculates remaining amount dynamically', () {
      Get.reset();
      final rxController = PrescriptionItemController(
        inventoryRepo: InventoryRepository(),
      );
      final newConsultationController = NewConsultationController(
        consultationRepo: ConsultationRepository(),
        petRepo: PetRepository(),
        authRepo: AuthRepository(),
        surgeryRepo: SurgeryRepository(),
        appointmentRepo: AppointmentRepository(),
        prescriptionController: rxController,
      );

      newConsultationController.costController.text = '6000';
      newConsultationController.paidAmountController.text = '4000';
      newConsultationController.updateRemainingAmount();

      expect(newConsultationController.remainingAmount.value, equals(2000.0));

      newConsultationController.paidAmountController.text = '6000';
      newConsultationController.updateRemainingAmount();
      expect(newConsultationController.remainingAmount.value, equals(0.0));

      newConsultationController.onClose();
      rxController.onClose();
    });
  });

  group('ConsultationDetailController Tests', () {
    test('loads consultation by id correctly', () async {
      Get.reset();
      final controller = ConsultationDetailController(
        consultationRepo: ConsultationRepository(),
        petRepo: PetRepository(),
      );

      final all = await ConsultationRepository().getAllConsultations();
      if (all.isNotEmpty) {
        await controller.loadConsultation(all.first);
        expect(controller.consultation.value, isNotNull);
        expect(controller.consultation.value?.id, equals(all.first.id));
      }

      controller.onClose();
    });
  });
}
