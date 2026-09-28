import '../database/database_helper.dart';
import '../database/database_tables.dart';
import '../models/owner_model.dart';
import '../models/pet_model.dart';
import '../models/pet_weight_model.dart';

class PetRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // --- OWNERS ---
  Future<List<OwnerModel>> getAllOwners() async {
    final db = await _dbHelper.database;
    final res = await db.query(DatabaseTables.tableOwners, orderBy: 'full_name ASC');
    return res.map((m) => OwnerModel.fromMap(m)).toList();
  }

  Future<OwnerModel?> getOwnerById(int id) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      DatabaseTables.tableOwners,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return OwnerModel.fromMap(res.first);
    }
    return null;
  }

  Future<int> insertOwner(OwnerModel owner) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseTables.tableOwners, owner.toMap());
  }

  Future<int> updateOwner(OwnerModel owner) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseTables.tableOwners,
      owner.toMap(),
      where: 'id = ?',
      whereArgs: [owner.id],
    );
  }

  Future<int> deleteOwner(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseTables.tableOwners,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- PETS ---
  Future<List<PetModel>> getAllPets() async {
    final db = await _dbHelper.database;
    const query = '''
      SELECT 
        p.*, 
        o.full_name AS owner_name, 
        o.phone_primary AS owner_phone,
        (SELECT pw.weight FROM ${DatabaseTables.tablePetWeights} pw WHERE pw.pet_id = p.id ORDER BY pw.recorded_date DESC, pw.id DESC LIMIT 1) AS latest_weight
      FROM ${DatabaseTables.tablePets} p
      INNER JOIN ${DatabaseTables.tableOwners} o ON p.owner_id = o.id
      ORDER BY p.id DESC
    ''';
    final res = await db.rawQuery(query);
    return res.map((m) => PetModel.fromMap(m)).toList();
  }

  Future<PetModel?> getPetById(int id) async {
    final db = await _dbHelper.database;
    final query = '''
      SELECT 
        p.*, 
        o.full_name AS owner_name, 
        o.phone_primary AS owner_phone,
        (SELECT pw.weight FROM ${DatabaseTables.tablePetWeights} pw WHERE pw.pet_id = p.id ORDER BY pw.recorded_date DESC, pw.id DESC LIMIT 1) AS latest_weight
      FROM ${DatabaseTables.tablePets} p
      INNER JOIN ${DatabaseTables.tableOwners} o ON p.owner_id = o.id
      WHERE p.id = ?
      LIMIT 1
    ''';
    final res = await db.rawQuery(query, [id]);
    if (res.isNotEmpty) {
      return PetModel.fromMap(res.first);
    }
    return null;
  }

  Future<List<PetModel>> searchPets(String query) async {
    final db = await _dbHelper.database;
    final cleanQuery = '%${query.trim()}%';
    const sql = '''
      SELECT 
        p.*, 
        o.full_name AS owner_name, 
        o.phone_primary AS owner_phone,
        (SELECT pw.weight FROM ${DatabaseTables.tablePetWeights} pw WHERE pw.pet_id = p.id ORDER BY pw.recorded_date DESC, pw.id DESC LIMIT 1) AS latest_weight
      FROM ${DatabaseTables.tablePets} p
      INNER JOIN ${DatabaseTables.tableOwners} o ON p.owner_id = o.id
      WHERE p.name LIKE ? 
         OR p.microchip_number LIKE ? 
         OR o.full_name LIKE ? 
         OR o.phone_primary LIKE ?
      ORDER BY p.id DESC
    ''';
    final res = await db.rawQuery(sql, [cleanQuery, cleanQuery, cleanQuery, cleanQuery]);
    return res.map((m) => PetModel.fromMap(m)).toList();
  }

  Future<int> insertPet(PetModel pet) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseTables.tablePets, pet.toMap());
  }

  Future<int> updatePet(PetModel pet) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseTables.tablePets,
      pet.toMap(),
      where: 'id = ?',
      whereArgs: [pet.id],
    );
  }

  Future<int> deletePet(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseTables.tablePets,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- PET WEIGHTS ---
  Future<List<PetWeightModel>> getWeightsForPet(int petId) async {
    final db = await _dbHelper.database;
    final res = await db.query(
      DatabaseTables.tablePetWeights,
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'recorded_date DESC, id DESC',
    );
    return res.map((m) => PetWeightModel.fromMap(m)).toList();
  }

  Future<int> addWeight(PetWeightModel weight) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseTables.tablePetWeights, weight.toMap());
  }
}
