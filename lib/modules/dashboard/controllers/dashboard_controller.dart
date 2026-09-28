import 'package:get/get.dart';
import '../../../data/models/consultation_model.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/consultation_repository.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../../data/repositories/surgery_repository.dart';

class DashboardController extends GetxController {
  final ConsultationRepository _consultationRepo = ConsultationRepository();
  final AppointmentRepository _appointmentRepo = AppointmentRepository();
  final InventoryRepository _inventoryRepo = InventoryRepository();
  final SurgeryRepository _surgeryRepo = SurgeryRepository();

  final RxInt todayVisits = 0.obs;
  final RxInt todaySurgeries = 0.obs;
  final RxInt pendingFollowUps = 0.obs;
  final RxInt lowStockCount = 0.obs;
  final RxInt expiringMedsCount = 0.obs;

  final RxList<ConsultationModel> recentConsultations = <ConsultationModel>[].obs;
  final RxList<MedicineModel> alertMedicines = <MedicineModel>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    isLoading.value = true;
    try {
      todayVisits.value = await _consultationRepo.getTodayConsultationsCount();
      todaySurgeries.value = await _surgeryRepo.getTodaySurgeriesCount();
      pendingFollowUps.value = await _appointmentRepo.getPendingTodayCount();

      final lowStock = await _inventoryRepo.getLowStockMedicines();
      lowStockCount.value = lowStock.length;

      final expiring = await _inventoryRepo.getExpiringOrExpiredMedicines();
      expiringMedsCount.value = expiring.length;
      alertMedicines.assignAll(expiring.take(5));

      final allVisits = await _consultationRepo.getAllConsultations();
      recentConsultations.assignAll(allVisits.take(5));
    } finally {
      isLoading.value = false;
    }
  }
}
