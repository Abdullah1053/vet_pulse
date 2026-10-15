import '../../core/services/data_sync_service.dart';
import '../database/database_helper.dart';
import '../database/database_tables.dart';
import '../models/backup_log_model.dart';

class BackupRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Inserts a new backup/restore audit log
  Future<int> insertBackupLog(BackupLogModel log) async {
    final db = await _dbHelper.database;
    final res = await db.insert(DatabaseTables.tableBackupLogs, log.toMap());
    DataSyncService.notifyAllChanged();
    return res;
  }

  /// Retrieves audit logs ordered by newest first
  Future<List<BackupLogModel>> getBackupLogs({int limit = 100}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.tableBackupLogs,
      orderBy: 'created_at DESC, id DESC',
      limit: limit,
    );
    return rows.map((r) => BackupLogModel.fromMap(r)).toList();
  }

  /// Retrieves the latest backup log record
  Future<BackupLogModel?> getLatestBackupLog() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseTables.tableBackupLogs,
      orderBy: 'created_at DESC, id DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return BackupLogModel.fromMap(rows.first);
    }
    return null;
  }

  /// Deletes a specific backup log by id
  Future<int> deleteBackupLog(int id) async {
    final db = await _dbHelper.database;
    final res = await db.delete(
      DatabaseTables.tableBackupLogs,
      where: 'id = ?',
      whereArgs: [id],
    );
    DataSyncService.notifyAllChanged();
    return res;
  }

  /// Clears all audit logs
  Future<int> clearAllLogs() async {
    final db = await _dbHelper.database;
    final res = await db.delete(DatabaseTables.tableBackupLogs);
    DataSyncService.notifyAllChanged();
    return res;
  }
}
