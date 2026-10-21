import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/services/data_sync_service.dart';
import '../../../core/services/device_contact_service.dart';
import '../../../core/utils/yemeni_phone_validator.dart';
import '../../../data/models/owner_model.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/models/pet_weight_model.dart';
import '../../../data/repositories/pet_repository.dart';

class AddPatientController extends GetxController {
  final PetRepository _petRepo;
  final ImagePicker _picker = ImagePicker();

  AddPatientController([PetRepository? petRepo])
      : _petRepo = petRepo ??
            (Get.isRegistered<PetRepository>()
                ? Get.find<PetRepository>()
                : Get.put(PetRepository(), permanent: true));

  final RxList<OwnerModel> owners = <OwnerModel>[].obs;
  final RxBool isLoading = false.obs;

  // Patient Form Controllers
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

  // Edit Mode
  final RxBool isEditing = false.obs;
  final Rx<int?> editingPetId = Rx<int?>(null);

  // Owner Form Controllers
  final ownerNameController = TextEditingController();
  final ownerPhoneController = TextEditingController();
  final ownerAddressController = TextEditingController();
  final Rx<OwnerModel?> selectedExistingOwner = Rx<OwnerModel?>(null);
  final RxBool autoSaveContactToPhone = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadOwners();
    final args = Get.arguments;
    if (args is PetModel) {
      initEditPet(args);
    }
  }

  Future<void> loadOwners() async {
    final list = await _petRepo.getAllOwners();
    owners.assignAll(list);
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
      String ph = owner.phonePrimary;
      if (ph.startsWith('+967')) {
        ph = ph.substring(4).trim();
      } else if (ph.startsWith('967')) {
        ph = ph.substring(3).trim();
      }
      ownerPhoneController.text = ph;
      ownerAddressController.text = owner.address ?? '';
    }
  }

  String? validateAndFormatYemeniPhone(String rawPhone) {
    if (!YemeniPhoneValidator.isValid(rawPhone)) {
      return null;
    }
    return YemeniPhoneValidator.formatWithCountryCode(rawPhone);
  }

  Future<void> savePatient() async {
    if (isEditing.value) {
      await updatePet();
      return;
    }

    if (!await DemoConfig.canAddPatient()) {
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
      final formattedPhone = validateAndFormatYemeniPhone(oPhone);
      if (formattedPhone == null) {
        Get.snackbar(
          'رقم الهاتف غير صالح',
          'يجب أن يبدأ رقم هاتف المالك بـ (77، 78، 73، 70، 71) ويتكون من 9 أرقام',
          backgroundColor: Colors.amber.shade100,
          duration: const Duration(seconds: 4),
        );
        return;
      }
      final newOwner = OwnerModel(
        fullName: oName,
        phonePrimary: formattedPhone,
        address: ownerAddressController.text.trim(),
      );
      ownerId = await _petRepo.insertOwner(newOwner);

      if (autoSaveContactToPhone.value) {
        DeviceContactService.saveOwnerToContacts(
          name: oName,
          phone: formattedPhone,
        );
      }
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

    int ownerId = selectedExistingOwner.value?.id ?? 1;

    String? validatedPhone;
    if (ownerPhoneController.text.trim().isNotEmpty) {
      validatedPhone = validateAndFormatYemeniPhone(ownerPhoneController.text.trim());
      if (validatedPhone == null && selectedExistingOwner.value == null) {
        Get.snackbar(
          'رقم الهاتف غير صالح',
          'يجب أن يبدأ رقم هاتف المالك بـ (77، 78، 73، 70، 71) ويتكون من 9 أرقام',
          backgroundColor: Colors.amber.shade100,
          duration: const Duration(seconds: 4),
        );
        return;
      }
    }

    if (selectedExistingOwner.value == null && ownerNameController.text.trim().isNotEmpty) {
      final newOwner = OwnerModel(
        fullName: ownerNameController.text.trim(),
        phonePrimary: validatedPhone ?? ownerPhoneController.text.trim(),
        address: ownerAddressController.text.trim(),
      );
      ownerId = await _petRepo.insertOwner(newOwner);
      if (autoSaveContactToPhone.value) {
        DeviceContactService.saveOwnerToContacts(
          name: newOwner.fullName,
          phone: newOwner.phonePrimary,
        );
      }
    } else if (selectedExistingOwner.value != null && ownerPhoneController.text.trim().isNotEmpty) {
      final currentO = selectedExistingOwner.value!;
      await _petRepo.updateOwner(currentO.copyWith(
        fullName: ownerNameController.text.trim(),
        phonePrimary: validatedPhone ?? currentO.phonePrimary,
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
    DataSyncService.notifyPatientChanged(petId: editingPetId.value);
    clearForm();
    Get.back();
    Get.snackbar('تم', 'تم تحديث بيانات المريض بنجاح', backgroundColor: Colors.green.shade100);
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
    autoSaveContactToPhone.value = true;
  }

  @override
  void onClose() {
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
    super.onClose();
  }
}
