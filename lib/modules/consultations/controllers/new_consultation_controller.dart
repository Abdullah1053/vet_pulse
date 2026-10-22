import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/constants/app_payment_methods.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/services/data_sync_service.dart';
import '../../../data/models/clinic_model.dart';
import '../../../data/models/consultation_model.dart';
import '../../../data/models/follow_up_model.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/models/surgery_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/consultation_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../data/repositories/surgery_repository.dart';
import '../../../routes/app_routes.dart';
import '../../auth/controllers/auth_controller.dart';
import 'prescription_item_controller.dart';

class NewConsultationController extends GetxController {
  final ConsultationRepository consultationRepo;
  final PetRepository petRepo;
  final AuthRepository authRepo;
  final SurgeryRepository surgeryRepo;
  final AppointmentRepository appointmentRepo;
  final PrescriptionItemController prescriptionController;

  NewConsultationController({
    ConsultationRepository? consultationRepo,
    PetRepository? petRepo,
    AuthRepository? authRepo,
    SurgeryRepository? surgeryRepo,
    AppointmentRepository? appointmentRepo,
    PrescriptionItemController? prescriptionController,
  })  : consultationRepo = consultationRepo ?? Get.find<ConsultationRepository>(),
        petRepo = petRepo ?? Get.find<PetRepository>(),
        authRepo = authRepo ?? Get.find<AuthRepository>(),
        surgeryRepo = surgeryRepo ?? Get.find<SurgeryRepository>(),
        appointmentRepo = appointmentRepo ?? Get.find<AppointmentRepository>(),
        prescriptionController = prescriptionController ?? Get.find<PrescriptionItemController>();

  final Rx<PetModel?> selectedPet = Rx<PetModel?>(null);
  final RxList<PetModel> allPets = <PetModel>[].obs;
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

  // Financial Settlement
  final costController = TextEditingController(text: '5000'); // Yemeni Rial
  final paidAmountController = TextEditingController(text: '5000');
  final RxDouble remainingAmount = 0.0.obs;
  final RxString selectedPaymentMethod = AppPaymentMethods.cash.obs;
  final RxBool showCostInPrescription = true.obs;

  bool get isDeferredPayment => selectedPaymentMethod.value == AppPaymentMethods.deferred;

  void setPaymentMethod(String method) {
    final oldMethod = selectedPaymentMethod.value;
    selectedPaymentMethod.value = method;
    if (method == AppPaymentMethods.deferred) {
      paidAmountController.text = '0';
      updateRemainingAmount();
    } else if (oldMethod == AppPaymentMethods.deferred) {
      if (paidAmountController.text.trim() == '0' || paidAmountController.text.trim() == '0.0') {
        paidAmountController.text = costController.text.trim();
      }
      updateRemainingAmount();
    }
  }

  // Surgery Option
  final RxBool needSurgery = false.obs;
  final surgeryNameController = TextEditingController();
  final surgeryCategoryController = TextEditingController(text: AppStringsAr.categoryElective);
  final surgeryDateController = TextEditingController();
  final surgeryTimeController = TextEditingController(text: '09:00 ص');
  final Rx<UserModel?> selectedSurgeon = Rx<UserModel?>(null);
  final surgeryCostController = TextEditingController(text: '25000');
  final surgeryNotesController = TextEditingController();

  // Consecutive Treatment Plan Option
  final RxBool needTreatmentPlan = false.obs;
  final planReasonController = TextEditingController(text: 'إبر مضادات حيوية ومتابعة بالعيادة');
  final planDaysController = TextEditingController(text: '3');
  final planTimeController = TextEditingController(text: '10:00 ص');
  final planStartDateController = TextEditingController();
  final planNotesController = TextEditingController();

  // Created Consultation for Preview
  final Rx<ConsultationModel?> lastCreatedConsultation = Rx<ConsultationModel?>(null);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is PetModel) {
      selectedPet.value = args;
      if (args.latestWeight != null) {
        prescriptionController.calcWeightController.text = args.latestWeight.toString();
      }
    } else if (args is int) {
      _loadPetById(args);
    }

    surgeryDateController.text =
        DateTime.now().add(const Duration(days: 2)).toIso8601String().substring(0, 10);
    planStartDateController.text =
        DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);

    costController.addListener(updateRemainingAmount);
    paidAmountController.addListener(updateRemainingAmount);
    updateRemainingAmount();
    loadData();
  }

  Future<void> _loadPetById(int petId) async {
    try {
      final pet = await petRepo.getPetById(petId);
      if (pet != null) {
        selectedPet.value = pet;
        if (pet.latestWeight != null) {
          prescriptionController.calcWeightController.text = pet.latestWeight.toString();
        }
      }
    } catch (e) {
      debugPrint('Error loading pet by id in NewConsultationController: $e');
    }
  }

  void updateRemainingAmount() {
    final cost = double.tryParse(costController.text.trim()) ?? 0.0;
    if (isDeferredPayment) {
      remainingAmount.value = cost;
      return;
    }
    final paid = double.tryParse(paidAmountController.text.trim()) ?? 0.0;
    remainingAmount.value = (cost - paid).clamp(0.0, double.infinity);
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final pets = await petRepo.getAllPets();
      allPets.assignAll(pets);

      // If selectedPet is still null and petId was passed via arguments, match from allPets
      if (selectedPet.value == null && Get.arguments is int) {
        final petId = Get.arguments as int;
        final match = pets.cast<PetModel?>().firstWhere((p) => p?.id == petId, orElse: () => null);
        if (match != null) {
          selectedPet.value = match;
          if (match.latestWeight != null) {
            prescriptionController.calcWeightController.text = match.latestWeight.toString();
          }
        }
      }

      clinicInfo.value = await authRepo.getClinicInfo();

      final allUsers = await authRepo.getAllUsers();
      availableSurgeons.assignAll(allUsers.where((u) => u.canPerformSurgeries));
      if (availableSurgeons.isNotEmpty) {
        selectedSurgeon.value = availableSurgeons.first;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveConsultation() async {
    if (!await DemoConfig.canAddConsultation()) {
      return;
    }

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
      final allPrescriptions = prescriptionController.buildAllPrescriptions();

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
        paidAmount: isDeferredPayment ? 0.0 : (double.tryParse(paidAmountController.text.trim()) ?? 0.0),
        paymentMethod: selectedPaymentMethod.value,
        petName: selectedPet.value!.name,
        petSpecies: selectedPet.value!.species,
        ownerName: selectedPet.value!.ownerName,
        ownerId: selectedPet.value!.ownerId,
        doctorName: auth.currentUser.value?.fullName ?? 'د. عبدالله خالد',
        prescriptions: allPrescriptions,
      );

      final id = await consultationRepo.createConsultationWithPrescriptions(
        consultation: consultation,
        prescriptions: allPrescriptions,
      );

      final created = consultation.copyWith(id: id);
      lastCreatedConsultation.value = created;

      SurgeryModel? createdSurgery;
      final List<FollowUpModel> createdFollowUps = [];

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
          surgeonName: selectedSurgeon.value?.fullName ?? auth.currentUser.value?.fullName,
          petName: selectedPet.value?.name,
          petSpecies: selectedPet.value?.species,
        );
        final surgeryId = await surgeryRepo.insertSurgery(surgery);
        createdSurgery = surgery.copyWith(id: surgeryId);
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
          final followUpDate =
              startDate.add(Duration(days: i)).toIso8601String().substring(0, 10);
          final dayLabel = ' (اليوم ${i + 1} من $days)';
          final followUp = FollowUpModel(
            petId: selectedPet.value!.id!,
            consultationId: id,
            scheduledDate: followUpDate,
            scheduledTime: planTimeController.text.trim(),
            reason: '${planReasonController.text.trim()}$dayLabel',
            notes: planNotesController.text.trim(),
            petName: selectedPet.value?.name,
            petSpecies: selectedPet.value?.species,
          );
          final followUpId = await appointmentRepo.insertFollowUp(followUp);
          createdFollowUps.add(followUp.copyWith(id: followUpId));
        }
      }

      // Wrap sync in try-catch so listener issues never block navigation
      try {
        DataSyncService.notifyConsultationChanged(petId: selectedPet.value!.id!);
      } catch (syncErr) {
        debugPrint('Sync listener error ignored during consultation save: $syncErr');
      }

      // Execute navigation FIRST
      await Get.offNamed(
        AppRoutes.prescriptionPreview,
        arguments: {
          'consultation': created,
          'showCost': showCostInPrescription.value,
          'scheduledSurgery': createdSurgery,
          'followUpSessions': createdFollowUps,
        },
      );

      // Trigger snackbar AFTER route transition starts
      Get.snackbar(
        'نجاح الكشف السريري',
        'تم حفظ الكشف السريري بنجاح',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
    } catch (e, stack) {
      debugPrint('Error saving consultation: $e\n$stack');
      Get.snackbar(
        'خطأ في الحفظ',
        'تعذر حفظ الكشف السريري: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    costController.removeListener(updateRemainingAmount);
    paidAmountController.removeListener(updateRemainingAmount);

    tempController.dispose();
    heartRateController.dispose();
    symptomsController.dispose();
    findingsController.dispose();
    diagnosisController.dispose();
    planController.dispose();

    costController.dispose();
    paidAmountController.dispose();

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
