import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/owner_model.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../routes/app_routes.dart';

class OwnerDetailController extends GetxController {
  final PetRepository _petRepo = PetRepository();

  final Rx<OwnerModel?> owner = Rx<OwnerModel?>(null);
  final RxList<PetModel> pets = <PetModel>[].obs;
  final RxBool isLoading = true.obs;

  late int ownerId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is int) {
      ownerId = args;
      loadOwnerData();
    } else {
      Get.back();
    }
  }

  Future<void> loadOwnerData() async {
    isLoading.value = true;
    try {
      final o = await _petRepo.getOwnerById(ownerId);
      owner.value = o;
      final petList = await _petRepo.getPetsByOwnerId(ownerId);
      pets.assignAll(petList);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> callOwner() async {
    final phone = owner.value?.phonePrimary;
    if (phone == null) return;
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> whatsappOwner() async {
    final phone = owner.value?.phonePrimary;
    if (phone == null) return;
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final name = owner.value?.fullName ?? '';
    final uri = Uri.parse('whatsapp://send?phone=$clean&text=${Uri.encodeComponent("مرحباً أ/ $name")}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class OwnerDetailView extends StatelessWidget {
  const OwnerDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OwnerDetailController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.owner.value?.fullName ?? 'تفاصيل المربي')),
        actions: [
          IconButton(
            tooltip: AppStringsAr.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadOwnerData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('إضافة حيوان لهذا المربي', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          Get.toNamed(AppRoutes.addPatient)?.then((_) => controller.loadOwnerData());
        },
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final owner = controller.owner.value;
        if (owner == null) {
          return const Center(child: Text('لم يتم العثور على بيانات المربي'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Owner Information Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary,
                            child: const Icon(Icons.person, size: 36, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  owner.fullName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'مسجل بالنظام منذ: ${owner.createdAt != null && owner.createdAt!.length >= 10 ? owner.createdAt!.substring(0, 10) : "غير محدد"}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Contact Details
                      _buildInfoRow(Icons.phone, 'رقم الهاتف الأساسي', owner.phonePrimary),
                      if (owner.phoneSecondary != null && owner.phoneSecondary!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.phone_android, 'رقم بديل', owner.phoneSecondary!),
                      ],
                      if (owner.address != null && owner.address!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.location_on_outlined, 'العنوان', owner.address!),
                      ],
                      if (owner.notes != null && owner.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.note_outlined, 'ملاحظات', owner.notes!),
                      ],

                      const SizedBox(height: 16),
                      // Quick Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: controller.callOwner,
                              icon: const Icon(Icons.call, size: 18),
                              label: const Text('اتصال مباشر'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: controller.whatsappOwner,
                              icon: const Icon(Icons.chat, size: 18),
                              label: const Text('واتساب'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Registered Pets Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الحيوانات التابعة لهذا المربي (${controller.pets.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkNeutral),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('إضافة حيوان'),
                    onPressed: () {
                      Get.toNamed(AppRoutes.addPatient)?.then((_) => controller.loadOwnerData());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (controller.pets.isEmpty)
                EmptyStateView(
                  icon: Icons.pets,
                  title: 'لا يوجد حيوانات أليفة مسجلة',
                  subtitle: 'يمكنك إضافة قط أو كلب أو حيوان أليف لهذا المربي الآن',
                  actionText: 'إضافة أول حيوان',
                  onAction: () {
                    Get.toNamed(AppRoutes.addPatient)?.then((_) => controller.loadOwnerData());
                  },
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.pets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pet = controller.pets[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Seamlessly navigate to pet details
                          Get.toNamed(AppRoutes.patientDetail, arguments: pet.id)?.then((_) => controller.loadOwnerData());
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: AppColors.secondaryLight,
                                        child: const Icon(Icons.pets, color: AppColors.primary, size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pet.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text(
                                            '${pet.species} ${pet.breed != null ? "• ${pet.breed}" : ""}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  StatusChip(
                                    label: pet.genderDisplayArabic,
                                    type: pet.gender == 'female' ? ChipStatusType.info : ChipStatusType.neutral,
                                  ),
                                ],
                              ),
                              const Divider(height: 20),

                              Row(
                                children: [
                                  const Icon(Icons.cake_outlined, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'العمر: ${pet.ageDisplayArabic}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  if (pet.latestWeight != null) ...[
                                    const SizedBox(width: 16),
                                    const Icon(Icons.monitor_weight_outlined, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'الوزن: ${pet.latestWeight} كجم',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ],
                              ),

                              if (pet.microchipNumber != null && pet.microchipNumber!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.qr_code, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'رقم الشريحة: ${pet.microchipNumber}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),

                              // Quick pet action links
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(Icons.medical_services_outlined, size: 16),
                                    label: const Text('كشف سريري جديد'),
                                    onPressed: () {
                                      Get.toNamed(AppRoutes.newConsultation, arguments: pet.id);
                                    },
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                    onPressed: () {
                                      Get.toNamed(AppRoutes.patientDetail, arguments: pet.id)?.then((_) => controller.loadOwnerData());
                                    },
                                    child: const Row(
                                      children: [
                                        Text('الملف الطبي'),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_ios, size: 12),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkNeutral),
          ),
        ),
      ],
    );
  }
}
