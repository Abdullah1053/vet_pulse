import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/status_chip.dart';
import '../controllers/users_controller.dart';

class UsersListView extends GetView<UsersController> {
  const UsersListView({super.key});

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStringsAr.addUser),
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
              CustomTextField(
                label: AppStringsAr.password,
                hint: 'كلمة المرور',
                controller: controller.passwordController,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: AppStringsAr.pinCode,
                hint: '4 أرقام للقفل السريع',
                controller: controller.pinController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.pin),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: AppStringsAr.phone,
                hint: '05xxxxxxxx',
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: controller.selectedRole.value,
                decoration: const InputDecoration(labelText: AppStringsAr.role),
                items: const [
                  DropdownMenuItem(value: 'lead_doctor', child: Text('طبيب رئيسي (Lead Doctor)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'assistant_vet', child: Text('طبيب مساعد (Assistant Vet)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'receptionist', child: Text('موظف استقبال (Receptionist)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 'pharmacist', child: Text('أمين المستودع (Pharmacist)', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) {
                  if (v != null) controller.selectedRole.value = v;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStringsAr.cancel),
          ),
          ElevatedButton(
            onPressed: controller.addUser,
            child: const Text(AppStringsAr.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStringsAr.usersManagement),
        actions: [
          IconButton(
            tooltip: AppStringsAr.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text(AppStringsAr.addUser, style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          controller.clearForm();
          _showAddUserDialog(context);
        },
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.users.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final user = controller.users[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
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
                title: Row(
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: user.isActive ? AppColors.darkNeutral : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(
                      label: user.roleDisplayArabic,
                      type: user.isLeadDoctor ? ChipStatusType.info : ChipStatusType.neutral,
                    ),
                  ],
                ),
                subtitle: Text(
                  'اسم المستخدم: ${user.username} • PIN: ${user.pinCode ?? "-"}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Switch(
                  value: user.isActive,
                  activeThumbColor: AppColors.primary,
                  onChanged: user.isLeadDoctor ? null : (_) => controller.toggleActive(user),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
