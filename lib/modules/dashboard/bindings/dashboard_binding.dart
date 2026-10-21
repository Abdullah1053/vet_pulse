import 'package:get/get.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/consultation_repository.dart';
import '../../../data/repositories/financial_repository.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../data/repositories/reports_repository.dart';
import '../../../data/repositories/surgery_repository.dart';
import '../controllers/alerts_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/weekly_reports_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // Repositories
    Get.lazyPut<PetRepository>(() => PetRepository(), fenix: true);
    Get.lazyPut<FinancialRepository>(() => FinancialRepository(), fenix: true);
    Get.lazyPut<ConsultationRepository>(() => ConsultationRepository());
    Get.lazyPut<AppointmentRepository>(() => AppointmentRepository());
    Get.lazyPut<InventoryRepository>(() => InventoryRepository());
    Get.lazyPut<SurgeryRepository>(() => SurgeryRepository());
    Get.lazyPut<ReportsRepository>(() => ReportsRepository());

    // Controllers
    Get.lazyPut<DashboardController>(
      () => DashboardController(
        consultationRepo: Get.find<ConsultationRepository>(),
        appointmentRepo: Get.find<AppointmentRepository>(),
        inventoryRepo: Get.find<InventoryRepository>(),
        surgeryRepo: Get.find<SurgeryRepository>(),
      ),
    );

    Get.lazyPut<AlertsController>(
      () => AlertsController(
        appointmentRepo: Get.find<AppointmentRepository>(),
        surgeryRepo: Get.find<SurgeryRepository>(),
      ),
    );

    Get.lazyPut<WeeklyReportsController>(
      () => WeeklyReportsController(
        Get.find<ReportsRepository>(),
      ),
    );

    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }
  }
}
