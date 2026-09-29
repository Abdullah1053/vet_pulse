import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../data/models/owner_model.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../routes/app_routes.dart';

class OwnersListController extends GetxController {
  final PetRepository _petRepo = PetRepository();
  final RxList<Map<String, dynamic>> owners = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredOwners = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadOwners();
  }

  Future<void> loadOwners() async {
    isLoading.value = true;
    try {
      final list = await _petRepo.getOwnersWithPetCounts();
      owners.assignAll(list);
      applyFilter();
    } finally {
      isLoading.value = false;
    }
  }

  void onSearch(String q) {
    applyFilter();
  }

  void applyFilter() {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      filteredOwners.assignAll(owners);
      return;
    }
    filteredOwners.assignAll(owners.where((o) {
      final name = (o['full_name'] as String? ?? '').toLowerCase();
      final phone = (o['phone_primary'] as String? ?? '').toLowerCase();
      final addr = (o['address'] as String? ?? '').toLowerCase();
      return name.contains(query) || phone.contains(query) || addr.contains(query);
    }).toList());
  }

  Future<void> callOwner(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> whatsappOwner(String phone, String name) async {
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('whatsapp://send?phone=$clean&text=${Uri.encodeComponent("مرحباً أ/ $name")}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}

class OwnersListView extends StatelessWidget {
  const OwnersListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OwnersListController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('دليل المربين والعملاء'),
        actions: [
          IconButton(
            tooltip: AppStringsAr.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadOwners,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('إضافة مريض / مالك', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => Get.toNamed(AppRoutes.addPatient)?.then((_) => controller.loadOwners()),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: CustomTextField(
              label: 'بحث عن مربي',
              hint: 'ابحث باسم المالك أو رقم هاتفه...',
              controller: controller.searchController,
              prefixIcon: const Icon(Icons.search),
              onChanged: controller.onSearch,
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredOwners.isEmpty) {
                return EmptyStateView(
                  icon: Icons.people_outline,
                  title: 'لا يوجد مربين مسجلين',
                  subtitle: 'يتم إضافة المربين تلقائياً عند تسجيل المرضى والحيوانات الأليفة',
                  actionText: 'إضافة مريض ومالك',
                  onAction: () => Get.toNamed(AppRoutes.addPatient)?.then((_) => controller.loadOwners()),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.filteredOwners.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final row = controller.filteredOwners[index];
                  final owner = OwnerModel.fromMap(row);
                  final petsCount = row['pets_count'] as int? ?? 0;

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Get.toNamed(AppRoutes.ownerDetail, arguments: owner.id)?.then((_) => controller.loadOwners());
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.15),
                              child: Text(
                                owner.fullName.isNotEmpty ? owner.fullName[0] : 'م',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    owner.fullName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        owner.phonePrimary,
                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryLight.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'عدد الحيوانات المسجلة: $petsCount',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.call, color: AppColors.success, size: 20),
                                      tooltip: 'اتصال هاتف',
                                      onPressed: () => controller.callOwner(owner.phonePrimary),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                                      tooltip: 'محادثة واتساب',
                                      onPressed: () => controller.whatsappOwner(owner.phonePrimary, owner.fullName),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                              ],
                            ),
                          ],
                        ),
                      ),
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
