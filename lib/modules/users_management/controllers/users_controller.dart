import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/yemeni_phone_validator.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class UsersController extends GetxController {
  final AuthRepository _authRepo;

  UsersController([AuthRepository? authRepo])
      : _authRepo = authRepo ?? AuthRepository();

  final RxList<UserModel> users = <UserModel>[].obs;
  final RxBool isLoading = false.obs;

  // New User Form Controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final pinController = TextEditingController(text: '1234');
  final RxString selectedRole = 'assistant_vet'.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers() async {
    isLoading.value = true;
    try {
      final list = await _authRepo.getAllUsers();
      users.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addUser() async {
    final uName = usernameController.text.trim();
    final pass = passwordController.text;
    final fName = fullNameController.text.trim();
    final pRaw = phoneController.text.trim();
    final pin = pinController.text.trim();

    if (fName.isEmpty || uName.isEmpty || pass.isEmpty || pin.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'الاسم الكامل، اسم المستخدم، كلمة المرور، ورمز PIN كلها حقول مطلوبة',
        backgroundColor: Colors.amber.shade100,
        colorText: Colors.black87,
      );
      return;
    }

    if (pin.length != 4 || int.tryParse(pin) == null) {
      Get.snackbar(
        'تنبيه',
        'رمز PIN يجب أن يتكون من 4 أرقام',
        backgroundColor: Colors.amber.shade100,
        colorText: Colors.black87,
      );
      return;
    }

    if (pRaw.isNotEmpty) {
      final phoneError = YemeniPhoneValidator.validate(pRaw, isRequired: false);
      if (phoneError != null) {
        Get.snackbar(
          'تنبيه',
          phoneError,
          backgroundColor: Colors.amber.shade100,
          colorText: Colors.black87,
        );
        return;
      }
    }

    if (users.any((u) => u.username.trim().toLowerCase() == uName.toLowerCase())) {
      Get.snackbar(
        'خطأ',
        'اسم المستخدم مسجل مسبقاً',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
      return;
    }

    final formattedPhone = pRaw.isNotEmpty
        ? YemeniPhoneValidator.formatWithCountryCode(pRaw)
        : null;

    isLoading.value = true;
    try {
      final user = UserModel(
        username: uName,
        passwordHash: pass,
        fullName: fName,
        role: selectedRole.value,
        phone: formattedPhone,
        pinCode: pin,
      );

      await _authRepo.addUser(user);
      clearForm();
      await loadUsers();
      if (Get.isDialogOpen ?? false) {
        Get.back();
      } else if (Get.overlayContext != null) {
        Navigator.of(Get.overlayContext!).pop();
      }
      Get.snackbar(
        'تم',
        'تمت إضافة الموظف بنجاح',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء إضافة الموظف: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleActive(UserModel user) async {
    final updated = UserModel(
      id: user.id,
      username: user.username,
      passwordHash: user.passwordHash,
      fullName: user.fullName,
      role: user.role,
      phone: user.phone,
      pinCode: user.pinCode,
      isActive: !user.isActive,
    );
    await _authRepo.updateUser(updated);
    await loadUsers();
  }

  void clearForm() {
    usernameController.clear();
    passwordController.clear();
    fullNameController.clear();
    phoneController.clear();
    pinController.text = '1234';
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    pinController.dispose();
    super.onClose();
  }
}
