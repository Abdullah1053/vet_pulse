import 'package:get/get.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/financial_repository.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../data/repositories/surgery_repository.dart';
import '../../consultations/controllers/prescription_item_controller.dart';
import '../controllers/complete_surgery_controller.dart';
import '../controllers/surgery_detail_controller.dart';
import '../controllers/surgery_follow_up_controller.dart';
import '../controllers/surgery_form_controller.dart';
import '../controllers/surgery_list_controller.dart';

class SurgeryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PetRepository>(() => PetRepository(), fenix: true);
    Get.lazyPut<FinancialRepository>(() => FinancialRepository(), fenix: true);
    Get.lazyPut<InventoryRepository>(() => InventoryRepository(), fenix: true);
    Get.lazyPut<SurgeryRepository>(() => SurgeryRepository());
    Get.lazyPut<AuthRepository>(() => AuthRepository());
    Get.lazyPut<AppointmentRepository>(() => AppointmentRepository());

    Get.lazyPut<SurgeryListController>(
      () => SurgeryListController(Get.find<SurgeryRepository>()),
    );
    Get.lazyPut<SurgeryDetailController>(
      () => SurgeryDetailController(
        surgeryRepo: Get.find<SurgeryRepository>(),
        appointmentRepo: Get.find<AppointmentRepository>(),
      ),
    );
    Get.lazyPut<SurgeryFormController>(
      () => SurgeryFormController(
        Get.find<SurgeryRepository>(),
        Get.find<PetRepository>(),
        Get.find<AuthRepository>(),
      ),
    );
    Get.lazyPut<PrescriptionItemController>(
      () => PrescriptionItemController(
        inventoryRepo: Get.find<InventoryRepository>(),
      ),
    );
    Get.lazyPut<CompleteSurgeryController>(
      () => CompleteSurgeryController(
        Get.find<SurgeryRepository>(),
        prescriptionController: Get.find<PrescriptionItemController>(),
      ),
    );
    Get.lazyPut<SurgeryFollowUpController>(
      () => SurgeryFollowUpController(),
    );
  }
}
