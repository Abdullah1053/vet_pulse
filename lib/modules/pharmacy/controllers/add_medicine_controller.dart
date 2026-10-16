import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/config/demo_config.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/services/data_sync_service.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/repositories/inventory_repository.dart';

class AddMedicineController extends GetxController {
  final InventoryRepository _inventoryRepo;

  AddMedicineController(this._inventoryRepo);

  final RxBool isLoading = false.obs;

  final tradeNameController = TextEditingController();
  final scientificNameController = TextEditingController();
  final formController = TextEditingController(text: AppStringsAr.formTablet);
  final concentrationController = TextEditingController();
  final clinicStockController = TextEditingController(text: '0');
  final warehouseStockController = TextEditingController(text: '0');
  final minStockController = TextEditingController(text: '5');
  final costPriceController = TextEditingController(text: '0.0');
  final salePriceController = TextEditingController(text: '0.0');
  final expiryDateController = TextEditingController();
  final batchNumberController = TextEditingController();

  Future<void> saveMedicine() async {
    if (!await DemoConfig.canAddMedicine()) {
      return;
    }

    final trade = tradeNameController.text.trim();
    final expiry = expiryDateController.text.trim();

    if (trade.isEmpty || expiry.isEmpty) {
      Get.snackbar('تنبيه', 'الاسم التجاري وتاريخ الانتهاء مطلوبان',
          backgroundColor: Colors.amber.shade100);
      return;
    }

    isLoading.value = true;
    try {
      final model = MedicineModel(
        tradeName: trade,
        scientificName: scientificNameController.text.trim(),
        form: formController.text.trim(),
        concentration: concentrationController.text.trim(),
        clinicStock: int.tryParse(clinicStockController.text.trim()) ?? 0,
        warehouseStock: int.tryParse(warehouseStockController.text.trim()) ?? 0,
        minStockAlert: int.tryParse(minStockController.text.trim()) ?? 5,
        unitCostPrice: double.tryParse(costPriceController.text.trim()) ?? 0.0,
        unitSalePrice: double.tryParse(salePriceController.text.trim()) ?? 0.0,
        expiryDate: expiry,
        batchNumber: batchNumberController.text.trim(),
      );

      await _inventoryRepo.insertMedicine(model);
      clearAddForm();
      DataSyncService.notifyInventoryChanged();
      Get.back();
      Get.snackbar('نجاح', 'تمت إضافة المستحضر الطبي إلى المخزون',
          backgroundColor: Colors.green.shade100);
    } finally {
      isLoading.value = false;
    }
  }

  void clearAddForm() {
    tradeNameController.clear();
    scientificNameController.clear();
    formController.text = AppStringsAr.formTablet;
    concentrationController.clear();
    clinicStockController.text = '0';
    warehouseStockController.text = '0';
    minStockController.text = '5';
    costPriceController.text = '0.0';
    salePriceController.text = '0.0';
    expiryDateController.clear();
    batchNumberController.clear();
  }

  @override
  void onClose() {
    tradeNameController.dispose();
    scientificNameController.dispose();
    formController.dispose();
    concentrationController.dispose();
    clinicStockController.dispose();
    warehouseStockController.dispose();
    minStockController.dispose();
    costPriceController.dispose();
    salePriceController.dispose();
    expiryDateController.dispose();
    batchNumberController.dispose();
    super.onClose();
  }
}
