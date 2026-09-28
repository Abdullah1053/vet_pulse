import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/consultation_model.dart';
import '../../../data/models/owner_model.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/models/pet_weight_model.dart';
import '../../../data/repositories/consultation_repository.dart';
import '../../../data/repositories/pet_repository.dart';

class PatientController extends GetxController {
  final PetRepository _petRepo = PetRepository();
  final ConsultationRepository _consultationRepo = ConsultationRepository();
  final ImagePicker _picker = ImagePicker();

  final RxList<PetModel> patients = <PetModel>[].obs;
  final RxList<OwnerModel> owners = <OwnerModel>[].obs;
  final Rx<PetModel?> selectedPet = Rx<PetModel?>(null);
  final RxList<PetWeightModel> petWeights = <PetWeightModel>[].obs;
  final RxList<ConsultationModel> petConsultations = <ConsultationModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxString selectedSpeciesFilter = 'الكل'.obs;

  final searchController = TextEditingController();

  // Add Patient Form Controllers
  final petNameController = TextEditingController();
  final speciesController = TextEditingController(text: 'قط');
  final breedController = TextEditingController();
  final microchipController = TextEditingController();
  final allergiesController = TextEditingController();
  final initialWeightController = TextEditingController();
  final RxString selectedGender = 'male'.obs;
  final RxBool isNeutered = false.obs;
  final Rx<String?> petPhotoPath = Rx<String?>(null);

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
    selectedPet.value = pet;
    if (pet.id != null) {
      petWeights.value = await _petRepo.getWeightsForPet(pet.id!);
      petConsultations.value = await _consultationRepo.getConsultationsForPet(pet.id!);
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

  Future<void> savePatient() async {
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

    final newPet = PetModel(
      ownerId: ownerId,
      name: pName,
      species: speciesController.text.trim(),
      breed: breedController.text.trim(),
      gender: selectedGender.value,
      isNeutered: isNeutered.value,
      microchipNumber: microchipController.text.trim(),
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
    Get.back();
    Get.snackbar('نجاح', 'تم تسجيل ملف المريض بنجاح', backgroundColor: Colors.green.shade100);
  }

  Future<void> recordNewWeight() async {
    if (selectedPet.value == null || selectedPet.value!.id == null) return;
    final w = double.tryParse(newWeightController.text.trim());
    if (w == null || w <= 0) {
      Get.snackbar('تنبيه', 'يرجى إدخال وزن صالح', backgroundColor: Colors.amber.shade100);
      return;
    }

    await _petRepo.addWeight(PetWeightModel(
      petId: selectedPet.value!.id!,
      weight: w,
      recordedDate: DateTime.now().toIso8601String().substring(0, 10),
    ));

    newWeightController.clear();
    petWeights.value = await _petRepo.getWeightsForPet(selectedPet.value!.id!);
    Get.back();
    Get.snackbar('تم', 'تم تسجيل الوزن في الملف السريري', backgroundColor: Colors.green.shade100);
  }

  void clearForm() {
    petNameController.clear();
    speciesController.text = 'قط';
    breedController.clear();
    microchipController.clear();
    allergiesController.clear();
    initialWeightController.clear();
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
    ownerNameController.dispose();
    ownerPhoneController.dispose();
    ownerAddressController.dispose();
    newWeightController.dispose();
    super.onClose();
  }
}
