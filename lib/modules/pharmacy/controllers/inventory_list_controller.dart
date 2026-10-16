import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/repositories/inventory_repository.dart';

class InventoryListController extends GetxController {
  final InventoryRepository _inventoryRepo;

  InventoryListController(this._inventoryRepo);

  final RxList<MedicineModel> medicines = <MedicineModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedFilter = 'الكل'.obs;

  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadMedicines();
  }

  Future<void> loadMedicines() async {
    isLoading.value = true;
    try {
      final list = await _inventoryRepo.getAllMedicines();
      medicines.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      loadMedicines();
      return;
    }
    isLoading.value = true;
    try {
      final results = await _inventoryRepo.searchMedicines(query);
      medicines.assignAll(results);
    } finally {
      isLoading.value = false;
    }
  }

  void filterMedicines(String filter) async {
    selectedFilter.value = filter;
    isLoading.value = true;
    try {
      if (filter == 'منخفض') {
        final low = await _inventoryRepo.getLowStockMedicines();
        medicines.assignAll(low);
      } else if (filter == 'منتهي / قريب') {
        final exp = await _inventoryRepo.getExpiringOrExpiredMedicines();
        medicines.assignAll(exp);
      } else {
        await loadMedicines();
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
