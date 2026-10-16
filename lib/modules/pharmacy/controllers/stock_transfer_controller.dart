import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/data_sync_service.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/repositories/inventory_repository.dart';

class StockTransferController extends GetxController {
  final InventoryRepository _inventoryRepo;

  StockTransferController(this._inventoryRepo);

  final RxList<MedicineModel> medicines = <MedicineModel>[].obs;
  final Rx<MedicineModel?> selectedMedForTransfer = Rx<MedicineModel?>(null);
  final transferQuantityController = TextEditingController();
  final RxBool isLoading = false.obs;

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

  Future<void> transferStock() async {
    final med = selectedMedForTransfer.value;
    final qty = int.tryParse(transferQuantityController.text.trim()) ?? 0;

    if (med == null || med.id == null) {
      Get.snackbar('تنبيه', 'يرجى اختيار الصنف لنقل رصيده',
          backgroundColor: Colors.amber.shade100);
      return;
    }

    if (qty <= 0) {
      Get.snackbar('تنبيه', 'الكمية المنقولة يجب أن تكون أكبر من صفر',
          backgroundColor: Colors.amber.shade100);
      return;
    }

    if (qty > med.warehouseStock) {
      Get.snackbar(
        'خطأ',
        'الكمية المطلوبة أكبر من رصيد المستودع الحالي (${med.warehouseStock})',
        backgroundColor: Colors.red.shade100,
      );
      return;
    }

    isLoading.value = true;
    try {
      final success = await _inventoryRepo.transferStock(
        medicineId: med.id!,
        quantity: qty,
      );
      if (success) {
        transferQuantityController.clear();
        selectedMedForTransfer.value = null;
        DataSyncService.notifyInventoryChanged();
        Get.back();
        Get.snackbar(
          'نجاح',
          'تم تحويل $qty وحدة من المستودع إلى رف العيادة بنجاح',
          backgroundColor: Colors.green.shade100,
        );
      } else {
        Get.snackbar(
          'خطأ',
          'فشلت عملية التحويل، تحقق من الرصيد المتوفر',
          backgroundColor: Colors.red.shade100,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    transferQuantityController.dispose();
    super.onClose();
  }
}
