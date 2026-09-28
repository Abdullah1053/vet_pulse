import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/utils/arabic_date_helper.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../routes/app_routes.dart';
import '../controllers/pharmacy_controller.dart';

class InventoryListView extends GetView<PharmacyController> {
  const InventoryListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStringsAr.pharmacy),
        actions: [
          IconButton(
            tooltip: AppStringsAr.stockTransfer,
            icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
            onPressed: () => Get.toNamed(AppRoutes.stockTransfer),
          ),
          IconButton(
            tooltip: AppStringsAr.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadMedicines,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(AppStringsAr.addMedicine, style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          controller.clearAddForm();
          Get.toNamed(AppRoutes.addMedicine);
        },
      ),
      body: Column(
        children: [
          // Filter Tabs (الكل، منخفض، منتهي / قريب)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Obx(() => Row(
                  children: [
                    _buildFilterChip('الكل'),
                    const SizedBox(width: 8),
                    _buildFilterChip('منخفض'),
                    const SizedBox(width: 8),
                    _buildFilterChip('منتهي / قريب'),
                  ],
                )),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: TextField(
              controller: controller.searchController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم التجاري، العلمي، أو رقم التشغيلة...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    controller.searchController.clear();
                    controller.loadMedicines();
                  },
                ),
              ),
              onChanged: controller.search,
            ),
          ),

          // Medicine Items List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.medicines.isEmpty) {
                return EmptyStateView(
                  icon: Icons.medication,
                  title: 'لا توجد أدوية مطابقة',
                  subtitle: 'قم بإضافة أصناف دوائية إلى مخزون العيادة',
                  actionText: AppStringsAr.addMedicine,
                  onAction: () => Get.toNamed(AppRoutes.addMedicine),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.medicines.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final med = controller.medicines[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      med.tradeName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    if (med.scientificName != null && med.scientificName!.isNotEmpty)
                                      Text(
                                        med.scientificName!,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                  ],
                                ),
                              ),
                              _buildExpiryBadge(med.expiryStatus),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStockColumn(
                                label: 'رف العيادة (الفوري)',
                                stock: med.clinicStock,
                                isLow: med.isLowStock,
                              ),
                              _buildStockColumn(
                                label: 'المستودع الرئيسي',
                                stock: med.warehouseStock,
                                isLow: false,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${med.unitSalePrice.toStringAsFixed(1)} ر.س',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                                  ),
                                  Text(
                                    'الصلاحية: ${med.expiryDate}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = controller.selectedFilter.value == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.filterMedicines(label),
    );
  }

  Widget _buildStockColumn({required String label, required int stock, required bool isLow}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              '$stock',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isLow ? AppColors.critical : AppColors.darkNeutral,
              ),
            ),
            if (isLow) ...[
              const SizedBox(width: 4),
              const Icon(Icons.arrow_downward, size: 14, color: AppColors.critical),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildExpiryBadge(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.expired:
        return const StatusChip(label: 'منتهي الصلاحية', type: ChipStatusType.critical);
      case ExpiryStatus.nearExpiry:
        return const StatusChip(label: 'أوشك على الانتهاء (<30 يوم)', type: ChipStatusType.warning);
      case ExpiryStatus.valid:
        return const StatusChip(label: 'صالح', type: ChipStatusType.success);
    }
  }
}
