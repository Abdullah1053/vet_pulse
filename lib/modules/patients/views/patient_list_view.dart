import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../routes/app_routes.dart';
import '../controllers/patient_controller.dart';

class PatientListView extends GetView<PatientController> {
  const PatientListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStringsAr.patients),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadPatients,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(AppStringsAr.newPetAction, style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          controller.clearForm();
          Get.toNamed(AppRoutes.addPatient);
        },
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: controller.searchController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'ابحث باسم الحيوان، المالك، الهاتف، أو الشريحة...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    controller.searchController.clear();
                    controller.loadPatients();
                  },
                ),
              ),
              onChanged: controller.search,
            ),
          ),

          // Patients List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.patients.isEmpty) {
                return EmptyStateView(
                  icon: Icons.pets,
                  title: 'لا يوجد مرضى مسجلين',
                  subtitle: 'قم بإضافة ملف أول مريض بيطري إلى النظام',
                  actionText: AppStringsAr.newPetAction,
                  onAction: () => Get.toNamed(AppRoutes.addPatient),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: controller.patients.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final pet = controller.patients[index];
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      onTap: () async {
                        await controller.selectPet(pet);
                        Get.toNamed(AppRoutes.patientDetail);
                      },
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.secondaryLight,
                        child: Icon(
                          pet.species == 'كلب'
                              ? Icons.pets
                              : (pet.species == 'طائر' ? Icons.flutter_dash : Icons.pets),
                          color: AppColors.primary,
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            pet.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          StatusChip(
                            label: pet.species,
                            type: ChipStatusType.info,
                            fontSize: 11,
                          ),
                          if (pet.hasAllergies) ...[
                            const SizedBox(width: 6),
                            const StatusChip(
                              label: 'حساسية!',
                              type: ChipStatusType.critical,
                              fontSize: 10,
                            ),
                          ],
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'المالك: ${pet.ownerName ?? "غير محدد"} • ${pet.ownerPhone ?? ""}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (pet.latestWeight != null)
                              Text(
                                'الوزن الأخير: ${pet.latestWeight} كجم',
                                style: const TextStyle(fontSize: 11, color: AppColors.primary),
                              ),
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
