import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/dosage_calculator.dart';
import '../../../data/models/clinic_model.dart';
import '../../../data/models/consultation_model.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/models/prescription_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/consultation_repository.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../routes/app_routes.dart';
import '../../auth/controllers/auth_controller.dart';

class ConsultationController extends GetxController {
  final ConsultationRepository _consultationRepo = ConsultationRepository();
  final InventoryRepository _inventoryRepo = InventoryRepository();
  final PetRepository _petRepo = PetRepository();
  final AuthRepository _authRepo = AuthRepository();

  final Rx<PetModel?> selectedPet = Rx<PetModel?>(null);
  final RxList<PetModel> allPets = <PetModel>[].obs;
  final RxList<MedicineModel> availableMedicines = <MedicineModel>[].obs;
  final Rx<ClinicModel?> clinicInfo = Rx<ClinicModel?>(null);

  final RxList<PrescriptionModel> prescriptionCart = <PrescriptionModel>[].obs;
  final RxBool isLoading = false.obs;

  // SOAP Inputs
  final tempController = TextEditingController();
  final heartRateController = TextEditingController();
  final symptomsController = TextEditingController(); // Subjective
  final findingsController = TextEditingController(); // Objective
  final diagnosisController = TextEditingController(); // Assessment
  final planController = TextEditingController(); // Plan
  final costController = TextEditingController(text: '100');

  // Dosage Calculator Modal Inputs
  final calcWeightController = TextEditingController();
  final calcDoseRateController = TextEditingController();
  final calcConcentrationController = TextEditingController();
  final RxDouble calculatedDose = 0.0.obs;

  // Add Medicine Form Inputs
  final Rx<MedicineModel?> selectedMedForRx = Rx<MedicineModel?>(null);
  final rxDosageController = TextEditingController();
  final rxFrequencyController = TextEditingController(text: 'مرتين يومياً');
  final rxDurationController = TextEditingController(text: '5');
  final rxQuantityController = TextEditingController(text: '1');
  final rxInstructionsController = TextEditingController();

  // Created Consultation for Preview
  final Rx<ConsultationModel?> lastCreatedConsultation = Rx<ConsultationModel?>(null);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is PetModel) {
      selectedPet.value = args;
      if (args.latestWeight != null) {
        calcWeightController.text = args.latestWeight.toString();
      }
    }
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      allPets.assignAll(await _petRepo.getAllPets());
      final meds = await _inventoryRepo.getAllMedicines();
      // Filter out completely expired or zero stock if needed, or keep valid ones
      availableMedicines.assignAll(meds.where((m) => !m.isExpired));
      clinicInfo.value = await _authRepo.getClinicInfo();
    } finally {
      isLoading.value = false;
    }
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
      rxDosageController.text = '$result مل';
    }
  }

  void addPrescriptionItem() {
    final med = selectedMedForRx.value;
    if (med == null) {
      Get.snackbar('تنبيه', 'يرجى اختيار الدواء أولاً', backgroundColor: Colors.amber.shade100);
      return;
    }

    final qty = int.tryParse(rxQuantityController.text.trim()) ?? 1;
    final duration = int.tryParse(rxDurationController.text.trim()) ?? 1;
    final dosage = rxDosageController.text.trim();
    final freq = rxFrequencyController.text.trim();

    if (dosage.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى كتابة الجرعة', backgroundColor: Colors.amber.shade100);
      return;
    }

    if (qty > med.clinicStock) {
      Get.snackbar('تحذير مخزون', 'الكمية المطلوبة ($qty) أكبر من رصيد رف العيادة (${med.clinicStock})',
          backgroundColor: Colors.orange.shade100);
    }

    prescriptionCart.add(PrescriptionModel(
      consultationId: 0,
      medicineId: med.id!,
      medicineName: med.tradeName,
      medicineForm: med.form,
      medicineConcentration: med.concentration,
      dosage: dosage,
      frequency: freq,
      durationDays: duration,
      quantityDispensed: qty,
      instructions: rxInstructionsController.text.trim(),
    ));

    // Clear rx inputs
    selectedMedForRx.value = null;
    rxDosageController.clear();
    rxInstructionsController.clear();
    rxQuantityController.text = '1';
  }

  void removePrescriptionItem(int index) {
    prescriptionCart.removeAt(index);
  }

  Future<void> saveConsultation() async {
    if (selectedPet.value == null) {
      Get.snackbar('تنبيه', 'يرجى اختيار المريض أولاً', backgroundColor: Colors.amber.shade100);
      return;
    }

    final diagnosis = diagnosisController.text.trim();
    if (diagnosis.isEmpty) {
      Get.snackbar('تنبيه', 'التشخيص الطبي (Assessment) مطلوب', backgroundColor: Colors.amber.shade100);
      return;
    }

    final auth = Get.find<AuthController>();
    final doctorId = auth.currentUser.value?.id ?? 1;

    isLoading.value = true;
    try {
      final consultation = ConsultationModel(
        petId: selectedPet.value!.id!,
        doctorId: doctorId,
        visitDate: DateTime.now().toIso8601String(),
        temperature: double.tryParse(tempController.text.trim()),
        heartRate: int.tryParse(heartRateController.text.trim()),
        symptoms: symptomsController.text.trim(),
        examinationFindings: findingsController.text.trim(),
        diagnosis: diagnosis,
        treatmentPlan: planController.text.trim(),
        visitCost: double.tryParse(costController.text.trim()) ?? 0.0,
        petName: selectedPet.value!.name,
        petSpecies: selectedPet.value!.species,
        ownerName: selectedPet.value!.ownerName,
        doctorName: auth.currentUser.value?.fullName ?? 'د. عبدالله خالد',
        prescriptions: List.from(prescriptionCart),
      );

      final id = await _consultationRepo.createConsultationWithPrescriptions(
        consultation: consultation,
        prescriptions: prescriptionCart,
      );

      final created = consultation.copyWith(id: id);
      lastCreatedConsultation.value = created;

      Get.snackbar('نجاح', 'تم تسجيل الكشف وصرف الأدوية من المخزون بنجاح',
          backgroundColor: Colors.green.shade100);

      // Navigate to printable prescription preview
      Get.offNamed(AppRoutes.prescriptionPreview, arguments: created);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    tempController.dispose();
    heartRateController.dispose();
    symptomsController.dispose();
    findingsController.dispose();
    diagnosisController.dispose();
    planController.dispose();
    costController.dispose();
    calcWeightController.dispose();
    calcDoseRateController.dispose();
    calcConcentrationController.dispose();
    rxDosageController.dispose();
    rxFrequencyController.dispose();
    rxDurationController.dispose();
    rxQuantityController.dispose();
    rxInstructionsController.dispose();
    super.onClose();
  }
}
