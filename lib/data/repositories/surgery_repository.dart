import '../database/database_helper.dart';
import '../database/database_tables.dart';
import '../models/surgery_model.dart';

class SurgeryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<SurgeryModel>> getAllSurgeries() async {
    final db = await _dbHelper.database;
    const sql = '''
      SELECT 
        s.*, 
        p.name AS pet_name, 
        p.species AS pet_species,
        u.full_name AS surgeon_name,
        o.full_name AS owner_name,
        o.phone_primary AS owner_phone
      FROM ${DatabaseTables.tableSurgeries} s
      INNER JOIN ${DatabaseTables.tablePets} p ON s.pet_id = p.id
      INNER JOIN ${DatabaseTables.tableUsers} u ON s.lead_surgeon_id = u.id
      INNER JOIN ${DatabaseTables.tableOwners} o ON p.owner_id = o.id
      ORDER BY s.scheduled_date DESC
    ''';
    final res = await db.rawQuery(sql);
    return res.map((m) => SurgeryModel.fromMap(m)).toList();
  }

  Future<SurgeryModel?> getSurgeryById(int id) async {
    final db = await _dbHelper.database;
    final sql = '''
      SELECT 
        s.*, 
        p.name AS pet_name, 
        p.species AS pet_species,
        u.full_name AS surgeon_name,
        o.full_name AS owner_name,
        o.phone_primary AS owner_phone
      FROM ${DatabaseTables.tableSurgeries} s
      INNER JOIN ${DatabaseTables.tablePets} p ON s.pet_id = p.id
      INNER JOIN ${DatabaseTables.tableUsers} u ON s.lead_surgeon_id = u.id
      INNER JOIN ${DatabaseTables.tableOwners} o ON p.owner_id = o.id
      WHERE s.id = ?
      LIMIT 1
    ''';
    final res = await db.rawQuery(sql, [id]);
    if (res.isNotEmpty) {
      return SurgeryModel.fromMap(res.first);
    }
    return null;
  }

  Future<int> insertSurgery(SurgeryModel surgery) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseTables.tableSurgeries, surgery.toMap());
  }

  Future<int> updateSurgery(SurgeryModel surgery) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseTables.tableSurgeries,
      surgery.toMap(),
      where: 'id = ?',
      whereArgs: [surgery.id],
    );
  }

  Future<int> togglePreOpChecklist(int id, bool passed) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseTables.tableSurgeries,
      {'pre_op_checklist_passed': passed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateSurgeryStatus(int id, String status) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseTables.tableSurgeries,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSurgery(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseTables.tableSurgeries,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getTodaySurgeriesCount() async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final res = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${DatabaseTables.tableSurgeries} WHERE scheduled_date LIKE ?',
      ['$today%'],
    );
    return res.first['cnt'] as int? ?? 0;
  }
}
