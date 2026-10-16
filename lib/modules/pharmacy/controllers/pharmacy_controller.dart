import 'inventory_list_controller.dart';

export 'add_medicine_controller.dart';
export 'inventory_list_controller.dart';
export 'stock_transfer_controller.dart';

/// Backward compatibility class mapping PharmacyController to InventoryListController
class PharmacyController extends InventoryListController {
  PharmacyController(super.inventoryRepo);
}
