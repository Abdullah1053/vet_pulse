import '../../core/services/data_sync_service.dart';
import '../database/database_helper.dart';
import '../database/database_tables.dart';
import '../models/medicine_model.dart';

class InventoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<MedicineModel>> getAllMedicines() async {
    final db = await _dbHelper.database;
    final res = await db.query(DatabaseTables.tableMedicines, orderBy: 'trade_name ASC');
    return res.map((m) => MedicineModel.fromMap(m)).toList();
  }

  Future<MedicineModel?> getMedicineById(int id) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      DatabaseTables.tableMedicines,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return MedicineModel.fromMap(res.first);
    }
    return null;
  }

  Future<List<MedicineModel>> searchMedicines(String query) async {
    final db = await _dbHelper.database;
    final cleanQuery = '%${query.trim()}%';
    final res = await db.query(
      DatabaseTables.tableMedicines,
      where: 'trade_name LIKE ? OR scientific_name LIKE ? OR batch_number LIKE ?',
      whereArgs: [cleanQuery, cleanQuery, cleanQuery],
      orderBy: 'trade_name ASC',
    );
    return res.map((m) => MedicineModel.fromMap(m)).toList();
  }

  Future<List<MedicineModel>> getLowStockMedicines() async {
    final db = await _dbHelper.database;
    final res = await db.query(
      DatabaseTables.tableMedicines,
      where: 'clinic_stock <= min_stock_alert',
      orderBy: 'clinic_stock ASC',
    );
    return res.map((m) => MedicineModel.fromMap(m)).toList();
  }

  Future<List<MedicineModel>> getExpiringOrExpiredMedicines() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final thresholdDate = DateTime(now.year, now.month, now.day + 30).toIso8601String().substring(0, 10);
    final res = await db.query(
      DatabaseTables.tableMedicines,
      where: 'expiry_date <= ?',
      whereArgs: [thresholdDate],
      orderBy: 'expiry_date ASC',
    );
    return res.map((m) => MedicineModel.fromMap(m)).toList();
  }

  Future<int> insertMedicine(MedicineModel medicine) async {
    final db = await _dbHelper.database;
    final res = await db.insert(DatabaseTables.tableMedicines, medicine.toMap());
    DataSyncService.notifyInventoryChanged();
    return res;
  }

  Future<int> updateMedicine(MedicineModel medicine) async {
    final db = await _dbHelper.database;
    final res = await db.update(
      DatabaseTables.tableMedicines,
      medicine.toMap(),
      where: 'id = ?',
      whereArgs: [medicine.id],
    );
    DataSyncService.notifyInventoryChanged();
    return res;
  }

  Future<int> deleteMedicine(int id) async {
    final db = await _dbHelper.database;
    final res = await db.delete(
      DatabaseTables.tableMedicines,
      where: 'id = ?',
      whereArgs: [id],
    );
    DataSyncService.notifyInventoryChanged();
    return res;
  }

  /// Internal Stock Transfer: Move quantity from Warehouse storage to Clinic dispensing shelf
  Future<bool> transferStock({required int medicineId, required int quantity}) async {
    final db = await _dbHelper.database;
    final success = await db.transaction((txn) async {
      final res = await txn.query(
        DatabaseTables.tableMedicines,
        where: 'id = ?',
        whereArgs: [medicineId],
        limit: 1,
      );
      if (res.isEmpty) return false;

      final currentWarehouse = res.first['warehouse_stock'] as int? ?? 0;
      final currentClinic = res.first['clinic_stock'] as int? ?? 0;

      if (currentWarehouse < quantity) {
        return false; // Insufficient warehouse stock
      }

      await txn.update(
        DatabaseTables.tableMedicines,
        {
          'warehouse_stock': currentWarehouse - quantity,
          'clinic_stock': currentClinic + quantity,
        },
        where: 'id = ?',
        whereArgs: [medicineId],
      );
      return true;
    });

    if (success) {
      DataSyncService.notifyInventoryChanged();
    }
    return success;
  }

  /// Deduct medication from clinic shelf upon prescription dispensing
  Future<bool> deductClinicStock({required int medicineId, required int quantity}) async {
    final db = await _dbHelper.database;
    final success = await db.transaction((txn) async {
      final res = await txn.query(
        DatabaseTables.tableMedicines,
        where: 'id = ?',
        whereArgs: [medicineId],
        limit: 1,
      );
      if (res.isEmpty) return false;

      final currentClinic = res.first['clinic_stock'] as int? ?? 0;
      final newStock = (currentClinic - quantity).clamp(0, 999999);

      await txn.update(
        DatabaseTables.tableMedicines,
        {'clinic_stock': newStock},
        where: 'id = ?',
        whereArgs: [medicineId],
      );
      return true;
    });

    if (success) {
      DataSyncService.notifyInventoryChanged();
    }
    return success;
  }
}
