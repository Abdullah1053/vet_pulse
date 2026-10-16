import 'package:get/get.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../controllers/pharmacy_controller.dart';

class PharmacyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InventoryRepository>(() => InventoryRepository());
    Get.lazyPut<InventoryListController>(() => InventoryListController(Get.find<InventoryRepository>()));
    Get.lazyPut<AddMedicineController>(() => AddMedicineController(Get.find<InventoryRepository>()));
    Get.lazyPut<StockTransferController>(() => StockTransferController(Get.find<InventoryRepository>()));
    Get.lazyPut<PharmacyController>(() => PharmacyController(Get.find<InventoryRepository>()));
  }
}
