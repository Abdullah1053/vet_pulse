import '../database/database_helper.dart';
import '../database/database_tables.dart';

class ReportsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Map<String, dynamic>> getConsultationsSummary(String startStr, String endStr) async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery('''
      SELECT COUNT(*) as count, COALESCE(SUM(visit_cost), 0) as revenue
      FROM ${DatabaseTables.tableConsultations}
      WHERE substr(visit_date, 1, 10) >= ? AND substr(visit_date, 1, 10) <= ?
    ''', [startStr, endStr]);
    return res.isNotEmpty ? res.first : {'count': 0, 'revenue': 0.0};
  }

  Future<int> getNewPatientsCount(String startStr, String endStr) async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM ${DatabaseTables.tablePets}
      WHERE substr(created_at, 1, 10) >= ? AND substr(created_at, 1, 10) <= ?
    ''', [startStr, endStr]);
    return res.isNotEmpty ? (res.first['count'] as int? ?? 0) : 0;
  }

  Future<Map<String, dynamic>> getSurgeriesSummary(String startStr, String endStr) async {
    final db = await _dbHelper.database;
    final res = await db.rawQuery('''
      SELECT COUNT(*) as count, COALESCE(SUM(estimated_cost), 0) as surgery_rev
      FROM ${DatabaseTables.tableSurgeries}
      WHERE substr(scheduled_date, 1, 10) >= ? AND substr(scheduled_date, 1, 10) <= ?
    ''', [startStr, endStr]);
    return res.isNotEmpty ? res.first : {'count': 0, 'surgery_rev': 0.0};
  }

  Future<List<Map<String, dynamic>>> getTopDiagnoses(String startStr, String endStr, {int limit = 5}) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT diagnosis, COUNT(*) as count
      FROM ${DatabaseTables.tableConsultations}
      WHERE substr(visit_date, 1, 10) >= ? AND substr(visit_date, 1, 10) <= ?
      GROUP BY diagnosis
      ORDER BY count DESC
      LIMIT ?
    ''', [startStr, endStr, limit]);
  }

  Future<List<Map<String, dynamic>>> getTopClinicMedicines(String startStr, String endStr, {int limit = 5}) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
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
      LIMIT ?
    ''', [startStr, endStr, limit]);
  }

  Future<List<Map<String, dynamic>>> getSpeciesBreakdown(String startStr, String endStr) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT p.species, COUNT(*) as count
      FROM ${DatabaseTables.tableConsultations} c
      INNER JOIN ${DatabaseTables.tablePets} p ON c.pet_id = p.id
      WHERE substr(c.visit_date, 1, 10) >= ? AND substr(c.visit_date, 1, 10) <= ?
      GROUP BY p.species
      ORDER BY count DESC
    ''', [startStr, endStr]);
  }

  Future<List<Map<String, dynamic>>> getDailyActivity(String startStr, String endStr) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT 
        substr(visit_date, 1, 10) as day_date, 
        COUNT(*) as visits_count,
        SUM(visit_cost) as day_revenue
      FROM ${DatabaseTables.tableConsultations}
      WHERE substr(visit_date, 1, 10) >= ? AND substr(visit_date, 1, 10) <= ?
      GROUP BY day_date
      ORDER BY day_date ASC
    ''', [startStr, endStr]);
  }
}
