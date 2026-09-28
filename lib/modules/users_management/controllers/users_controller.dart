import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class UsersController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();

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

    if (uName.isEmpty || pass.isEmpty || fName.isEmpty) {
      Get.snackbar('تنبيه', 'اسم المستخدم وكلمة المرور والاسم الكامل مطلوبان',
          backgroundColor: Colors.amber.shade100);
      return;
    }

    isLoading.value = true;
    try {
      final user = UserModel(
        username: uName,
        passwordHash: pass,
        fullName: fName,
        role: selectedRole.value,
        phone: phoneController.text.trim(),
        pinCode: pinController.text.trim(),
      );

      await _authRepo.addUser(user);
      clearForm();
      await loadUsers();
      Get.back();
      Get.snackbar('تم', 'تمت إضافة المستخدم بنجاح', backgroundColor: Colors.green.shade100);
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
