import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/clinic_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final Rx<ClinicModel?> clinicInfo = Rx<ClinicModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isLocked = false.obs;

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
      phoneController.text = clinicInfo.value!.phone ?? '';
      addressController.text = clinicInfo.value!.address ?? '';
    }
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

  void lockScreen() {
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

    if (name.isEmpty || doc.isEmpty) {
      Get.snackbar('تنبيه', 'اسم العيادة واسم الطبيب مطلوبان',
          backgroundColor: Colors.amber.shade100);
      return;
    }

    isLoading.value = true;
    try {
      final updated = ClinicModel(
        id: clinicInfo.value?.id,
        clinicName: name,
        doctorName: doc,
        licenseNumber: licenseController.text.trim(),
        phone: phoneController.text.trim(),
        address: addressController.text.trim(),
      );
      await _authRepo.saveClinicInfo(updated);
      clinicInfo.value = updated;
      Get.back();
      Get.snackbar('تم', 'تم حفظ بيانات العيادة بنجاح',
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
