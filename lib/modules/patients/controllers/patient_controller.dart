import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/consultation_model.dart';
import '../../../data/models/follow_up_model.dart';
import '../../../data/models/owner_model.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/models/pet_weight_model.dart';
import '../../../data/models/surgery_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/consultation_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../data/repositories/surgery_repository.dart';
import '../../../core/services/data_sync_service.dart';

class PatientController extends GetxController {
  final PetRepository _petRepo = PetRepository();
  final ConsultationRepository _consultationRepo = ConsultationRepository();
  final SurgeryRepository _surgeryRepo = SurgeryRepository();
  final AppointmentRepository _appointmentRepo = AppointmentRepository();
  final ImagePicker _picker = ImagePicker();

  final RxList<PetModel> patients = <PetModel>[].obs;
  final RxList<OwnerModel> owners = <OwnerModel>[].obs;
  final Rx<PetModel?> selectedPet = Rx<PetModel?>(null);
  final RxList<PetWeightModel> petWeights = <PetWeightModel>[].obs;
  final RxList<ConsultationModel> petConsultations = <ConsultationModel>[].obs;
  final RxList<SurgeryModel> petSurgeries = <SurgeryModel>[].obs;
  final RxList<FollowUpModel> petFollowUps = <FollowUpModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingProfile = false.obs;
  final RxString selectedSpeciesFilter = 'الكل'.obs;

  final searchController = TextEditingController();

  // Add/Edit Patient Form Controllers
  final petNameController = TextEditingController();
  final speciesController = TextEditingController(text: 'قط');
  final breedController = TextEditingController();
  final microchipController = TextEditingController();
  final allergiesController = TextEditingController();
  final initialWeightController = TextEditingController();
  final ageValueController = TextEditingController();
  final RxString selectedAgeUnit = 'سنوات'.obs;
  final RxBool hasMicrochip = false.obs;
  final RxString selectedGender = 'male'.obs;
  final RxBool isNeutered = false.obs;
  final Rx<String?> petPhotoPath = Rx<String?>(null);

  // Edit Pet Mode
  final RxBool isEditing = false.obs;
  final Rx<int?> editingPetId = Rx<int?>(null);

  // Owner Form Controllers
  final ownerNameController = TextEditingController();
  final ownerPhoneController = TextEditingController();
  final ownerAddressController = TextEditingController();
  final Rx<OwnerModel?> selectedExistingOwner = Rx<OwnerModel?>(null);

  // New Weight Controller
  final newWeightController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadPatients();
    loadOwners();
  }

  Future<void> loadPatients() async {
    isLoading.value = true;
    try {
      final list = await _petRepo.getAllPets();
      patients.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadOwners() async {
    final list = await _petRepo.getAllOwners();
    owners.assignAll(list);
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      loadPatients();
      return;
    }
    isLoading.value = true;
    try {
      final results = await _petRepo.searchPets(query);
      patients.assignAll(results);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectPet(PetModel pet) async {
    await loadPetFullProfile(pet);
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
      debugPrint('Error loading pet full profile: $e');
    } finally {
      isLoadingProfile.value = false;
    }
  }

  Future<void> pickPetPhoto(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file != null) {
        petPhotoPath.value = file.path;
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر التقاط أو اختيار الصورة: $e', backgroundColor: Colors.red.shade100);
    }
  }

  void clearPetPhoto() {
    petPhotoPath.value = null;
  }

  String? computeDobFromAge() {
    final val = int.tryParse(ageValueController.text.trim());
    if (val == null || val <= 0) return null;
    final now = DateTime.now();
    if (selectedAgeUnit.value == 'أشهر') {
      final dob = DateTime(now.year, now.month - val, now.day);
      return dob.toIso8601String().substring(0, 10);
    } else {
      final dob = DateTime(now.year - val, now.month, now.day);
      return dob.toIso8601String().substring(0, 10);
    }
  }

  void initEditPet(PetModel pet) async {
    isEditing.value = true;
    editingPetId.value = pet.id;
    petNameController.text = pet.name;
    speciesController.text = pet.species;
    breedController.text = pet.breed ?? '';
    selectedGender.value = pet.gender ?? 'male';
    isNeutered.value = pet.isNeutered;
    allergiesController.text = pet.allergies ?? '';
    petPhotoPath.value = pet.photoPath;

    if (pet.microchipNumber != null && pet.microchipNumber!.trim().isNotEmpty) {
      hasMicrochip.value = true;
      microchipController.text = pet.microchipNumber!;
    } else {
      hasMicrochip.value = false;
      microchipController.clear();
    }

    if (pet.dateOfBirth != null && pet.dateOfBirth!.trim().isNotEmpty) {
      final dob = DateTime.tryParse(pet.dateOfBirth!);
      if (dob != null) {
        final now = DateTime.now();
        int years = now.year - dob.year;
        int months = now.month - dob.month;
        if (now.day < dob.day) months--;
        if (months < 0) {
          years--;
          months += 12;
        }
        if (years > 0) {
          ageValueController.text = years.toString();
          selectedAgeUnit.value = 'سنوات';
        } else if (months > 0) {
          ageValueController.text = months.toString();
          selectedAgeUnit.value = 'أشهر';
        }
      }
    } else {
      ageValueController.clear();
    }

    final owner = await _petRepo.getOwnerById(pet.ownerId);
    if (owner != null) {
      selectedExistingOwner.value = owner;
      ownerNameController.text = owner.fullName;
      ownerPhoneController.text = owner.phonePrimary;
      ownerAddressController.text = owner.address ?? '';
    }
  }

  Future<void> savePatient() async {
    if (isEditing.value) {
      await updatePet();
      return;
    }

    final pName = petNameController.text.trim();
    final oName = ownerNameController.text.trim();
    final oPhone = ownerPhoneController.text.trim();

    if (pName.isEmpty) {
      Get.snackbar('تنبيه', 'اسم الحيوان مطلوب', backgroundColor: Colors.amber.shade100);
      return;
    }

    int ownerId;
    if (selectedExistingOwner.value != null) {
      ownerId = selectedExistingOwner.value!.id!;
    } else {
      if (oName.isEmpty || oPhone.isEmpty) {
        Get.snackbar('تنبيه', 'اسم المالك ورقم الهاتف مطلوبان', backgroundColor: Colors.amber.shade100);
        return;
      }
      final newOwner = OwnerModel(
        fullName: oName,
        phonePrimary: oPhone,
        address: ownerAddressController.text.trim(),
      );
      ownerId = await _petRepo.insertOwner(newOwner);
    }

    final dob = computeDobFromAge();

    final newPet = PetModel(
      ownerId: ownerId,
      name: pName,
      species: speciesController.text.trim(),
      breed: breedController.text.trim(),
      gender: selectedGender.value,
      isNeutered: isNeutered.value,
      dateOfBirth: dob,
      microchipNumber: hasMicrochip.value ? microchipController.text.trim() : null,
      photoPath: petPhotoPath.value,
      allergies: allergiesController.text.trim(),
    );

    final petId = await _petRepo.insertPet(newPet);

    // Initial weight if provided
    final weightVal = double.tryParse(initialWeightController.text.trim());
    if (weightVal != null && weightVal > 0) {
      await _petRepo.addWeight(PetWeightModel(
        petId: petId,
        weight: weightVal,
        recordedDate: DateTime.now().toIso8601String().substring(0, 10),
      ));
    }

    clearForm();
    await loadPatients();
    DataSyncService.notifyPatientChanged(petId: petId);
    Get.back();
    Get.snackbar('نجاح', 'تم تسجيل ملف المريض بنجاح', backgroundColor: Colors.green.shade100);
  }

  Future<void> updatePet() async {
    if (editingPetId.value == null) return;
    final pName = petNameController.text.trim();
    if (pName.isEmpty) {
      Get.snackbar('تنبيه', 'اسم الحيوان مطلوب', backgroundColor: Colors.amber.shade100);
      return;
    }

    int ownerId = selectedExistingOwner.value?.id ?? selectedPet.value?.ownerId ?? 1;

    // If owner info was changed and no existing owner was picked
    if (selectedExistingOwner.value == null && ownerNameController.text.trim().isNotEmpty) {
      final newOwner = OwnerModel(
        fullName: ownerNameController.text.trim(),
        phonePrimary: ownerPhoneController.text.trim(),
        address: ownerAddressController.text.trim(),
      );
      ownerId = await _petRepo.insertOwner(newOwner);
    } else if (selectedExistingOwner.value != null && ownerPhoneController.text.trim().isNotEmpty) {
      // update owner phone/address if edited
      final currentO = selectedExistingOwner.value!;
      await _petRepo.updateOwner(currentO.copyWith(
        fullName: ownerNameController.text.trim(),
        phonePrimary: ownerPhoneController.text.trim(),
        address: ownerAddressController.text.trim(),
      ));
    }

    final dob = computeDobFromAge();

    final updated = PetModel(
      id: editingPetId.value,
      ownerId: ownerId,
      name: pName,
      species: speciesController.text.trim(),
      breed: breedController.text.trim(),
      gender: selectedGender.value,
      isNeutered: isNeutered.value,
      dateOfBirth: dob,
      microchipNumber: hasMicrochip.value ? microchipController.text.trim() : null,
      photoPath: petPhotoPath.value,
      allergies: allergiesController.text.trim(),
    );

    await _petRepo.updatePet(updated);
    final refreshed = await _petRepo.getPetById(editingPetId.value!);
    if (refreshed != null) {
      selectedPet.value = refreshed;
    }
    await loadPatients();
    DataSyncService.notifyPatientChanged(petId: editingPetId.value);
    clearForm();
    Get.back();
    Get.snackbar('تم', 'تم تحديث بيانات المريض بنجاح', backgroundColor: Colors.green.shade100);
  }

  Future<void> deletePet(int petId) async {
    await _petRepo.deletePet(petId);
    selectedPet.value = null;
    await loadPatients();
    DataSyncService.notifyPatientChanged(petId: petId);
    Get.back(); // close dialog if open
    Get.back(); // close detail view
    Get.snackbar('تم الحذف', 'تم حذف ملف المريض وكافة بياناته المرتبطة', backgroundColor: Colors.green.shade100);
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

  void clearForm() {
    isEditing.value = false;
    editingPetId.value = null;
    petNameController.clear();
    speciesController.text = 'قط';
    breedController.clear();
    microchipController.clear();
    allergiesController.clear();
    initialWeightController.clear();
    ageValueController.clear();
    selectedAgeUnit.value = 'سنوات';
    hasMicrochip.value = false;
    ownerNameController.clear();
    ownerPhoneController.clear();
    ownerAddressController.clear();
    selectedExistingOwner.value = null;
    selectedGender.value = 'male';
    isNeutered.value = false;
    petPhotoPath.value = null;
  }

  @override
  void onClose() {
    searchController.dispose();
    petNameController.dispose();
    speciesController.dispose();
    breedController.dispose();
    microchipController.dispose();
    allergiesController.dispose();
    initialWeightController.dispose();
    ageValueController.dispose();
    ownerNameController.dispose();
    ownerPhoneController.dispose();
    ownerAddressController.dispose();
    newWeightController.dispose();
    super.onClose();
  }
}
