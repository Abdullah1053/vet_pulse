import '../../core/services/data_sync_service.dart';
import '../database/database_helper.dart';
import '../database/database_tables.dart';
import '../models/follow_up_model.dart';
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

  Future<List<SurgeryModel>> getSurgeriesForPet(int petId) async {
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
      LEFT JOIN ${DatabaseTables.tableUsers} u ON s.lead_surgeon_id = u.id
      INNER JOIN ${DatabaseTables.tableOwners} o ON p.owner_id = o.id
      WHERE s.pet_id = ?
      ORDER BY s.scheduled_date DESC
    ''';
    final res = await db.rawQuery(sql, [petId]);
    return res.map((m) => SurgeryModel.fromMap(m)).toList();
  }

  Future<int> insertSurgery(SurgeryModel surgery) async {
    final db = await _dbHelper.database;
    final res = await db.insert(DatabaseTables.tableSurgeries, surgery.toMap());
    DataSyncService.notifySurgeryChanged(petId: surgery.petId);
    return res;
  }

  Future<int> updateSurgery(SurgeryModel surgery) async {
    final db = await _dbHelper.database;
    final res = await db.update(
      DatabaseTables.tableSurgeries,
      surgery.toMap(),
      where: 'id = ?',
      whereArgs: [surgery.id],
    );
    DataSyncService.notifySurgeryChanged(petId: surgery.petId);
    return res;
  }

  Future<void> completeSurgeryWithBilling({
    required SurgeryModel surgery,
    required double finalCost,
    double paidAmount = 0.0,
    String paymentMethod = 'نقدا',
    FollowUpModel? followUp,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Update Surgery record to completed
      await txn.update(
        DatabaseTables.tableSurgeries,
        surgery.toMap(),
        where: 'id = ?',
        whereArgs: [surgery.id],
      );

      // 2. Insert Follow-up if requested
      if (followUp != null) {
        await txn.insert(
          DatabaseTables.tableFollowUps,
          followUp.toMap(),
        );
      }

      // 3. Atomically record income transaction in financial ledger
      if (finalCost > 0) {
        final existingTx = await txn.query(
          DatabaseTables.tableTransactions,
          where: 'reference_type = ? AND reference_id = ?',
          whereArgs: ['surgery', surgery.id],
          limit: 1,
        );

        if (existingTx.isEmpty) {
          final petRows = await txn.query(
            DatabaseTables.tablePets,
            columns: ['owner_id'],
            where: 'id = ?',
            whereArgs: [surgery.petId],
            limit: 1,
          );
          final ownerId = petRows.isNotEmpty ? petRows.first['owner_id'] as int? : null;
          final paid = paidAmount.clamp(0.0, finalCost);
          final remaining = (finalCost - paid).clamp(0.0, double.infinity);

          final txId = await txn.insert(DatabaseTables.tableTransactions, {
            'transaction_type': 'income',
            'category': 'surgery',
            'owner_id': ownerId,
            'pet_id': surgery.petId,
            'reference_id': surgery.id,
            'reference_type': 'surgery',
            'amount': finalCost,
            'paid_amount': paid,
            'remaining_amount': remaining,
            'payment_method': paymentMethod,
            'transaction_date': DateTime.now().toIso8601String(),
            'notes': 'أتعاب عملية جراحية: ${surgery.surgeryName}${remaining > 0 ? ' (متبقي آجل: ${remaining.toStringAsFixed(0)} ر.ي)' : ' (خالص ومسدد بالكامل)'}',
          });

          // Record in customer_payments if an initial payment was made
          if (paid > 0 && ownerId != null) {
            await txn.insert(DatabaseTables.tableCustomerPayments, {
              'owner_id': ownerId,
              'transaction_id': txId,
              'amount': paid,
              'payment_method': paymentMethod,
              'payment_date': DateTime.now().toIso8601String(),
              'receipt_number': 'REC-SURG-${surgery.id}-1',
              'notes': 'دفعة مسددة عند اعتماد وإنهاء العملية الجراحية (${surgery.surgeryName})',
            });
          }
        }
      }
    });

    DataSyncService.notifySurgeryChanged(petId: surgery.petId);
    if (followUp != null) {
      DataSyncService.notifyFollowUpChanged(petId: surgery.petId);
    }
  }

  Future<int> togglePreOpChecklist(int id, bool passed) async {
    final db = await _dbHelper.database;
    int? petId;
    try {
      final rows = await db.query(DatabaseTables.tableSurgeries, columns: ['pet_id'], where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) petId = rows.first['pet_id'] as int?;
    } catch (_) {}
    final res = await db.update(
      DatabaseTables.tableSurgeries,
      {'pre_op_checklist_passed': passed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    DataSyncService.notifySurgeryChanged(petId: petId);
    return res;
  }

  Future<int> updateSurgeryStatus(int id, String status) async {
    final db = await _dbHelper.database;
    int? petId;
    try {
      final rows = await db.query(DatabaseTables.tableSurgeries, columns: ['pet_id'], where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) petId = rows.first['pet_id'] as int?;
    } catch (_) {}
    final res = await db.update(
      DatabaseTables.tableSurgeries,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
    DataSyncService.notifySurgeryChanged(petId: petId);
    return res;
  }

  Future<int> deleteSurgery(int id) async {
    final db = await _dbHelper.database;
    int? petId;
    try {
      final rows = await db.query(DatabaseTables.tableSurgeries, columns: ['pet_id'], where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) petId = rows.first['pet_id'] as int?;
    } catch (_) {}
    final res = await db.delete(
      DatabaseTables.tableSurgeries,
      where: 'id = ?',
      whereArgs: [id],
    );
    DataSyncService.notifySurgeryChanged(petId: petId);
    return res;
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

  Future<List<Map<String, dynamic>>> getScheduledSurgeriesForAlerts() async {
    final db = await _dbHelper.database;
    const sql = '''
      SELECT 
        s.*, 
        p.name AS pet_name, 
        p.species AS pet_species,
        o.full_name AS owner_name, 
        o.phone_primary AS owner_phone
      FROM ${DatabaseTables.tableSurgeries} s
      INNER JOIN ${DatabaseTables.tablePets} p ON s.pet_id = p.id
      INNER JOIN ${DatabaseTables.tableOwners} o ON p.owner_id = o.id
      WHERE s.status = 'scheduled'
    ''';
    return await db.rawQuery(sql);
  }
}
