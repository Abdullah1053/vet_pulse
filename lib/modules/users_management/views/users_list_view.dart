import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/utils/yemeni_phone_validator.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/users_controller.dart';

class UsersListView extends GetView<UsersController> {
  const UsersListView({super.key});

  void _showUserFormDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Obx(
          () => Text(
            controller.isEditing.value ? 'تعديل بيانات الموظف' : AppStringsAr.addUser,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: AppStringsAr.fullName,
                hint: 'مثال: د. سارة الأحمد',
                controller: controller.fullNameController,
                prefixIcon: const Icon(Icons.person),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: AppStringsAr.username,
                hint: 'اسم المستخدم للدخول',
                controller: controller.usernameController,
                prefixIcon: const Icon(Icons.account_circle),
              ),
              const SizedBox(height: 12),
              Obx(
                () => CustomTextField(
                  label: AppStringsAr.password,
                  hint: controller.isEditing.value
                      ? 'اتركه فارغاً للإبقاء على كلمة المرور الحالية'
                      : 'كلمة المرور',
                  controller: controller.passwordController,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: AppStringsAr.pinCode,
                hint: '4 أرقام للقفل السريع',
                controller: controller.pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                prefixIcon: const Icon(Icons.pin),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: '${AppStringsAr.phone} (رقم يمني +967)',
                hint: '77xxxxxxx أو 78 أو 73 أو 70 أو 71',
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                prefixText: '+967 ',
                textDirection: TextDirection.ltr,
                maxLength: 9,
                validator: (v) => YemeniPhoneValidator.validate(v, isRequired: false),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                prefixIcon: const Icon(Icons.phone),
              ),
              const SizedBox(height: 12),
              Obx(
                () => DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: controller.selectedRole.value,
                  decoration: const InputDecoration(labelText: AppStringsAr.role),
                  items: const [
                    DropdownMenuItem(
                      value: 'lead_doctor',
                      child: Text('طبيب رئيسي (Lead Doctor)', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'assistant_vet',
                      child: Text('طبيب مساعد (Assistant Vet)', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'receptionist',
                      child: Text('موظف استقبال (Receptionist)', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'pharmacist',
                      child: Text('أمين المستودع (Pharmacist)', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) controller.selectedRole.value = v;
                  },
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('حالة الحساب', style: TextStyle(fontSize: 14)),
                  subtitle: Text(
                    controller.isFormUserActive.value ? 'نشط ومفعل' : 'معطل وموقوف',
                    style: TextStyle(
                      fontSize: 12,
                      color: controller.isFormUserActive.value ? AppColors.success : AppColors.critical,
                    ),
                  ),
                  value: controller.isFormUserActive.value,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => controller.isFormUserActive.value = v,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(AppStringsAr.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: controller.saveUser,
            child: const Text(AppStringsAr.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStringsAr.usersManagement),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text(AppStringsAr.addUser, style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          if (authController != null &&
              !authController.checkPermission((u) => u.canManageUsers, 'إضافة موظف جديد متاح للطبيب الرئيسي فقط')) {
            return;
          }
          controller.clearForm();
          _showUserFormDialog(context);
        },
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final currentUserId = authController?.currentUser.value?.id;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.users.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final user = controller.users[index];
            final isPrimaryAdmin = user.id == 1;
            final isSelf = currentUserId != null && user.id == currentUserId;
            final isSwitchDisabled = isPrimaryAdmin || isSelf;

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: user.isActive ? AppColors.secondaryLight : Colors.grey.shade200,
                      child: Icon(
                        user.isLeadDoctor
                            ? Icons.medical_services
                            : (user.isAssistantVet
                                ? Icons.healing
                                : (user.isPharmacist ? Icons.medication : Icons.support_agent)),
                        color: user.isActive ? AppColors.primary : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.fullName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: user.isActive ? AppColors.darkNeutral : AppColors.textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusChip(
                                label: user.roleDisplayArabic,
                                type: user.isLeadDoctor ? ChipStatusType.info : ChipStatusType.neutral,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'اسم المستخدم: ${user.username} • PIN: ${user.pinCode ?? "-"}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (user.phone != null && user.phone!.isNotEmpty)
                            Text(
                              'الهاتف: ${user.phone}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user.isActive ? 'نشط' : 'معطل',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: user.isActive ? AppColors.success : AppColors.critical,
                              ),
                            ),
                            Switch(
                              value: user.isActive,
                              activeThumbColor: AppColors.primary,
                              onChanged: isSwitchDisabled
                                  ? null
                                  : (_) {
                                      if (authController != null &&
                                          !authController.checkPermission((u) => u.canManageUsers, 'تغيير حالة الموظفين متاح للطبيب الرئيسي فقط')) {
                                        return;
                                      }
                                      controller.toggleActive(user);
                                    },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                              tooltip: 'تعديل بيانات الموظف',
                              onPressed: () {
                                if (authController != null &&
                                    !authController.checkPermission((u) => u.canManageUsers, 'تعديل بيانات الموظفين متاح للطبيب الرئيسي فقط')) {
                                  return;
                                }
                                controller.initEditUser(user);
                                _showUserFormDialog(context);
                              },
                            ),
                            if (!isPrimaryAdmin)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.critical),
                                tooltip: 'حذف الموظف',
                                onPressed: isSelf
                                    ? null
                                    : () {
                                        if (authController != null &&
                                            !authController.checkPermission((u) => u.canManageUsers, 'حذف الموظفين متاح للطبيب الرئيسي فقط')) {
                                          return;
                                        }
                                        controller.deleteUser(user);
                                      },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
