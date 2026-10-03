import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database_tables.dart';

class DatabaseHelper {
  static const String _dbName = 'vet_pulse.db';
  static const int _dbVersion = 3;

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
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

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
