import 'package:get/get.dart';
import '../../../core/services/license_service.dart';
import '../../../data/models/consultation_model.dart';
import '../../../data/models/medicine_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/consultation_repository.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../../data/repositories/surgery_repository.dart';
import '../../../routes/app_routes.dart';

class DashboardController extends GetxController {
  final ConsultationRepository _consultationRepo;
  final AppointmentRepository _appointmentRepo;
  final InventoryRepository _inventoryRepo;
  final SurgeryRepository _surgeryRepo;

  DashboardController({
    ConsultationRepository? consultationRepo,
    AppointmentRepository? appointmentRepo,
    InventoryRepository? inventoryRepo,
    SurgeryRepository? surgeryRepo,
  })  : _consultationRepo = consultationRepo ?? ConsultationRepository(),
        _appointmentRepo = appointmentRepo ?? AppointmentRepository(),
        _inventoryRepo = inventoryRepo ?? InventoryRepository(),
        _surgeryRepo = surgeryRepo ?? SurgeryRepository();

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
    final licenseStatus = await LicenseService.to.checkLicenseValidity();
    if (licenseStatus == LicenseStatus.expired || !LicenseService.to.isLicenseActive.value) {
      Get.offAllNamed(AppRoutes.activation);
      return;
    }

    isLoading.value = true;
    try {
      todaySurgeries.value = await _surgeryRepo.getScheduledSurgeriesCount();
      pendingFollowUps.value = await _appointmentRepo.getPendingTodayCount();

      final lowStock = await _inventoryRepo.getLowStockMedicines();
      lowStockCount.value = lowStock.length;

      final expiring = await _inventoryRepo.getExpiringOrExpiredMedicines();
      expiringMedsCount.value = expiring.length;
      alertMedicines.assignAll(expiring.take(5));

      final allVisits = await _consultationRepo.getAllConsultations();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final todayVisitsList = allVisits.where((c) => c.visitDate.startsWith(todayStr)).toList();
      recentConsultations.assignAll(todayVisitsList);
      todayVisits.value = todayVisitsList.length;
    } finally {
      isLoading.value = false;
    }
  }
}
