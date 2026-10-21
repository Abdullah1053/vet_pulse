import 'package:get/get.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/consultation_repository.dart';
import '../../../data/repositories/financial_repository.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../data/repositories/surgery_repository.dart';
import '../controllers/consultation_controller.dart';
import '../controllers/consultation_detail_controller.dart';
import '../controllers/consultations_list_controller.dart';
import '../controllers/new_consultation_controller.dart';
import '../controllers/prescription_item_controller.dart';

class ConsultationBinding extends Bindings {
  @override
  void dependencies() {
    // Repositories
    Get.lazyPut<PetRepository>(() => PetRepository(), fenix: true);
    Get.lazyPut<FinancialRepository>(() => FinancialRepository(), fenix: true);
    Get.lazyPut<ConsultationRepository>(() => ConsultationRepository());
    Get.lazyPut<InventoryRepository>(() => InventoryRepository());
    Get.lazyPut<AuthRepository>(() => AuthRepository());
    Get.lazyPut<SurgeryRepository>(() => SurgeryRepository());
    Get.lazyPut<AppointmentRepository>(() => AppointmentRepository());

    // Controllers
    Get.lazyPut<PrescriptionItemController>(
      () => PrescriptionItemController(
        inventoryRepo: Get.find<InventoryRepository>(),
      ),
    );

    Get.lazyPut<NewConsultationController>(
      () => NewConsultationController(
        consultationRepo: Get.find<ConsultationRepository>(),
        petRepo: Get.find<PetRepository>(),
        authRepo: Get.find<AuthRepository>(),
        surgeryRepo: Get.find<SurgeryRepository>(),
        appointmentRepo: Get.find<AppointmentRepository>(),
        prescriptionController: Get.find<PrescriptionItemController>(),
      ),
    );

    Get.lazyPut<ConsultationController>(
      () => Get.find<NewConsultationController>(),
    );

    Get.lazyPut<ConsultationDetailController>(
      () => ConsultationDetailController(
        consultationRepo: Get.find<ConsultationRepository>(),
        petRepo: Get.find<PetRepository>(),
      ),
    );

    Get.lazyPut<ConsultationsListController>(
      () => ConsultationsListController(
        Get.find<ConsultationRepository>(),
      ),
    );
  }
}
