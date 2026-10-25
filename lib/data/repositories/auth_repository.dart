import 'package:sqflite/sqflite.dart';
import '../../core/services/data_sync_service.dart';
import '../database/database_helper.dart';
import '../database/database_tables.dart';
import '../models/clinic_model.dart';
import '../models/user_model.dart';

class AuthRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<ClinicModel?> getClinicInfo() async {
    final db = await _dbHelper.database;
    final res = await db.query(DatabaseTables.tableClinicInfo, limit: 1);
    if (res.isNotEmpty) {
      return ClinicModel.fromMap(res.first);
    }
    return null;
  }

  Future<int> saveClinicInfo(ClinicModel clinic) async {
    final db = await _dbHelper.database;
    final int res;
    if (clinic.id != null) {
      res = await db.update(
        DatabaseTables.tableClinicInfo,
        clinic.toMap(),
        where: 'id = ?',
        whereArgs: [clinic.id],
      );
    } else {
      res = await db.insert(DatabaseTables.tableClinicInfo, clinic.toMap());
    }
    DataSyncService.notifyAllChanged();
    return res;
  }

  Future<UserModel?> login(String username, String password) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      DatabaseTables.tableUsers,
      where: 'username = ? AND password_hash = ? AND is_active = 1',
      whereArgs: [username.trim(), password],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return UserModel.fromMap(res.first);
    }
    return null;
  }

  Future<UserModel?> loginWithPin(String pin) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      DatabaseTables.tableUsers,
      where: 'pin_code = ? AND is_active = 1',
      whereArgs: [pin.trim()],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return UserModel.fromMap(res.first);
    }
    return null;
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      DatabaseTables.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return UserModel.fromMap(res.first);
    }
    return null;
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await _dbHelper.database;
    final res = await db.query(DatabaseTables.tableUsers, orderBy: 'id ASC');
    return res.map((m) => UserModel.fromMap(m)).toList();
  }

  Future<int> addUser(UserModel user) async {
    final db = await _dbHelper.database;
    final res = await db.insert(DatabaseTables.tableUsers, user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    DataSyncService.notifyAllChanged();
    return res;
  }

  Future<int> updateUser(UserModel user) async {
    final db = await _dbHelper.database;
    final res = await db.update(
      DatabaseTables.tableUsers,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
    DataSyncService.notifyAllChanged();
    return res;
  }

  Future<int> deleteUser(int id) async {
    final db = await _dbHelper.database;
    final res = await db.delete(
      DatabaseTables.tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
    DataSyncService.notifyAllChanged();
    return res;
  }
}
