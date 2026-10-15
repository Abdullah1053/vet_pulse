import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_tables.dart';

class DatabaseHelper {
  static const String _dbName = 'vet_pulse.db';
  static const int _dbVersion = 8;

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
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // Tables
    batch.execute(DatabaseTables.createClinicInfoTable);
    batch.execute(DatabaseTables.createUsersTable);
    batch.execute(DatabaseTables.createOwnersTable);
    batch.execute(DatabaseTables.createOwnersPhoneIndex);
    batch.execute(DatabaseTables.createPetsTable);
    batch.execute(DatabaseTables.createPetsMicrochipIndex);
    batch.execute(DatabaseTables.createPetWeightsTable);
    batch.execute(DatabaseTables.createMedicinesTable);
    batch.execute(DatabaseTables.createMedicinesExpiryIndex);
    batch.execute(DatabaseTables.createConsultationsTable);
    batch.execute(DatabaseTables.createPrescriptionsTable);
    batch.execute(DatabaseTables.createFollowUpsTable);
    batch.execute(DatabaseTables.createFollowUpsDateIndex);
    batch.execute(DatabaseTables.createSurgeriesTable);
    batch.execute(DatabaseTables.createExpensesTable);
    batch.execute(DatabaseTables.createExpensesDateIndex);
    batch.execute(DatabaseTables.createTransactionsTable);
    batch.execute(DatabaseTables.createTransactionsDateIndex);
    batch.execute(DatabaseTables.createTransactionsOwnerIndex);
    batch.execute(DatabaseTables.createCustomerPaymentsTable);
    batch.execute(DatabaseTables.createCustomerPaymentsOwnerIndex);
    batch.execute(DatabaseTables.createCustomerPaymentsDateIndex);
    batch.execute(DatabaseTables.createBackupLogsTable);
    batch.execute(DatabaseTables.createBackupLogsDateIndex);

    await batch.commit();

    // Seed Initial Doctor & Clinic
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    // 1. Initial Clinic Setup
    await db.insert(DatabaseTables.tableClinicInfo, {
      'clinic_name': 'عيادة الوفاء البيطرية المتقدمة',
      'doctor_name': 'د. عبدالله خالد السالم',
      'phone': '0555123456',
      'address': 'الرياض - حي النرجس، طريق أبي بكر الصديق',
      'license_number': 'VET-SA-2026-9812',
    });

    // 2. Initial Lead Doctor User
    await db.insert(DatabaseTables.tableUsers, {
      'username': 'admin',
      'password_hash': 'admin123', // In real clinic apps, securely hashed
      'full_name': 'د. عبدالله خالد السالم',
      'role': 'lead_doctor',
      'phone': '0555123456',
      'pin_code': '1234',
      'is_active': 1,
    });

    // 3. Initial Sample Medicines
    final now = DateTime.now();
    final futureDate = DateTime(now.year + 1, now.month, now.day).toIso8601String().substring(0, 10);
    final nearExpiryDate = DateTime(now.year, now.month, now.day + 15).toIso8601String().substring(0, 10);
    final expiredDate = DateTime(now.year - 1, now.month, now.day).toIso8601String().substring(0, 10);

    final medicines = [
      {
        'trade_name': 'أموكسيسيلين + كلافولانيك (Synulox)',
        'scientific_name': 'Amoxicillin + Clavulanic Acid',
        'form': 'أقراص (Tablets)',
        'concentration': '250mg',
        'clinic_stock': 35,
        'warehouse_stock': 120,
        'min_stock_alert': 10,
        'unit_cost_price': 18.5,
        'unit_sale_price': 35.0,
        'expiry_date': futureDate,
        'batch_number': 'SNX-2026-A1',
      },
      {
        'trade_name': 'ميلوكسيكام (Metacam Inj)',
        'scientific_name': 'Meloxicam',
        'form': 'حقن (Injectable)',
        'concentration': '5mg/ml',
        'clinic_stock': 8,
        'warehouse_stock': 25,
        'min_stock_alert': 5,
        'unit_cost_price': 45.0,
        'unit_sale_price': 80.0,
        'expiry_date': futureDate,
        'batch_number': 'MTC-9942',
      },
      {
        'trade_name': 'دوكسيسيكلين (Doxybactin)',
        'scientific_name': 'Doxycycline Hyclate',
        'form': 'أقراص (Tablets)',
        'concentration': '50mg',
        'clinic_stock': 3, // Low stock alert demo
        'warehouse_stock': 5,
        'min_stock_alert': 10,
        'unit_cost_price': 12.0,
        'unit_sale_price': 25.0,
        'expiry_date': nearExpiryDate, // Near expiry demo
        'batch_number': 'DXB-2025-09',
      },
      {
        'trade_name': 'سيفوفلوران (Sevoflurane)',
        'scientific_name': 'Sevoflurane Inhalation Gas',
        'form': 'سوائل وريدية (IV Fluids)',
        'concentration': '250ml',
        'clinic_stock': 2,
        'warehouse_stock': 6,
        'min_stock_alert': 3,
        'unit_cost_price': 180.0,
        'unit_sale_price': 320.0,
        'expiry_date': futureDate,
        'batch_number': 'SEV-8821',
      },
      {
        'trade_name': 'إيفيرمكتين (Ivermectin 1%)',
        'scientific_name': 'Ivermectin',
        'form': 'حقن (Injectable)',
        'concentration': '10mg/ml',
        'clinic_stock': 1,
        'warehouse_stock': 0,
        'min_stock_alert': 4,
        'unit_cost_price': 15.0,
        'unit_sale_price': 30.0,
        'expiry_date': expiredDate, // Expired demo
        'batch_number': 'IVM-2023-EXP',
      },
    ];

    for (final med in medicines) {
      await db.insert(DatabaseTables.tableMedicines, med);
    }
  }

  /// Self-healing schema validation: ensures all required tables and columns exist
  Future<void> ensureAllTablesExist(Database db) async {
    // Core & Financial Tables
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.tableClinicInfo} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clinic_name TEXT NOT NULL,
        doctor_name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        logo_path TEXT,
        license_number TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.tableUsers} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL CHECK(role IN ('lead_doctor', 'assistant_vet', 'receptionist', 'pharmacist')),
        phone TEXT,
        pin_code TEXT,
        is_active INTEGER DEFAULT 1,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.tableOwners} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        phone_primary TEXT NOT NULL,
        address TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_owners_phone ON ${DatabaseTables.tableOwners}(phone_primary);');
    } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.tablePets} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        species TEXT NOT NULL,
        breed TEXT,
        gender TEXT CHECK(gender IN ('male', 'female')),
        is_neutered INTEGER DEFAULT 0,
        date_of_birth DATE,
        microchip_number TEXT,
        photo_path TEXT,
        allergies TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (owner_id) REFERENCES ${DatabaseTables.tableOwners} (id) ON DELETE CASCADE
      );
    ''');
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_pets_microchip ON ${DatabaseTables.tablePets}(microchip_number);');
    } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.tablePetWeights} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        weight REAL NOT NULL,
        recorded_date DATE NOT NULL,
        FOREIGN KEY (pet_id) REFERENCES ${DatabaseTables.tablePets} (id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.tableMedicines} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trade_name TEXT NOT NULL,
        scientific_name TEXT,
        form TEXT NOT NULL,
        concentration TEXT,
        clinic_stock INTEGER DEFAULT 0,
        warehouse_stock INTEGER DEFAULT 0,
        min_stock_alert INTEGER DEFAULT 5,
        unit_cost_price REAL DEFAULT 0.0,
        unit_sale_price REAL DEFAULT 0.0,
        expiry_date DATE NOT NULL,
        batch_number TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_medicines_expiry ON ${DatabaseTables.tableMedicines}(expiry_date);');
    } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.tableConsultations} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        doctor_id INTEGER NOT NULL,
        visit_date DATETIME NOT NULL,
        temperature REAL,
        heart_rate INTEGER,
        symptoms TEXT,
        examination_findings TEXT,
        diagnosis TEXT NOT NULL,
        treatment_plan TEXT,
        visit_cost REAL DEFAULT 0.0,
        paid_amount REAL DEFAULT 0.0,
        payment_method TEXT DEFAULT 'نقدا',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (pet_id) REFERENCES ${DatabaseTables.tablePets} (id) ON DELETE CASCADE,
        FOREIGN KEY (doctor_id) REFERENCES ${DatabaseTables.tableUsers} (id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.tablePrescriptions} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        consultation_id INTEGER NOT NULL,
        medicine_id INTEGER,
        custom_name TEXT,
        dosage TEXT NOT NULL,
        frequency TEXT NOT NULL,
        duration_days INTEGER NOT NULL,
        quantity_dispensed INTEGER NOT NULL,
        instructions TEXT,
        is_clinic_administered INTEGER DEFAULT 0,
        route TEXT,
        FOREIGN KEY (consultation_id) REFERENCES ${DatabaseTables.tableConsultations} (id) ON DELETE CASCADE,
        FOREIGN KEY (medicine_id) REFERENCES ${DatabaseTables.tableMedicines} (id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.tableFollowUps} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        consultation_id INTEGER,
        scheduled_date DATE NOT NULL,
        scheduled_time TEXT,
        reason TEXT NOT NULL,
        status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'completed', 'missed', 'cancelled')),
        reminder_sent INTEGER DEFAULT 0,
        notes TEXT,
        FOREIGN KEY (pet_id) REFERENCES ${DatabaseTables.tablePets} (id) ON DELETE CASCADE,
        FOREIGN KEY (consultation_id) REFERENCES ${DatabaseTables.tableConsultations} (id)
      );
    ''');
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_followups_date ON ${DatabaseTables.tableFollowUps}(scheduled_date);');
    } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.tableSurgeries} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        lead_surgeon_id INTEGER NOT NULL,
        scheduled_date DATETIME NOT NULL,
        surgery_name TEXT NOT NULL,
        surgery_category TEXT,
        status TEXT DEFAULT 'scheduled' CHECK(status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
        pre_op_checklist_passed INTEGER DEFAULT 0,
        anesthesia_protocol TEXT,
        post_op_notes TEXT,
        estimated_cost REAL,
        FOREIGN KEY (pet_id) REFERENCES ${DatabaseTables.tablePets} (id) ON DELETE CASCADE,
        FOREIGN KEY (lead_surgeon_id) REFERENCES ${DatabaseTables.tableUsers} (id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.tableExpenses} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        expense_date DATE NOT NULL,
        notes TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_date ON ${DatabaseTables.tableExpenses}(expense_date);');
    } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.tableTransactions} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_type TEXT NOT NULL CHECK(transaction_type IN ('income', 'expense', 'payment')),
        category TEXT,
        owner_id INTEGER,
        pet_id INTEGER,
        reference_id INTEGER,
        reference_type TEXT,
        amount REAL NOT NULL,
        paid_amount REAL DEFAULT 0.0,
        remaining_amount REAL DEFAULT 0.0,
        payment_method TEXT DEFAULT 'نقدا',
        transaction_date DATETIME NOT NULL,
        notes TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (owner_id) REFERENCES ${DatabaseTables.tableOwners} (id) ON DELETE SET NULL,
        FOREIGN KEY (pet_id) REFERENCES ${DatabaseTables.tablePets} (id) ON DELETE SET NULL
      );
    ''');
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_date ON ${DatabaseTables.tableTransactions}(transaction_date);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_owner ON ${DatabaseTables.tableTransactions}(owner_id);');
    } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.tableCustomerPayments} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id INTEGER NOT NULL,
        transaction_id INTEGER,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'نقدا',
        payment_date DATETIME NOT NULL,
        receipt_number TEXT,
        notes TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (owner_id) REFERENCES ${DatabaseTables.tableOwners} (id) ON DELETE CASCADE,
        FOREIGN KEY (transaction_id) REFERENCES ${DatabaseTables.tableTransactions} (id) ON DELETE SET NULL
      );
    ''');
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_customer_payments_owner ON ${DatabaseTables.tableCustomerPayments}(owner_id);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_customer_payments_date ON ${DatabaseTables.tableCustomerPayments}(payment_date);');
    } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseTables.tableBackupLogs} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        backup_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        size_bytes INTEGER DEFAULT 0,
        backup_type TEXT NOT NULL DEFAULT 'internal',
        destination TEXT,
        status TEXT NOT NULL DEFAULT 'success',
        error_message TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    ''');
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_backup_logs_date ON ${DatabaseTables.tableBackupLogs}(created_at);');
    } catch (_) {}

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
  }
}
