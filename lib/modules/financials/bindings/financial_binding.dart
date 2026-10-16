import 'package:get/get.dart';
import '../../../data/repositories/financial_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../controllers/financial_controller.dart';

class FinancialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FinancialRepository>(() => FinancialRepository());
    Get.lazyPut<PetRepository>(() => PetRepository());
    Get.lazyPut<FinancialDashboardController>(
      () => FinancialDashboardController(
        Get.find<FinancialRepository>(),
        Get.find<PetRepository>(),
      ),
    );
    Get.lazyPut<OwnerStatementController>(
      () => OwnerStatementController(Get.find<FinancialRepository>()),
    );
    Get.lazyPut<FinancialController>(
      () => FinancialController(
        Get.find<FinancialRepository>(),
        Get.find<PetRepository>(),
      ),
    );
  }
}
