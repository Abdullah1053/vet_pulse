import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/data_sync_service.dart';
import '../../../data/models/consultation_model.dart';
import '../../../data/models/follow_up_model.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/models/pet_weight_model.dart';
import '../../../data/models/surgery_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/consultation_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../data/repositories/surgery_repository.dart';

class PatientDetailController extends GetxController {
  final PetRepository _petRepo;
  final ConsultationRepository _consultationRepo;
  final SurgeryRepository _surgeryRepo;
  final AppointmentRepository _appointmentRepo;

  PatientDetailController(
    this._petRepo,
    this._consultationRepo,
    this._surgeryRepo,
    this._appointmentRepo,
  );

  final Rx<PetModel?> selectedPet = Rx<PetModel?>(null);
  int? get petId => selectedPet.value?.id;

  final RxList<PetWeightModel> petWeights = <PetWeightModel>[].obs;
  final RxList<ConsultationModel> petConsultations = <ConsultationModel>[].obs;
  final RxList<SurgeryModel> petSurgeries = <SurgeryModel>[].obs;
  final RxList<FollowUpModel> petFollowUps = <FollowUpModel>[].obs;
  final RxBool isLoadingProfile = false.obs;

  final newWeightController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg != null) {
      loadPetFullProfile(arg);
    }
  }

  Future<void> loadPetFullProfile(dynamic arg) async {
    isLoadingProfile.value = true;
    try {
      PetModel? targetPet;
      if (arg is PetModel) {
        targetPet = arg;
      } else if (arg is int) {
        targetPet = await _petRepo.getPetById(arg);
      } else if (selectedPet.value != null) {
        targetPet = await _petRepo.getPetById(selectedPet.value!.id!);
      }

      if (targetPet != null) {
        selectedPet.value = targetPet;
        final petId = targetPet.id;
        if (petId != null) {
          final weightsFuture = _petRepo.getWeightsForPet(petId);
          final consultationsFuture = _consultationRepo.getConsultationsForPet(petId);
          final surgeriesFuture = _surgeryRepo.getSurgeriesForPet(petId);
          final followUpsFuture = _appointmentRepo.getFollowUpsForPet(petId);

          final results = await Future.wait([
            weightsFuture,
            consultationsFuture,
            surgeriesFuture,
            followUpsFuture,
          ]);

          petWeights.value = results[0] as List<PetWeightModel>;
          petConsultations.value = results[1] as List<ConsultationModel>;
          petSurgeries.value = results[2] as List<SurgeryModel>;
          petFollowUps.value = results[3] as List<FollowUpModel>;
        }
      }
    } catch (e) {
      debugPrint('[PatientDetailController] Error loading pet profile: $e');
    } finally {
      isLoadingProfile.value = false;
    }
  }

  Future<void> recordNewWeight() async {
    if (selectedPet.value == null || selectedPet.value!.id == null) return;
    final w = double.tryParse(newWeightController.text.trim());
    if (w == null || w <= 0) {
      Get.snackbar('تنبيه', 'يرجى إدخال وزن صالح', backgroundColor: Colors.amber.shade100);
      return;
    }

    final petId = selectedPet.value!.id!;
    await _petRepo.addWeight(PetWeightModel(
      petId: petId,
      weight: w,
      recordedDate: DateTime.now().toIso8601String().substring(0, 10),
    ));

    newWeightController.clear();
    petWeights.value = await _petRepo.getWeightsForPet(petId);
    DataSyncService.notifyPatientChanged(petId: petId);
    Get.back();
    Get.snackbar('تم', 'تم تسجيل الوزن في الملف السريري', backgroundColor: Colors.green.shade100);
  }

  Future<void> deletePet(int petId) async {
    await _petRepo.deletePet(petId);
    selectedPet.value = null;
    DataSyncService.notifyPatientChanged(petId: petId);
    Get.back(); // close dialog if open
    Get.back(); // close detail view
    Get.snackbar('تم الحذف', 'تم حذف ملف المريض وكافة بياناته المرتبطة', backgroundColor: Colors.green.shade100);
  }

  @override
  void onClose() {
    newWeightController.dispose();
    super.onClose();
  }
}
