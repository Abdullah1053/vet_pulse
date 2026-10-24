import 'package:get/get.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/consultation_repository.dart';
import '../../../data/repositories/financial_repository.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../consultations/controllers/prescription_item_controller.dart';
import '../controllers/follow_up_controller.dart';
import '../controllers/follow_up_detail_controller.dart';

class FollowUpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppointmentRepository>(() => AppointmentRepository(), fenix: true);
    Get.lazyPut<PetRepository>(() => PetRepository(), fenix: true);
    Get.lazyPut<FinancialRepository>(() => FinancialRepository(), fenix: true);
    Get.lazyPut<InventoryRepository>(() => InventoryRepository(), fenix: true);
    Get.lazyPut<ConsultationRepository>(() => ConsultationRepository(), fenix: true);
    Get.lazyPut<PrescriptionItemController>(
      () => PrescriptionItemController(inventoryRepo: Get.find<InventoryRepository>()),
      fenix: true,
    );
    Get.lazyPut<FollowUpController>(() => FollowUpController());
    Get.lazyPut<FollowUpDetailController>(() => FollowUpDetailController());
  }
}
