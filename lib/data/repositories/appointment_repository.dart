import '../database/database_helper.dart';
import '../database/database_tables.dart';
import '../models/follow_up_model.dart';

class AppointmentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<FollowUpModel>> getAllFollowUps() async {
    final db = await _dbHelper.database;
    const sql = '''
      SELECT 
        f.*, 
        p.name AS pet_name, 
        p.species AS pet_species,
        o.full_name AS owner_name,
        o.phone_primary AS owner_phone
      FROM ${DatabaseTables.tableFollowUps} f
      INNER JOIN ${DatabaseTables.tablePets} p ON f.pet_id = p.id
      INNER JOIN ${DatabaseTables.tableOwners} o ON p.owner_id = o.id
      ORDER BY f.scheduled_date ASC
    ''';
    final res = await db.rawQuery(sql);
    return res.map((m) => FollowUpModel.fromMap(m)).toList();
  }

  Future<List<FollowUpModel>> getFollowUpsByFilter(String filter) async {
    final all = await getAllFollowUps();
    switch (filter) {
      case 'overdue':
        return all.where((f) => f.isOverdue).toList();
      case 'today':
        return all.where((f) => f.isToday && f.isPending).toList();
      case 'upcoming':
        return all.where((f) => !f.isOverdue && f.isPending && !f.isToday).toList();
      case 'all':
      default:
        return all;
    }
  }

  Future<List<FollowUpModel>> getFollowUpsForPet(int petId) async {
    final db = await _dbHelper.database;
    const sql = '''
      SELECT 
        f.*, 
        p.name AS pet_name, 
        p.species AS pet_species,
        o.full_name AS owner_name,
        o.phone_primary AS owner_phone
      FROM ${DatabaseTables.tableFollowUps} f
      INNER JOIN ${DatabaseTables.tablePets} p ON f.pet_id = p.id
      INNER JOIN ${DatabaseTables.tableOwners} o ON p.owner_id = o.id
      WHERE f.pet_id = ?
      ORDER BY f.scheduled_date DESC
    ''';
    final res = await db.rawQuery(sql, [petId]);
    return res.map((m) => FollowUpModel.fromMap(m)).toList();
  }

  Future<int> insertFollowUp(FollowUpModel followUp) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseTables.tableFollowUps, followUp.toMap());
  }

  Future<int> updateFollowUp(FollowUpModel followUp) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseTables.tableFollowUps,
      followUp.toMap(),
      where: 'id = ?',
      whereArgs: [followUp.id],
    );
  }

  Future<int> updateFollowUpStatus(int id, String status) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseTables.tableFollowUps,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markReminderSent(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseTables.tableFollowUps,
      {'reminder_sent': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteFollowUp(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseTables.tableFollowUps,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getPendingTodayCount() async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final res = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${DatabaseTables.tableFollowUps} WHERE scheduled_date = ? AND status = "pending"',
      [today],
    );
    return res.first['cnt'] as int? ?? 0;
  }
}
