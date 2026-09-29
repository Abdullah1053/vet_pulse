import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/utils/dosage_calculator.dart';
import '../../../data/models/clinic_model.dart';
import '../../../data/models/consultation_model.dart';
import '../../../data/models/follow_up_model.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/models/prescription_model.dart';
import '../../../data/models/surgery_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/consultation_repository.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../data/repositories/surgery_repository.dart';
import '../../../routes/app_routes.dart';
import '../../auth/controllers/auth_controller.dart';

class ConsultationController extends GetxController {
  final ConsultationRepository _consultationRepo = ConsultationRepository();
  final InventoryRepository _inventoryRepo = InventoryRepository();
  final PetRepository _petRepo = PetRepository();
  final AuthRepository _authRepo = AuthRepository();
  final SurgeryRepository _surgeryRepo = SurgeryRepository();
  final AppointmentRepository _appointmentRepo = AppointmentRepository();

  final Rx<PetModel?> selectedPet = Rx<PetModel?>(null);
  final RxList<PetModel> allPets = <PetModel>[].obs;
  final RxList<MedicineModel> availableMedicines = <MedicineModel>[].obs;
  final Rx<ClinicModel?> clinicInfo = Rx<ClinicModel?>(null);
  final RxList<UserModel> availableSurgeons = <UserModel>[].obs;

  final RxBool isLoading = false.obs;

  // SOAP Inputs
  final tempController = TextEditingController();
  final heartRateController = TextEditingController();
  final symptomsController = TextEditingController(); // Subjective
  final findingsController = TextEditingController(); // Objective
  final diagnosisController = TextEditingController(); // Assessment
  final planController = TextEditingController(); // Plan
  final costController = TextEditingController(text: '5000'); // Yemeni Rial

  // 1. In-Clinic Administered Injections & Treatments (deducted from pharmacy shelf stock)
  final RxList<PrescriptionModel> clinicTreatments = <PrescriptionModel>[].obs;
  final Rx<MedicineModel?> selectedClinicMed = Rx<MedicineModel?>(null);
  final clinicDoseController = TextEditingController();
  final clinicRouteController = TextEditingController(text: 'حقن عضلي (IM)');
  final clinicQtyController = TextEditingController(text: '1');
  final clinicNotesController = TextEditingController();

  // 2. Take-Home Prescriptions for the Owner (Freeform, not deducted from pharmacy stock)
  final RxList<PrescriptionModel> homePrescriptions = <PrescriptionModel>[].obs;
  final homeMedNameController = TextEditingController();
  final homeDosageController = TextEditingController();
  final homeFrequencyController = TextEditingController(text: 'مرتين يومياً');
  final homeDurationController = TextEditingController(text: '5');
  final homeInstructionsController = TextEditingController();

  // 3. Schedule Surgery Option
  final RxBool needSurgery = false.obs;
  final surgeryNameController = TextEditingController();
  final surgeryCategoryController = TextEditingController(text: AppStringsAr.categoryElective);
  final surgeryDateController = TextEditingController();
  final surgeryTimeController = TextEditingController(text: '09:00 ص');
  final Rx<UserModel?> selectedSurgeon = Rx<UserModel?>(null);
  final surgeryCostController = TextEditingController(text: '25000');
  final surgeryNotesController = TextEditingController();

  // 4. Consecutive Treatment Plan Option (e.g., 3 days of antibiotics at clinic)
  final RxBool needTreatmentPlan = false.obs;
  final planReasonController = TextEditingController(text: 'إبر مضادات حيوية ومتابعة بالعيادة');
  final planDaysController = TextEditingController(text: '3');
  final planTimeController = TextEditingController(text: '10:00 ص');
  final planStartDateController = TextEditingController();
  final planNotesController = TextEditingController();

  // Dosage Calculator Modal Inputs
  final calcWeightController = TextEditingController();
  final calcDoseRateController = TextEditingController();
  final calcConcentrationController = TextEditingController();
  final RxDouble calculatedDose = 0.0.obs;

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
    surgeryDateController.text = DateTime.now().add(const Duration(days: 2)).toIso8601String().substring(0, 10);
    planStartDateController.text = DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      allPets.assignAll(await _petRepo.getAllPets());
      final meds = await _inventoryRepo.getAllMedicines();
      availableMedicines.assignAll(meds.where((m) => !m.isExpired));
      clinicInfo.value = await _authRepo.getClinicInfo();

      final allUsers = await _authRepo.getAllUsers();
      availableSurgeons.assignAll(allUsers.where((u) => u.canPerformSurgeries));
      if (availableSurgeons.isNotEmpty) {
        selectedSurgeon.value = availableSurgeons.first;
      }
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
      clinicDoseController.text = '$result مل';
    }
  }

  // 1. Add Clinic Administered Treatment (Injections/Meds deducted from stock)
  void addClinicTreatment() {
    final med = selectedClinicMed.value;
    if (med == null) {
      Get.snackbar('تنبيه', 'يرجى اختيار الدواء من صيدلية العيادة أولاً', backgroundColor: Colors.amber.shade100);
      return;
    }

    final qty = int.tryParse(clinicQtyController.text.trim()) ?? 1;
    final dose = clinicDoseController.text.trim();

    if (dose.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى تحديد الجرعة المعطاة بالعيادة', backgroundColor: Colors.amber.shade100);
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
      instructions: clinicNotesController.text.trim().isEmpty ? 'إعطاء فوري بالعيادة' : clinicNotesController.text.trim(),
    ));

    selectedClinicMed.value = null;
    clinicDoseController.clear();
    clinicNotesController.clear();
    clinicQtyController.text = '1';
  }

  void removeClinicTreatment(int index) {
    clinicTreatments.removeAt(index);
  }

  // 2. Add Take-Home Prescription for Owner (Freeform, not deducted from stock)
  void addHomePrescription() {
    final name = homeMedNameController.text.trim();
    final dose = homeDosageController.text.trim();
    final freq = homeFrequencyController.text.trim();
    final days = int.tryParse(homeDurationController.text.trim()) ?? 5;

    if (name.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى كتابة اسم الدواء للروشتة', backgroundColor: Colors.amber.shade100);
      return;
    }

    if (dose.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى تحديد الجرعة', backgroundColor: Colors.amber.shade100);
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
    homePrescriptions.removeAt(index);
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
      // Combine clinic treatments and home prescriptions
      final allPrescriptions = <PrescriptionModel>[
        ...clinicTreatments,
        ...homePrescriptions,
      ];

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
        prescriptions: allPrescriptions,
      );

      final id = await _consultationRepo.createConsultationWithPrescriptions(
        consultation: consultation,
        prescriptions: allPrescriptions,
      );

      final created = consultation.copyWith(id: id);
      lastCreatedConsultation.value = created;

      // 1. Create surgery if requested
      if (needSurgery.value && surgeryNameController.text.trim().isNotEmpty) {
        final sDate = surgeryDateController.text.trim();
        final sTime = surgeryTimeController.text.trim();
        final fullDateTime = sDate.isNotEmpty
            ? '$sDate $sTime'
            : '${DateTime.now().add(const Duration(days: 2)).toIso8601String().substring(0, 10)} 09:00 ص';

        final surgery = SurgeryModel(
          petId: selectedPet.value!.id!,
          leadSurgeonId: selectedSurgeon.value?.id ?? doctorId,
          scheduledDate: fullDateTime,
          surgeryName: surgeryNameController.text.trim(),
          surgeryCategory: surgeryCategoryController.text.trim(),
          estimatedCost: double.tryParse(surgeryCostController.text.trim()) ?? 0.0,
          anesthesiaProtocol: 'بروتوكول عام وفق حالة الحيوان',
          postOpNotes: surgeryNotesController.text.trim(),
        );
        await _surgeryRepo.insertSurgery(surgery);
      }

      // 2. Create consecutive treatment plan follow-ups if requested
      if (needTreatmentPlan.value) {
        final days = int.tryParse(planDaysController.text.trim()) ?? 3;
        final startDateStr = planStartDateController.text.trim();
        DateTime startDate = DateTime.now().add(const Duration(days: 1));
        if (startDateStr.isNotEmpty) {
          final parsed = DateTime.tryParse(startDateStr);
          if (parsed != null) startDate = parsed;
        }

        for (int i = 0; i < days; i++) {
          final followUpDate = startDate.add(Duration(days: i)).toIso8601String().substring(0, 10);
          final dayLabel = ' (اليوم ${i + 1} من $days)';
          await _appointmentRepo.insertFollowUp(FollowUpModel(
            petId: selectedPet.value!.id!,
            consultationId: id,
            scheduledDate: followUpDate,
            scheduledTime: planTimeController.text.trim(),
            reason: '${planReasonController.text.trim()}$dayLabel',
            notes: planNotesController.text.trim(),
          ));
        }
      }

      Get.snackbar(
        'نجاح الكشف السريري',
        'تم تسجيل الكشف وصرف الأدوية وتحديث المخزون والمواعيد بنجاح',
        backgroundColor: Colors.green.shade100,
      );

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

    clinicDoseController.dispose();
    clinicRouteController.dispose();
    clinicQtyController.dispose();
    clinicNotesController.dispose();

    homeMedNameController.dispose();
    homeDosageController.dispose();
    homeFrequencyController.dispose();
    homeDurationController.dispose();
    homeInstructionsController.dispose();

    surgeryNameController.dispose();
    surgeryCategoryController.dispose();
    surgeryDateController.dispose();
    surgeryTimeController.dispose();
    surgeryCostController.dispose();
    surgeryNotesController.dispose();

    planReasonController.dispose();
    planDaysController.dispose();
    planTimeController.dispose();
    planStartDateController.dispose();
    planNotesController.dispose();

    super.onClose();
  }
}
