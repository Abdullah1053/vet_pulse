import '../database/database_helper.dart';
import '../database/database_tables.dart';
import '../models/consultation_model.dart';
import '../models/prescription_model.dart';

class ConsultationRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<ConsultationModel>> getAllConsultations() async {
    final db = await _dbHelper.database;
    const sql = '''
      SELECT 
        c.*, 
        p.name AS pet_name, 
        p.species AS pet_species,
        u.full_name AS doctor_name,
        o.full_name AS owner_name
      FROM ${DatabaseTables.tableConsultations} c
      INNER JOIN ${DatabaseTables.tablePets} p ON c.pet_id = p.id
      INNER JOIN ${DatabaseTables.tableUsers} u ON c.doctor_id = u.id
      INNER JOIN ${DatabaseTables.tableOwners} o ON p.owner_id = o.id
      ORDER BY c.visit_date DESC, c.id DESC
    ''';
    final res = await db.rawQuery(sql);
    
    List<ConsultationModel> list = [];
    for (final row in res) {
      final id = row['id'] as int;
      final prescriptions = await getPrescriptionsForConsultation(id);
      list.add(ConsultationModel.fromMap(row, prescriptions: prescriptions));
    }
    return list;
  }

  Future<List<ConsultationModel>> getConsultationsForPet(int petId) async {
    final db = await _dbHelper.database;
    const sql = '''
      SELECT 
        c.*, 
        p.name AS pet_name, 
        p.species AS pet_species,
        u.full_name AS doctor_name,
        o.full_name AS owner_name
      FROM ${DatabaseTables.tableConsultations} c
      INNER JOIN ${DatabaseTables.tablePets} p ON c.pet_id = p.id
      INNER JOIN ${DatabaseTables.tableUsers} u ON c.doctor_id = u.id
      INNER JOIN ${DatabaseTables.tableOwners} o ON p.owner_id = o.id
      WHERE c.pet_id = ?
      ORDER BY c.visit_date DESC, c.id DESC
    ''';
    final res = await db.rawQuery(sql, [petId]);

    List<ConsultationModel> list = [];
    for (final row in res) {
      final id = row['id'] as int;
      final prescriptions = await getPrescriptionsForConsultation(id);
      list.add(ConsultationModel.fromMap(row, prescriptions: prescriptions));
    }
    return list;
  }

  Future<ConsultationModel?> getConsultationById(int id) async {
    final db = await _dbHelper.database;
    final sql = '''
      SELECT 
        c.*, 
        p.name AS pet_name, 
        p.species AS pet_species,
        u.full_name AS doctor_name,
        o.full_name AS owner_name
      FROM ${DatabaseTables.tableConsultations} c
      INNER JOIN ${DatabaseTables.tablePets} p ON c.pet_id = p.id
      INNER JOIN ${DatabaseTables.tableUsers} u ON c.doctor_id = u.id
      INNER JOIN ${DatabaseTables.tableOwners} o ON p.owner_id = o.id
      WHERE c.id = ?
      LIMIT 1
    ''';
    final res = await db.rawQuery(sql, [id]);
    if (res.isNotEmpty) {
      final prescriptions = await getPrescriptionsForConsultation(id);
      return ConsultationModel.fromMap(res.first, prescriptions: prescriptions);
    }
    return null;
  }

  Future<List<PrescriptionModel>> getPrescriptionsForConsultation(int consultationId) async {
    final db = await _dbHelper.database;
    const sql = '''
      SELECT 
        pr.*, 
        COALESCE(m.trade_name, pr.custom_name) AS medicine_name, 
        m.form AS medicine_form, 
        m.concentration AS medicine_concentration
      FROM ${DatabaseTables.tablePrescriptions} pr
      LEFT JOIN ${DatabaseTables.tableMedicines} m ON pr.medicine_id = m.id
      WHERE pr.consultation_id = ?
    ''';
    final res = await db.rawQuery(sql, [consultationId]);
    return res.map((m) => PrescriptionModel.fromMap(m)).toList();
  }

  /// Create consultation and its prescriptions within a single atomic transaction
  /// Deducts shelf stock ONLY for clinic-administered treatments with valid pharmacy medicine_id
  Future<int> createConsultationWithPrescriptions({
    required ConsultationModel consultation,
    required List<PrescriptionModel> prescriptions,
  }) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      // 1. Insert consultation
      final consultationId = await txn.insert(
        DatabaseTables.tableConsultations,
        consultation.toMap(),
      );

      // 2. Insert prescriptions & auto-deduct shelf stock if clinic administered
      for (final rx in prescriptions) {
        final rxMap = rx.copyWith(consultationId: consultationId).toMap();
        await txn.insert(DatabaseTables.tablePrescriptions, rxMap);

        // Deduct clinic shelf stock ONLY for in-clinic administered medications
        if (rx.isClinicAdministered && rx.medicineId != null && rx.medicineId! > 0) {
          final medRows = await txn.query(
            DatabaseTables.tableMedicines,
            where: 'id = ?',
            whereArgs: [rx.medicineId],
            limit: 1,
          );

          if (medRows.isNotEmpty) {
            final currentStock = medRows.first['clinic_stock'] as int? ?? 0;
            final updatedStock = (currentStock - rx.quantityDispensed).clamp(0, 999999);
            await txn.update(
              DatabaseTables.tableMedicines,
              {'clinic_stock': updatedStock},
              where: 'id = ?',
              whereArgs: [rx.medicineId],
            );
          }
        }
      }

      // 3. Automatically record income transaction in financial module
      if (consultation.visitCost > 0) {
        final petRows = await txn.query(
          DatabaseTables.tablePets,
          columns: ['owner_id'],
          where: 'id = ?',
          whereArgs: [consultation.petId],
          limit: 1,
        );
        final ownerId = petRows.isNotEmpty ? petRows.first['owner_id'] as int? : null;

        await txn.insert(DatabaseTables.tableTransactions, {
          'transaction_type': 'income',
          'category': 'consultation',
          'owner_id': ownerId,
          'pet_id': consultation.petId,
          'reference_id': consultationId,
          'reference_type': 'consultation',
          'amount': consultation.visitCost,
          'paid_amount': consultation.visitCost,
          'remaining_amount': 0.0,
          'payment_method': consultation.paymentMethod,
          'transaction_date': consultation.visitDate,
          'notes': 'أتعاب كشف واستشارة سريرية: ${consultation.diagnosis}',
        });
      }

      return consultationId;
    });
  }

  Future<int> updateConsultation(ConsultationModel consultation) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseTables.tableConsultations,
      consultation.toMap(),
      where: 'id = ?',
      whereArgs: [consultation.id],
    );
  }

  Future<void> deleteConsultation(int consultationId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // 1. Find clinic-administered prescriptions to restore shelf stock
      final rxList = await txn.query(
        DatabaseTables.tablePrescriptions,
        where: 'consultation_id = ?',
        whereArgs: [consultationId],
      );

      for (final rx in rxList) {
        final isClinicAdministered = (rx['is_clinic_administered'] as int? ?? 0) == 1;
        final medId = rx['medicine_id'] as int?;
        final qty = rx['quantity_dispensed'] as int? ?? 0;

        if (isClinicAdministered && medId != null && medId > 0 && qty > 0) {
          final medRows = await txn.query(
            DatabaseTables.tableMedicines,
            where: 'id = ?',
            whereArgs: [medId],
            limit: 1,
          );
          if (medRows.isNotEmpty) {
            final currentStock = medRows.first['clinic_stock'] as int? ?? 0;
            await txn.update(
              DatabaseTables.tableMedicines,
              {'clinic_stock': currentStock + qty},
              where: 'id = ?',
              whereArgs: [medId],
            );
          }
        }
      }

      // 2. Delete consultation (cascades to prescriptions)
      await txn.delete(
        DatabaseTables.tableConsultations,
        where: 'id = ?',
        whereArgs: [consultationId],
      );
    });
  }

  Future<int> getTodayConsultationsCount() async {
    final db = await _dbHelper.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final res = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM ${DatabaseTables.tableConsultations} WHERE visit_date LIKE ?',
      ['$today%'],
    );
    return res.first['cnt'] as int? ?? 0;
  }
}
