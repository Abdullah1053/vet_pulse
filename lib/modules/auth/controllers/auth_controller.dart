import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/yemeni_phone_validator.dart';
import '../../../data/models/clinic_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepo;

  AuthController([AuthRepository? authRepo]) : _authRepo = authRepo ?? AuthRepository();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final Rx<ClinicModel?> clinicInfo = Rx<ClinicModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLocked = false.obs;
  final RxString pinLockInput = ''.obs;

  // Password visibility toggle for LoginView
  final RxBool isPasswordHidden = true.obs;
  void togglePasswordVisibility() => isPasswordHidden.value = !isPasswordHidden.value;

  /// RBAC Permission checking helper
  bool checkPermission(bool Function(UserModel u) check, String deniedMessage) {
    final user = currentUser.value;
    if (user == null || user.isLeadDoctor) return true;
    if (!check(user)) {
      Get.snackbar(
        'صلاحية غير كافية',
        deniedMessage,
        backgroundColor: Colors.amber.shade100,
        colorText: Colors.black87,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.lock_outline, color: Colors.orange),
      );
      return false;
    }
    return true;
  }

  // Clinic Logo observable
  final RxnString clinicLogoPath = RxnString();

  // Controllers for login
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final pinController = TextEditingController();

  // Controllers for clinic setup
  final clinicNameController = TextEditingController();
  final doctorNameController = TextEditingController();
  final licenseController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadClinicInfo();
  }

  Future<void> loadClinicInfo() async {
    clinicInfo.value = await _authRepo.getClinicInfo();
    if (clinicInfo.value != null) {
      clinicNameController.text = clinicInfo.value!.clinicName;
      doctorNameController.text = clinicInfo.value!.doctorName;
      licenseController.text = clinicInfo.value!.licenseNumber ?? '';
      phoneController.text = YemeniPhoneValidator.cleanDigits(clinicInfo.value!.phone ?? '');
      addressController.text = clinicInfo.value!.address ?? '';
      clinicLogoPath.value = clinicInfo.value!.logoPath;
    }
  }

  Future<void> pickClinicLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        clinicLogoPath.value = picked.path;
      }
    } catch (e) {
      debugPrint('Error picking clinic logo: $e');
    }
  }

  void removeClinicLogo() {
    clinicLogoPath.value = null;
  }

  Future<void> login() async {
    final user = usernameController.text.trim();
    final pass = passwordController.text;

    if (user.isEmpty || pass.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى إدخال اسم المستخدم وكلمة المرور',
          backgroundColor: Colors.amber.shade100, colorText: Colors.black87);
      return;
    }

    isLoading.value = true;
    try {
      final userModel = await _authRepo.login(user, pass);
      if (userModel != null) {
        currentUser.value = userModel;
        usernameController.clear();
        passwordController.clear();
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        Get.snackbar('خطأ', 'اسم المستخدم أو كلمة المرور غير صحيحة',
            backgroundColor: Colors.red.shade100, colorText: Colors.red.shade900);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> unlockWithPin(String pin) async {
    if (pin.length < 4) return;
    isLoading.value = true;
    try {
      final userModel = await _authRepo.loginWithPin(pin);
      if (userModel != null) {
        currentUser.value = userModel;
        isLocked.value = false;
        pinController.clear();
        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        Get.snackbar('خطأ', 'رمز PIN غير صحيح',
            backgroundColor: Colors.red.shade100, colorText: Colors.red.shade900);
        pinController.clear();
      }
    } finally {
      isLoading.value = false;
    }
  }

  void onPinKeyPress(String digit) {
    if (pinLockInput.value.length < 4) {
      pinLockInput.value += digit;
      if (pinLockInput.value.length == 4) {
        final entered = pinLockInput.value;
        pinLockInput.value = '';
        unlockWithPin(entered);
      }
    }
  }

  void onPinBackspace() {
    if (pinLockInput.value.isNotEmpty) {
      pinLockInput.value = pinLockInput.value.substring(0, pinLockInput.value.length - 1);
    }
  }

  void clearPinLock() {
    pinLockInput.value = '';
  }

  void lockScreen() {
    clearPinLock();
    isLocked.value = true;
    Get.offAllNamed(AppRoutes.pinLock);
  }

  void logout() {
    currentUser.value = null;
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> saveClinicProfile() async {
    final name = clinicNameController.text.trim();
    final doc = doctorNameController.text.trim();
    final license = licenseController.text.trim();
    final phoneRaw = phoneController.text.trim();
    final address = addressController.text.trim();

    if (name.isEmpty) {
      Get.snackbar('تنبيه', 'اسم المنشأة البيطرية مطلوب',
          backgroundColor: Colors.amber.shade100, colorText: Colors.black87);
      return;
    }

    if (doc.isEmpty) {
      Get.snackbar('تنبيه', 'اسم الطبيب المسؤول مطلوب',
          backgroundColor: Colors.amber.shade100, colorText: Colors.black87);
      return;
    }

    if (license.isEmpty) {
      Get.snackbar('تنبيه', 'رقم ترخيص مزاولة المهنة مطلوب',
          backgroundColor: Colors.amber.shade100, colorText: Colors.black87);
      return;
    }

    final phoneError = YemeniPhoneValidator.validate(phoneRaw);
    if (phoneError != null) {
      Get.snackbar('تنبيه', phoneError,
          backgroundColor: Colors.amber.shade100, colorText: Colors.black87);
      return;
    }

    if (address.isEmpty) {
      Get.snackbar('تنبيه', 'عنوان المنشأة البيطرية مطلوب',
          backgroundColor: Colors.amber.shade100, colorText: Colors.black87);
      return;
    }

    isLoading.value = true;
    try {
      final formattedPhone = YemeniPhoneValidator.formatWithCountryCode(phoneRaw);
      final updated = ClinicModel(
        id: clinicInfo.value?.id,
        clinicName: name,
        doctorName: doc,
        licenseNumber: license,
        phone: formattedPhone,
        address: address,
        logoPath: clinicLogoPath.value,
      );
      await _authRepo.saveClinicInfo(updated);
      clinicInfo.value = updated;
      Get.back();
      Get.snackbar('تم', 'تم حفظ بيانات وهوية العيادة بنجاح',
          backgroundColor: Colors.green.shade100, colorText: Colors.green.shade900);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    pinController.dispose();
    clinicNameController.dispose();
    doctorNameController.dispose();
    licenseController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.onClose();
  }
}
