import 'package:get/get.dart';
import '../../../data/repositories/reports_repository.dart';

class WeeklyReportsController extends GetxController {
  final ReportsRepository _reportsRepo;

  WeeklyReportsController([ReportsRepository? reportsRepo])
      : _reportsRepo = reportsRepo ?? ReportsRepository();

  final RxInt weekOffset = 0.obs; // 0 = current week, 1 = 1 week ago, etc.
  final RxString weekRangeText = ''.obs;

  final RxInt totalConsultations = 0.obs;
  final RxInt newPatients = 0.obs;
  final RxInt totalSurgeries = 0.obs;
  final RxDouble totalRevenue = 0.0.obs;

  final RxList<Map<String, dynamic>> topDiagnoses = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> topClinicMedicines = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> speciesBreakdown = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> dailyActivity = <Map<String, dynamic>>[].obs;

  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadWeeklyReport();
  }

  void previousWeek() {
    weekOffset.value++;
    loadWeeklyReport();
  }

  void nextWeek() {
    if (weekOffset.value > 0) {
      weekOffset.value--;
      loadWeeklyReport();
    }
  }

  Future<void> loadWeeklyReport() async {
    isLoading.value = true;
    try {
      final now = DateTime.now();
      // Calculate start and end of selected week (7 days window)
      final endDay = now.subtract(Duration(days: weekOffset.value * 7));
      final startDay = endDay.subtract(const Duration(days: 6));

      final startStr = '${startDay.year}-${startDay.month.toString().padLeft(2, '0')}-${startDay.day.toString().padLeft(2, '0')}';
      final endStr = '${endDay.year}-${endDay.month.toString().padLeft(2, '0')}-${endDay.day.toString().padLeft(2, '0')}';

      weekRangeText.value = '$startStr  إلى  $endStr';

      // 1. Total Consultations & Revenue
      final consultRes = await _reportsRepo.getConsultationsSummary(startStr, endStr);
      totalConsultations.value = consultRes['count'] as int? ?? 0;
      totalRevenue.value = (consultRes['revenue'] as num?)?.toDouble() ?? 0.0;

      // 2. New Patients
      newPatients.value = await _reportsRepo.getNewPatientsCount(startStr, endStr);

      // 3. Surgeries
      final surgeryRes = await _reportsRepo.getSurgeriesSummary(startStr, endStr);
      totalSurgeries.value = surgeryRes['count'] as int? ?? 0;
      final surgeryRev = (surgeryRes['surgery_rev'] as num?)?.toDouble() ?? 0.0;
      totalRevenue.value += surgeryRev;

      // 4. Top Diagnoses
      final diagRes = await _reportsRepo.getTopDiagnoses(startStr, endStr);
      topDiagnoses.assignAll(diagRes);

      // 5. Most Administered Clinic Injections
      final clinicMedRes = await _reportsRepo.getTopClinicMedicines(startStr, endStr);
      topClinicMedicines.assignAll(clinicMedRes);

      // 6. Species Breakdown
      final specRes = await _reportsRepo.getSpeciesBreakdown(startStr, endStr);
      speciesBreakdown.assignAll(specRes);

      // 7. Daily Activity
      final dailyRes = await _reportsRepo.getDailyActivity(startStr, endStr);
      dailyActivity.assignAll(dailyRes);

    } finally {
      isLoading.value = false;
    }
  }
}
