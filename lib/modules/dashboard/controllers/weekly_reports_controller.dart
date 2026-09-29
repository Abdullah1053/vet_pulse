import 'package:get/get.dart';
import '../../../data/database/database_helper.dart';
import '../../../data/database/database_tables.dart';

class WeeklyReportsController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

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

      final db = await _dbHelper.database;

      // 1. Total Consultations & Revenue
      final consultRes = await db.rawQuery('''
        SELECT COUNT(*) as count, COALESCE(SUM(visit_cost), 0) as revenue
        FROM ${DatabaseTables.tableConsultations}
        WHERE substr(visit_date, 1, 10) >= ? AND substr(visit_date, 1, 10) <= ?
      ''', [startStr, endStr]);

      totalConsultations.value = consultRes.first['count'] as int? ?? 0;
      totalRevenue.value = (consultRes.first['revenue'] as num?)?.toDouble() ?? 0.0;

      // 2. New Patients
      final patientRes = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM ${DatabaseTables.tablePets}
        WHERE substr(created_at, 1, 10) >= ? AND substr(created_at, 1, 10) <= ?
      ''', [startStr, endStr]);
      newPatients.value = patientRes.first['count'] as int? ?? 0;

      // 3. Surgeries
      final surgeryRes = await db.rawQuery('''
        SELECT COUNT(*) as count, COALESCE(SUM(estimated_cost), 0) as surgery_rev
        FROM ${DatabaseTables.tableSurgeries}
        WHERE substr(scheduled_date, 1, 10) >= ? AND substr(scheduled_date, 1, 10) <= ?
      ''', [startStr, endStr]);
      totalSurgeries.value = surgeryRes.first['count'] as int? ?? 0;
      final surgeryRev = (surgeryRes.first['surgery_rev'] as num?)?.toDouble() ?? 0.0;
      totalRevenue.value += surgeryRev;

      // 4. Top Diagnoses
      final diagRes = await db.rawQuery('''
        SELECT diagnosis, COUNT(*) as count
        FROM ${DatabaseTables.tableConsultations}
        WHERE substr(visit_date, 1, 10) >= ? AND substr(visit_date, 1, 10) <= ?
        GROUP BY diagnosis
        ORDER BY count DESC
        LIMIT 5
      ''', [startStr, endStr]);
      topDiagnoses.assignAll(diagRes);

      // 5. Most Administered Clinic Injections
      final clinicMedRes = await db.rawQuery('''
        SELECT 
          COALESCE(m.trade_name, pr.custom_name, 'إبرة/علاج') as med_name,
          SUM(pr.quantity_dispensed) as total_qty
        FROM ${DatabaseTables.tablePrescriptions} pr
        LEFT JOIN ${DatabaseTables.tableMedicines} m ON pr.medicine_id = m.id
        INNER JOIN ${DatabaseTables.tableConsultations} c ON pr.consultation_id = c.id
        WHERE pr.is_clinic_administered = 1
          AND substr(c.visit_date, 1, 10) >= ? AND substr(c.visit_date, 1, 10) <= ?
        GROUP BY med_name
        ORDER BY total_qty DESC
        LIMIT 5
      ''', [startStr, endStr]);
      topClinicMedicines.assignAll(clinicMedRes);

      // 6. Species Breakdown
      final specRes = await db.rawQuery('''
        SELECT p.species, COUNT(*) as count
        FROM ${DatabaseTables.tableConsultations} c
        INNER JOIN ${DatabaseTables.tablePets} p ON c.pet_id = p.id
        WHERE substr(c.visit_date, 1, 10) >= ? AND substr(c.visit_date, 1, 10) <= ?
        GROUP BY p.species
        ORDER BY count DESC
      ''', [startStr, endStr]);
      speciesBreakdown.assignAll(specRes);

      // 7. Daily Activity
      final dailyRes = await db.rawQuery('''
        SELECT 
          substr(visit_date, 1, 10) as day_date, 
          COUNT(*) as visits_count,
          SUM(visit_cost) as day_revenue
        FROM ${DatabaseTables.tableConsultations}
        WHERE substr(visit_date, 1, 10) >= ? AND substr(visit_date, 1, 10) <= ?
        GROUP BY day_date
        ORDER BY day_date ASC
      ''', [startStr, endStr]);
      dailyActivity.assignAll(dailyRes);

    } finally {
      isLoading.value = false;
    }
  }
}
