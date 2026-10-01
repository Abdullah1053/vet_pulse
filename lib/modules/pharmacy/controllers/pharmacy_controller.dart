import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../../core/services/data_sync_service.dart';
import '../../../core/config/demo_config.dart';

class PharmacyController extends GetxController {
  final InventoryRepository _inventoryRepo = InventoryRepository();

  final RxList<MedicineModel> medicines = <MedicineModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedFilter = 'الكل'.obs;

  final searchController = TextEditingController();

  // Add Medicine Form Controllers
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

  // Transfer Form Controllers
  final Rx<MedicineModel?> selectedMedForTransfer = Rx<MedicineModel?>(null);
  final transferQuantityController = TextEditingController();

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

  Future<void> saveMedicine() async {
    if (!await DemoConfig.canAddMedicine()) {
      return;
    }

    final trade = tradeNameController.text.trim();
    final expiry = expiryDateController.text.trim();

    if (trade.isEmpty || expiry.isEmpty) {
      Get.snackbar('تنبيه', 'الاسم التجاري وتاريخ الانتهاء مطلوبان', backgroundColor: Colors.amber.shade100);
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
      await loadMedicines();
      DataSyncService.notifyInventoryChanged();
      Get.back();
      Get.snackbar('نجاح', 'تمت إضافة المستحضر الطبي إلى المخزون', backgroundColor: Colors.green.shade100);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> transferStock() async {
    final med = selectedMedForTransfer.value;
    final qty = int.tryParse(transferQuantityController.text.trim()) ?? 0;

    if (med == null || med.id == null) {
      Get.snackbar('تنبيه', 'يرجى اختيار الصنف لنقل رصيده', backgroundColor: Colors.amber.shade100);
      return;
    }

    if (qty <= 0) {
      Get.snackbar('تنبيه', 'الكمية المنقولة يجب أن تكون أكبر من صفر', backgroundColor: Colors.amber.shade100);
      return;
    }

    if (qty > med.warehouseStock) {
      Get.snackbar('خطأ', 'الكمية المطلوبة أكبر من رصيد المستودع الحالي (${med.warehouseStock})',
          backgroundColor: Colors.red.shade100);
      return;
    }

    isLoading.value = true;
    try {
      final success = await _inventoryRepo.transferStock(medicineId: med.id!, quantity: qty);
      if (success) {
        transferQuantityController.clear();
        selectedMedForTransfer.value = null;
        await loadMedicines();
        DataSyncService.notifyInventoryChanged();
        Get.back();
        Get.snackbar('نجاح', 'تم تحويل $qty وحدة من المستودع إلى رف العيادة بنجاح',
            backgroundColor: Colors.green.shade100);
      } else {
        Get.snackbar('خطأ', 'فشلت عملية التحويل، تحقق من الرصيد المتوفر', backgroundColor: Colors.red.shade100);
      }
    } finally {
      isLoading.value = false;
    }
  }

  void clearAddForm() {
    tradeNameController.clear();
    scientificNameController.clear();
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
    searchController.dispose();
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
    transferQuantityController.dispose();
    super.onClose();
  }
}
