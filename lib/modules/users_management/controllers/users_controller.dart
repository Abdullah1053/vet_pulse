import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/yemeni_phone_validator.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../auth/controllers/auth_controller.dart';

class UsersController extends GetxController {
  final AuthRepository _authRepo;

  UsersController([AuthRepository? authRepo])
      : _authRepo = authRepo ??
            (Get.isRegistered<AuthRepository>()
                ? Get.find<AuthRepository>()
                : AuthRepository());

  final RxList<UserModel> users = <UserModel>[].obs;
  final RxBool isLoading = false.obs;

  // Edit mode state
  final RxBool isEditing = false.obs;
  final RxnInt editingUserId = RxnInt();
  final RxBool isFormUserActive = true.obs;

  // User Form Controllers
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

  void initEditUser(UserModel user) {
    isEditing.value = true;
    editingUserId.value = user.id;
    fullNameController.text = user.fullName;
    usernameController.text = user.username;
    passwordController.text = '';
    pinController.text = user.pinCode ?? '1234';
    phoneController.text = YemeniPhoneValidator.cleanDigits(user.phone ?? '');
    selectedRole.value = user.role;
    isFormUserActive.value = user.isActive;
  }

  Future<void> saveUser() async {
    final uName = usernameController.text.trim();
    final pass = passwordController.text;
    final fName = fullNameController.text.trim();
    final pRaw = phoneController.text.trim();
    final pin = pinController.text.trim();

    if (fName.isEmpty || uName.isEmpty || (!isEditing.value && pass.isEmpty) || pin.isEmpty) {
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

    final hasDuplicate = users.any((u) =>
        u.username.trim().toLowerCase() == uName.toLowerCase() &&
        (!isEditing.value || u.id != editingUserId.value));

    if (hasDuplicate) {
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
      final wasEditing = isEditing.value;
      if (wasEditing) {
        final existing = users.firstWhereOrNull((u) => u.id == editingUserId.value);
        final finalPass = pass.isNotEmpty ? pass : (existing?.passwordHash ?? '');
        final user = UserModel(
          id: editingUserId.value,
          username: uName,
          passwordHash: finalPass,
          fullName: fName,
          role: selectedRole.value,
          phone: formattedPhone,
          pinCode: pin,
          isActive: isFormUserActive.value,
        );
        await _authRepo.updateUser(user);
        final idx = users.indexWhere((u) => u.id == user.id);
        if (idx != -1) {
          users[idx] = user;
          users.refresh();
        }
      } else {
        final user = UserModel(
          username: uName,
          passwordHash: pass,
          fullName: fName,
          role: selectedRole.value,
          phone: formattedPhone,
          pinCode: pin,
          isActive: isFormUserActive.value,
        );
        await _authRepo.addUser(user);
      }

      clearForm();
      await loadUsers();
      if (Get.isDialogOpen ?? false) {
        Get.back();
      } else if (Get.overlayContext != null) {
        Navigator.of(Get.overlayContext!).pop();
      }
      Get.snackbar(
        'تم',
        wasEditing ? 'تم تعديل بيانات الموظف بنجاح' : 'تمت إضافة الموظف بنجاح',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء حفظ الموظف: $e',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addUser() => saveUser();

  Future<void> deleteUser(UserModel user) async {
    final currentLoggedInId = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().currentUser.value?.id
        : null;

    if (user.id == 1 || (currentLoggedInId != null && user.id == currentLoggedInId)) {
      Get.snackbar(
        'تنبيه',
        'لا يمكن حذف الحساب الإداري الرئيسي أو الحساب المسجل به حالياً',
        backgroundColor: Colors.amber.shade100,
        colorText: Colors.black87,
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('تأكيد الحذف'),
          ],
        ),
        content: Text('هل أنت متأكد من حذف حساب الموظف "${user.fullName}" بشكل نهائي؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Get.back();
              if (user.id != null) {
                await _authRepo.deleteUser(user.id!);
                users.removeWhere((u) => u.id == user.id);
                await loadUsers();
                Get.snackbar(
                  'تم الحذف',
                  'تم حذف حساب الموظف بنجاح',
                  backgroundColor: Colors.green.shade100,
                  colorText: Colors.green.shade900,
                );
              }
            },
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );
  }

  Future<void> toggleActive(UserModel user) async {
    final currentLoggedInId = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>().currentUser.value?.id
        : null;

    if (user.id == 1 || (currentLoggedInId != null && user.id == currentLoggedInId)) {
      Get.snackbar(
        'تنبيه',
        'لا يمكن تعطيل الحساب الإداري الرئيسي أو الحساب المسجل به حالياً',
        backgroundColor: Colors.amber.shade100,
        colorText: Colors.black87,
      );
      return;
    }

    final updated = user.copyWith(isActive: !user.isActive);
    final idx = users.indexWhere((u) => u.id == user.id);
    if (idx != -1) {
      users[idx] = updated;
      users.refresh();
    }
    await _authRepo.updateUser(updated);
  }

  void clearForm() {
    isEditing.value = false;
    editingUserId.value = null;
    isFormUserActive.value = true;
    usernameController.clear();
    passwordController.clear();
    fullNameController.clear();
    phoneController.clear();
    pinController.text = '1234';
    selectedRole.value = 'assistant_vet';
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
