import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/services/device_contact_service.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../data/database/demo_data_seeder.dart';
import '../../../data/models/owner_model.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../routes/app_routes.dart';

class OwnersListController extends GetxController {
  final PetRepository _petRepo = PetRepository();
  final RxList<Map<String, dynamic>> owners = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredOwners = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final searchController = TextEditingController();

  int get totalPetsCount => owners.fold<int>(
        0,
        (sum, o) => sum + (o['pets_count'] as int? ?? 0),
      );

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

  void clearSearch() {
    searchController.clear();
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
    final uri = Uri.parse(
      'whatsapp://send?phone=$clean&text=${Uri.encodeComponent("مرحباً أ/ $name")}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> saveToContacts(String name, String phone) async {
    await DeviceContactService.saveOwnerToContacts(name: name, phone: phone);
  }

  void copyPhoneToClipboard(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    Get.snackbar(
      'تم النسخ',
      'تم نسخ رقم الهاتف ($phone) إلى الحافظة',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.grey.shade800,
      colorText: Colors.white,
    );
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'دليل المربين والعملاء',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'توليد واستعادة البيانات التجريبية الشاملة',
            icon: const Icon(Icons.auto_awesome, color: Colors.amber),
            onPressed: () async {
              final confirm = await Get.dialog<bool>(
                AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.amber),
                      SizedBox(width: 8),
                      Text('توليد بيانات تجريبية شاملة'),
                    ],
                  ),
                  content: const Text(
                    'سيتم ملء وتحديث التطبيق ببيانات تجريبية كاملة للمربين والحيوانات الأليفة، بالإضافة إلى السجلات المالية وسندات القبض والمصروفات.\n\nهل تريد المتابعة؟',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: () => Get.back(result: true),
                      child: const Text('توليد الآن', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                Get.dialog(
                  const Center(child: CircularProgressIndicator()),
                  barrierDismissible: false,
                );
                await DemoDataSeeder.resetDemoData();
                await controller.loadOwners();
                Get.back();
                Get.snackbar(
                  'تم بنجاح',
                  'تم توليد بيانات المربين وسجلاتهم المالية بنجاح.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green.shade800,
                  colorText: Colors.white,
                );
              }
            },
          ),
          IconButton(
            tooltip: AppStringsAr.refresh,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.loadOwners,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'إضافة مريض / مربي جديد',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: () => Get.toNamed(AppRoutes.addPatient)?.then((_) => controller.loadOwners()),
      ),
      body: Column(
        children: [
          // Search & Summary Header Card
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Quick Statistics Chips Row
                Obx(() => Row(
                  children: [
                    _buildStatPill(
                      icon: Icons.people_alt_rounded,
                      label: 'إجمالي المربين',
                      count: '${controller.owners.length}',
                      color: AppColors.primary,
                      bgColor: AppColors.primary.withValues(alpha: 0.08),
                    ),
                    const SizedBox(width: 8),
                    _buildStatPill(
                      icon: Icons.pets_rounded,
                      label: 'الحيوانات المسجلة',
                      count: '${controller.totalPetsCount}',
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                    ),
                  ],
                )),
                const SizedBox(height: 12),

                // Modern Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: controller.searchController,
                    onChanged: controller.onSearch,
                    decoration: InputDecoration(
                      hintText: 'ابحث باسم المربي، رقم هاتفه أو عنوانه...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      suffixIcon: Obx(() {
                        if (controller.filteredOwners.length != controller.owners.length ||
                            controller.searchController.text.isNotEmpty) {
                          return IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20, color: Colors.grey),
                            onPressed: controller.clearSearch,
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Owners List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.filteredOwners.isEmpty) {
                return EmptyStateView(
                  icon: Icons.people_outline_rounded,
                  title: 'لا يوجد مربين مسجلين',
                  subtitle: controller.searchController.text.isNotEmpty
                      ? 'لا توجد نتائج تطابق بحثك الحالي'
                      : 'يتم إضافة المربين تلقائياً أو يمكنك توليد بيانات تجريبية كاملة لعرض النظام',
                  actionText: controller.searchController.text.isNotEmpty
                      ? 'إلغاء التصفية'
                      : 'توليد بيانات تجريبية شاملة (Demo Data)',
                  onAction: () async {
                    if (controller.searchController.text.isNotEmpty) {
                      controller.clearSearch();
                    } else {
                      await DemoDataSeeder.resetDemoData();
                      await controller.loadOwners();
                    }
                  },
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
                itemCount: controller.filteredOwners.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final row = controller.filteredOwners[index];
                  final owner = OwnerModel.fromMap(row);
                  final petsCount = row['pets_count'] as int? ?? 0;

                  return _buildOwnerCard(context, controller, owner, petsCount);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required String count,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
            Text(
              count,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerCard(
    BuildContext context,
    OwnersListController controller,
    OwnerModel owner,
    int petsCount,
  ) {
    // Generate deterministic initials
    final initial = owner.fullName.trim().isNotEmpty ? owner.fullName.trim()[0] : 'م';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Get.toNamed(AppRoutes.ownerDetail, arguments: owner.id)?.then((_) => controller.loadOwners());
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              // Top Section: Avatar, Name, Phone, and Arrow
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gradient Avatar with Initial
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.75),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Owner Information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          owner.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        // Phone pill with quick copy
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => controller.copyPhoneToClipboard(owner.phonePrimary),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_rounded, size: 13, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    owner.phonePrimary,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.copy_rounded, size: 11, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),

                        // Address if available
                        if (owner.address != null && owner.address!.trim().isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  owner.address!,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Pet Count Chip and Arrow
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: petsCount > 0
                              ? const Color(0xFFE0F2FE)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: petsCount > 0
                                ? const Color(0xFFBAE6FD)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pets_rounded,
                              size: 13,
                              color: petsCount > 0 ? const Color(0xFF0284C7) : Colors.grey,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$petsCount',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: petsCount > 0 ? const Color(0xFF0284C7) : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ],
              ),

              const Divider(height: 20, thickness: 1, color: Color(0xFFF1F5F9)),

              // Action Buttons Row: Call, WhatsApp, Account Statement
              Row(
                children: [
                  // Call Button
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => controller.callOwner(owner.phonePrimary),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call_rounded, size: 15, color: Color(0xFF16A34A)),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'اتصال',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // WhatsApp Button
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => controller.whatsappOwner(owner.phonePrimary, owner.fullName),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_rounded, size: 15, color: Color(0xFF25D366)),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'واتساب',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Quick Account Statement button
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Get.toNamed(AppRoutes.ownerAccountStatement, arguments: owner.id)
                            ?.then((_) => controller.loadOwners());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.25)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 15, color: Color(0xFF0F766E)),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'كشف الحساب',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
