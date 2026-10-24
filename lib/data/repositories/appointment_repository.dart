import 'package:get/get.dart';
import '../../core/services/data_sync_service.dart';
import '../../core/services/notification_service.dart';
import '../database/database_helper.dart';
import '../database/database_tables.dart';
import '../models/follow_up_model.dart';
import '../models/prescription_model.dart';

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
      ORDER BY f.scheduled_date DESC, f.id DESC
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
      ORDER BY f.scheduled_date DESC, f.id DESC
    ''';
    final res = await db.rawQuery(sql, [petId]);
    return res.map((m) => FollowUpModel.fromMap(m)).toList();
  }

  Future<int> insertFollowUp(FollowUpModel followUp) async {
    final db = await _dbHelper.database;
    final res = await db.insert(DatabaseTables.tableFollowUps, followUp.toMap());
    DataSyncService.notifyFollowUpChanged(petId: followUp.petId);
    if (Get.isRegistered<NotificationService>()) {
      NotificationService.to.scheduleFollowUpReminder(followUp.copyWith(id: res));
    }
    return res;
  }

  Future<int> updateFollowUp(FollowUpModel followUp) async {
    final db = await _dbHelper.database;
    final res = await db.update(
      DatabaseTables.tableFollowUps,
      followUp.toMap(),
      where: 'id = ?',
      whereArgs: [followUp.id],
    );
    DataSyncService.notifyFollowUpChanged(petId: followUp.petId);
    if (Get.isRegistered<NotificationService>()) {
      if (followUp.status == 'pending') {
        NotificationService.to.scheduleFollowUpReminder(followUp);
      } else if (followUp.id != null) {
        NotificationService.to.cancelFollowUpReminder(followUp.id!);
      }
    }
    return res;
  }

  Future<int> updateFollowUpStatus(int id, String status) async {
    final db = await _dbHelper.database;
    int? petId;
    try {
      final rows = await db.query(DatabaseTables.tableFollowUps, columns: ['pet_id'], where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) petId = rows.first['pet_id'] as int?;
    } catch (_) {}
    final res = await db.update(
      DatabaseTables.tableFollowUps,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
    DataSyncService.notifyFollowUpChanged(petId: petId);
    if (status != 'pending' && Get.isRegistered<NotificationService>()) {
      NotificationService.to.cancelFollowUpReminder(id);
    }
    return res;
  }

  Future<int> markReminderSent(int id) async {
    final db = await _dbHelper.database;
    int? petId;
    try {
      final rows = await db.query(DatabaseTables.tableFollowUps, columns: ['pet_id'], where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) petId = rows.first['pet_id'] as int?;
    } catch (_) {}
    final res = await db.update(
      DatabaseTables.tableFollowUps,
      {'reminder_sent': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    DataSyncService.notifyFollowUpChanged(petId: petId);
    return res;
  }

  Future<int> deleteFollowUp(int id) async {
    final db = await _dbHelper.database;
    int? petId;
    try {
      final rows = await db.query(DatabaseTables.tableFollowUps, columns: ['pet_id'], where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) petId = rows.first['pet_id'] as int?;
    } catch (_) {}
    final res = await db.delete(
      DatabaseTables.tableFollowUps,
      where: 'id = ?',
      whereArgs: [id],
    );
    DataSyncService.notifyFollowUpChanged(petId: petId);
    if (Get.isRegistered<NotificationService>()) {
      NotificationService.to.cancelFollowUpReminder(id);
    }
    return res;
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

  Future<List<Map<String, dynamic>>> getPendingFollowUpsForAlerts() async {
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
      WHERE f.status = 'pending'
    ''';
    return await db.rawQuery(sql);
  }

  Future<FollowUpModel?> getFollowUpById(int id) async {
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
      WHERE f.id = ?
      LIMIT 1
    ''';
    final res = await db.rawQuery(sql, [id]);
    if (res.isNotEmpty) {
      return FollowUpModel.fromMap(res.first);
    }
    return null;
  }

  Future<void> completeFollowUpWithTreatment({
    required FollowUpModel followUp,
    required String clinicalNotes,
    List<PrescriptionModel> administeredTreatments = const [],
    double followUpCost = 0.0,
    double paidAmount = 0.0,
    double remainingAmount = 0.0,
    String paymentMethod = 'نقدا',
    FollowUpModel? nextFollowUp,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Update FollowUpModel status to completed and append clinical notes & treatment summary
      final updatedNotesBuffer = StringBuffer();
      if (followUp.notes != null && followUp.notes!.isNotEmpty) {
        updatedNotesBuffer.writeln(followUp.notes);
      }
      if (clinicalNotes.isNotEmpty) {
        updatedNotesBuffer.writeln('[ملاحظات المراجعة السريرية]: $clinicalNotes');
      }
      if (administeredTreatments.isNotEmpty) {
        final medSummary = administeredTreatments
            .map((t) => '${t.displayName} (${t.dosage} - ${t.route ?? "حقن/موضعي"} - كمية: ${t.quantityDispensed})')
            .join('، ');
        updatedNotesBuffer.writeln('[العلاجات والحقن المصروفة بالعيادة]: $medSummary');
      }

      await txn.update(
        DatabaseTables.tableFollowUps,
        {
          'status': 'completed',
          'notes': updatedNotesBuffer.toString().trim(),
        },
        where: 'id = ?',
        whereArgs: [followUp.id],
      );

      // 2. Automatically deduct quantityDispensed from clinic_stock in tableMedicines
      for (final treatment in administeredTreatments) {
        if (treatment.medicineId != null && treatment.medicineId! > 0) {
          await txn.rawUpdate('''
            UPDATE ${DatabaseTables.tableMedicines}
            SET clinic_stock = MAX(0, clinic_stock - ?)
            WHERE id = ?
          ''', [treatment.quantityDispensed, treatment.medicineId]);
        }
      }

      // 3. Financial transaction & payment recording
      if (followUpCost > 0) {
        int? ownerId;
        final petRows = await txn.query(
          DatabaseTables.tablePets,
          columns: ['owner_id'],
          where: 'id = ?',
          whereArgs: [followUp.petId],
        );
        if (petRows.isNotEmpty) {
          ownerId = petRows.first['owner_id'] as int?;
        }

        final txId = await txn.insert(
          DatabaseTables.tableTransactions,
          {
            'transaction_type': 'income',
            'category': 'consultation',
            'owner_id': ownerId,
            'pet_id': followUp.petId,
            'reference_id': followUp.id,
            'reference_type': 'follow_up',
            'amount': followUpCost,
            'paid_amount': paidAmount,
            'remaining_amount': remainingAmount,
            'payment_method': paymentMethod,
            'transaction_date': DateTime.now().toIso8601String(),
            'notes': 'مراجعة سريرية: ${followUp.reason}',
          },
        );

        if (paidAmount > 0) {
          await txn.insert(
            DatabaseTables.tableCustomerPayments,
            {
              'owner_id': ownerId,
              'transaction_id': txId,
              'amount': paidAmount,
              'payment_method': paymentMethod,
              'payment_date': DateTime.now().toIso8601String(),
              'receipt_number': 'REC-FU-${followUp.id}-1',
              'notes': 'سداد مراجعة سريرية: ${followUp.reason}',
            },
          );
        }
      }

      // 4. Insert optional next follow-up appointment
      if (nextFollowUp != null) {
        final nextId = await txn.insert(
          DatabaseTables.tableFollowUps,
          nextFollowUp.toMap(),
        );
        if (Get.isRegistered<NotificationService>()) {
          NotificationService.to.scheduleFollowUpReminder(nextFollowUp.copyWith(id: nextId));
        }
      }
    });

    // 5. Cancel OS notification reminder for completed follow-up
    if (followUp.id != null && Get.isRegistered<NotificationService>()) {
      NotificationService.to.cancelFollowUpReminder(followUp.id!);
    }

    // 6. Notify DataSyncService
    DataSyncService.notifyFollowUpChanged(petId: followUp.petId);
    if (administeredTreatments.isNotEmpty) {
      DataSyncService.notifyInventoryChanged();
    }
    if (followUpCost > 0) {
      DataSyncService.notifyFinancialChanged();
    }
  }

  Future<int> markFollowUpMissed(int id, {String? missedNote}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(DatabaseTables.tableFollowUps, where: 'id = ?', whereArgs: [id]);
    int? petId;
    String existingNotes = '';
    if (rows.isNotEmpty) {
      petId = rows.first['pet_id'] as int?;
      existingNotes = (rows.first['notes'] as String?) ?? '';
    }
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final noteToAdd = missedNote ?? 'تغيب عن الحضور في $todayStr';
    final newNotes = existingNotes.isEmpty ? '[لم يحضر الموعد]: $noteToAdd' : '$existingNotes\n[لم يحضر الموعد]: $noteToAdd';

    final res = await db.update(
      DatabaseTables.tableFollowUps,
      {
        'status': 'missed',
        'notes': newNotes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    DataSyncService.notifyFollowUpChanged(petId: petId);
    if (Get.isRegistered<NotificationService>()) {
      NotificationService.to.cancelFollowUpReminder(id);
    }
    return res;
  }

  Future<List<int>> resumeFollowUpSchedule({
    required FollowUpModel missedFollowUp,
    required String newStartDate,
    required String scheduledTime,
    required int newDaysCount,
  }) async {
    final db = await _dbHelper.database;
    final newIds = await db.transaction((txn) async {
      // 1. Update the missed follow-up notes to record resumption
      final existingNotes = missedFollowUp.notes ?? '';
      final updatedNotes = existingNotes.isEmpty
          ? '[تم استئناف الجدولة بتاريخ $newStartDate]'
          : '$existingNotes\n[تم استئناف الجدولة بتاريخ $newStartDate]';
      await txn.update(
        DatabaseTables.tableFollowUps,
        {'notes': updatedNotes},
        where: 'id = ?',
        whereArgs: [missedFollowUp.id],
      );

      // 2. Generate new consecutive follow-up records
      final startDate = DateTime.tryParse(newStartDate) ?? DateTime.now();
      final List<int> ids = [];
      for (int i = 0; i < newDaysCount; i++) {
        final date = startDate.add(Duration(days: i)).toIso8601String().substring(0, 10);
        final sessionLabel = newDaysCount > 1
            ? ' (استئناف الجلسات - اليوم ${i + 1} من $newDaysCount)'
            : ' (استئناف الموعد)';
        final newFollowUp = FollowUpModel(
          petId: missedFollowUp.petId,
          consultationId: missedFollowUp.consultationId,
          scheduledDate: date,
          scheduledTime: scheduledTime,
          reason: '${missedFollowUp.reason}$sessionLabel',
          status: 'pending',
          notes: 'تمت إعادة الجدولة بعد تغيب موعد سابق',
        );
        final id = await txn.insert(DatabaseTables.tableFollowUps, newFollowUp.toMap());
        ids.add(id);
      }
      return ids;
    });

    DataSyncService.notifyFollowUpChanged(petId: missedFollowUp.petId);
    return newIds;
  }

  Future<Map<String, dynamic>?> getFollowUpFinancialSummary(int followUpId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.tableTransactions,
      where: 'reference_type = ? AND reference_id = ?',
      whereArgs: ['follow_up', followUpId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final tx = rows.first;
      return {
        'totalCost': (tx['amount'] as num?)?.toDouble() ?? 0.0,
        'paidAmount': (tx['paid_amount'] as num?)?.toDouble() ?? 0.0,
        'remainingAmount': (tx['remaining_amount'] as num?)?.toDouble() ?? 0.0,
        'paymentMethod': (tx['payment_method'] as String?) ?? 'نقدا',
      };
    }
    return null;
  }
}
