import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_tables.dart';

class DatabaseHelper {
  static const String _dbName = 'vet_pulse.db';
  static const int _dbVersion = 9;

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<String> getDatabaseFilePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, _dbName);
  }

  Future<void> flushWal() async {
    if (_database != null && _database!.isOpen) {
      try {
        await _database!.execute('PRAGMA wal_checkpoint(FULL);');
      } catch (_) {}
    }
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDatabase() async {
    // Desktop support (Windows, Linux, macOS)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await ensureAllTablesExist(db);
      },
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE ${DatabaseTables.tablePrescriptions} ADD COLUMN custom_name TEXT;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE ${DatabaseTables.tablePrescriptions} ADD COLUMN is_clinic_administered INTEGER DEFAULT 0;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE ${DatabaseTables.tablePrescriptions} ADD COLUMN route TEXT;');
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute(DatabaseTables.createExpensesTable);
        await db.execute(DatabaseTables.createExpensesDateIndex);
      } catch (_) {}
      try {
        await db.execute(DatabaseTables.createTransactionsTable);
        await db.execute(DatabaseTables.createTransactionsDateIndex);
        await db.execute(DatabaseTables.createTransactionsOwnerIndex);
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE ${DatabaseTables.tableConsultations} ADD COLUMN payment_method TEXT DEFAULT "نقدا";');
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE ${DatabaseTables.tableConsultations} ADD COLUMN paid_amount REAL DEFAULT 0.0;');
      } catch (_) {}
      try {
        await db.execute(DatabaseTables.createCustomerPaymentsTable);
        await db.execute(DatabaseTables.createCustomerPaymentsOwnerIndex);
        await db.execute(DatabaseTables.createCustomerPaymentsDateIndex);
      } catch (_) {}
      try {
        await db.execute(DatabaseTables.createBackupLogsTable);
        await db.execute(DatabaseTables.createBackupLogsDateIndex);
      } catch (_) {}
    }
    if (oldVersion < 6) {
      await db.execute('PRAGMA foreign_keys = OFF;');
      try {
        await db.execute('DROP TABLE IF EXISTS ${DatabaseTables.tableCustomerPayments};');
        await db.execute('ALTER TABLE ${DatabaseTables.tableTransactions} RENAME TO temp_transactions_old;');
        await db.execute(DatabaseTables.createTransactionsTable);
        await db.execute(DatabaseTables.createTransactionsDateIndex);
        await db.execute(DatabaseTables.createTransactionsOwnerIndex);
        await db.execute('''
          INSERT INTO ${DatabaseTables.tableTransactions} 
          (id, transaction_type, category, owner_id, pet_id, reference_id, reference_type, amount, paid_amount, remaining_amount, payment_method, transaction_date, notes, created_at)
          SELECT id, transaction_type, category, owner_id, pet_id, reference_id, reference_type, amount, 
                 COALESCE(paid_amount, amount), COALESCE(remaining_amount, 0.0), payment_method, transaction_date, notes, created_at
          FROM temp_transactions_old;
        ''');
        await db.execute('DROP TABLE temp_transactions_old;');
        await db.execute(DatabaseTables.createCustomerPaymentsTable);
        await db.execute(DatabaseTables.createCustomerPaymentsOwnerIndex);
        await db.execute(DatabaseTables.createCustomerPaymentsDateIndex);
      } catch (_) {}
      await db.execute('PRAGMA foreign_keys = ON;');
    }
    if (oldVersion < 7) {
      try {
        await db.execute('ALTER TABLE ${DatabaseTables.tableOwners} DROP COLUMN phone_secondary;');
      } catch (_) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE ${DatabaseTables.tableOwners} DROP COLUMN notes;');
      } catch (_) {}
    }
    if (oldVersion < 9) {
      try {
        await db.execute(DatabaseTables.createAppLicenseStateTable);
      } catch (_) {}
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    for (final sql in DatabaseTables.allTablesAndIndices) {
      batch.execute(sql);
    }

    await batch.commit();

    // Seed Initial Doctor & Clinic
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    // 1. Initial Primary Lead Doctor Admin User (id = 1)
    await db.insert(DatabaseTables.tableUsers, {
      'id': 1,
      'username': 'admin',
      'password_hash': 'admin123',
      'full_name': 'الطبيب المسؤول',
      'role': 'lead_doctor',
      'phone': '',
      'pin_code': '1234',
      'is_active': 1,
    });

    // 2. Initial Unactivated App License State (id = 1)
    await db.insert(DatabaseTables.tableAppLicenseState, {
      'id': 1,
      'onboarding_completed': 0,
      'clinic_setup_completed': 0,
      'device_fingerprint': '',
      'activation_code': null,
      'activated_at': null,
      'expiry_date': null,
      'last_seen_timestamp': DateTime.now().toIso8601String(),
      'used_codes_json': '[]',
    });
  }

  /// Self-healing schema validation: ensures all required tables and columns exist
  Future<void> ensureAllTablesExist(Database db) async {
    for (final sql in DatabaseTables.allTablesAndIndices) {
      await db.execute(sql);
    }

    // Ensure columns exist on legacy databases
    try {
      final txCols = await db.rawQuery('PRAGMA table_info(${DatabaseTables.tableTransactions});');
      final txColNames = txCols.map((c) => c['name'] as String).toSet();
      if (!txColNames.contains('paid_amount')) {
        await db.execute('ALTER TABLE ${DatabaseTables.tableTransactions} ADD COLUMN paid_amount REAL DEFAULT 0.0;');
      }
      if (!txColNames.contains('remaining_amount')) {
        await db.execute('ALTER TABLE ${DatabaseTables.tableTransactions} ADD COLUMN remaining_amount REAL DEFAULT 0.0;');
      }
    } catch (_) {}

    try {
      final consultCols = await db.rawQuery('PRAGMA table_info(${DatabaseTables.tableConsultations});');
      final consultColNames = consultCols.map((c) => c['name'] as String).toSet();
      if (!consultColNames.contains('paid_amount')) {
        await db.execute('ALTER TABLE ${DatabaseTables.tableConsultations} ADD COLUMN paid_amount REAL DEFAULT 0.0;');
      }
      if (!consultColNames.contains('payment_method')) {
        await db.execute('ALTER TABLE ${DatabaseTables.tableConsultations} ADD COLUMN payment_method TEXT DEFAULT "نقدا";');
      }
    } catch (_) {}

    // Clean up legacy auto-generated receipt vouchers from consultations and surgeries
    try {
      await db.execute('''
        DELETE FROM ${DatabaseTables.tableCustomerPayments}
        WHERE receipt_number LIKE 'REC-%-1' 
           OR receipt_number LIKE 'REC-SURG-%';
      ''');
    } catch (_) {}
  }
}
