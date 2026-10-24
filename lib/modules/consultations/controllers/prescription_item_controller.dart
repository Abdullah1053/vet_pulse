import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/dosage_calculator.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/models/prescription_model.dart';
import '../../../data/repositories/inventory_repository.dart';

class PrescriptionItemController extends GetxController {
  final InventoryRepository inventoryRepo;

  PrescriptionItemController({InventoryRepository? inventoryRepo})
      : inventoryRepo = inventoryRepo ??
            (Get.isRegistered<InventoryRepository>()
                ? Get.find<InventoryRepository>()
                : Get.put(InventoryRepository(), permanent: true));

  // Available medicines for clinic use
  final RxList<MedicineModel> availableMedicines = <MedicineModel>[].obs;

  // 1. In-Clinic Administered Injections & Treatments
  final RxList<PrescriptionModel> clinicTreatments = <PrescriptionModel>[].obs;
  final Rx<MedicineModel?> selectedClinicMed = Rx<MedicineModel?>(null);
  final clinicDoseController = TextEditingController();
  final clinicRouteController = TextEditingController(text: 'حقن عضلي (IM)');
  final clinicQtyController = TextEditingController(text: '1');
  final clinicNotesController = TextEditingController();

  // 2. Take-Home Prescriptions for Owner
  final RxList<PrescriptionModel> homePrescriptions = <PrescriptionModel>[].obs;
  final homeMedNameController = TextEditingController();
  final homeDosageController = TextEditingController();
  final homeFrequencyController = TextEditingController(text: 'مرتين يومياً');
  final homeDurationController = TextEditingController(text: '5');
  final homeInstructionsController = TextEditingController();

  // 3. Dosage Calculator
  final calcWeightController = TextEditingController();
  final calcDoseRateController = TextEditingController();
  final calcConcentrationController = TextEditingController();
  final RxDouble calculatedDose = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadMedicines();
  }

  Future<void> loadMedicines() async {
    final meds = await inventoryRepo.getAllMedicines();
    availableMedicines.assignAll(meds.where((m) => !m.isExpired));
  }

  void calculateDosage() {
    final w = double.tryParse(calcWeightController.text.trim()) ?? 0;
    final r = double.tryParse(calcDoseRateController.text.trim()) ?? 0;
    final c = double.tryParse(calcConcentrationController.text.trim()) ?? 0;

    final result = DosageCalculator.calculateDose(
      weightKg: w,
      doseRateMgPerKg: r,
      concentrationMgPerUnit: c,
    );
    calculatedDose.value = result ?? 0.0;
    if (result != null) {
      clinicDoseController.text = '$result مل';
    }
  }

  void addClinicTreatment() {
    final med = selectedClinicMed.value;
    if (med == null) {
      Get.snackbar(
        'تنبيه',
        'يرجى اختيار الدواء من صيدلية العيادة أولاً',
        backgroundColor: Colors.amber.shade100,
      );
      return;
    }

    final qty = int.tryParse(clinicQtyController.text.trim()) ?? 1;
    final dose = clinicDoseController.text.trim();

    if (dose.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يرجى تحديد الجرعة المعطاة بالعيادة',
        backgroundColor: Colors.amber.shade100,
      );
      return;
    }

    if (qty > med.clinicStock) {
      Get.snackbar(
        'تحذير رصيد',
        'الكمية المطلوبة ($qty) أكبر من رصيد رف العيادة (${med.clinicStock})',
        backgroundColor: Colors.orange.shade100,
      );
    }

    clinicTreatments.add(PrescriptionModel(
      consultationId: 0,
      medicineId: med.id,
      medicineName: med.tradeName,
      medicineForm: med.form,
      medicineConcentration: med.concentration,
      dosage: dose,
      frequency: 'جرعة بالعيادة فوري',
      durationDays: 1,
      quantityDispensed: qty,
      isClinicAdministered: true,
      route: clinicRouteController.text.trim(),
      instructions: clinicNotesController.text.trim().isEmpty
          ? 'إعطاء فوري بالعيادة'
          : clinicNotesController.text.trim(),
    ));

    selectedClinicMed.value = null;
    clinicDoseController.clear();
    clinicNotesController.clear();
    clinicQtyController.text = '1';
  }

  void removeClinicTreatment(int index) {
    if (index >= 0 && index < clinicTreatments.length) {
      clinicTreatments.removeAt(index);
    }
  }

  void addHomePrescription() {
    final name = homeMedNameController.text.trim();
    final dose = homeDosageController.text.trim();
    final freq = homeFrequencyController.text.trim();
    final days = int.tryParse(homeDurationController.text.trim()) ?? 5;

    if (name.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يرجى كتابة اسم الدواء للروشتة',
        backgroundColor: Colors.amber.shade100,
      );
      return;
    }

    if (dose.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يرجى تحديد الجرعة',
        backgroundColor: Colors.amber.shade100,
      );
      return;
    }

    homePrescriptions.add(PrescriptionModel(
      consultationId: 0,
      medicineId: null,
      customName: name,
      dosage: dose,
      frequency: freq.isEmpty ? 'حسب الإرشادات' : freq,
      durationDays: days,
      quantityDispensed: 1,
      isClinicAdministered: false,
      instructions: homeInstructionsController.text.trim(),
    ));

    homeMedNameController.clear();
    homeDosageController.clear();
    homeInstructionsController.clear();
    homeDurationController.text = '5';
  }

  void removeHomePrescription(int index) {
    if (index >= 0 && index < homePrescriptions.length) {
      homePrescriptions.removeAt(index);
    }
  }

  List<PrescriptionModel> buildAllPrescriptions() {
    return [...clinicTreatments, ...homePrescriptions];
  }

  @override
  void onClose() {
    clinicDoseController.dispose();
    clinicRouteController.dispose();
    clinicQtyController.dispose();
    clinicNotesController.dispose();

    homeMedNameController.dispose();
    homeDosageController.dispose();
    homeFrequencyController.dispose();
    homeDurationController.dispose();
    homeInstructionsController.dispose();

    calcWeightController.dispose();
    calcDoseRateController.dispose();
    calcConcentrationController.dispose();

    super.onClose();
  }
}
