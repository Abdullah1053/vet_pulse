import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vet_pulse/core/services/license_service.dart';
import 'package:vet_pulse/data/database/database_helper.dart';
import 'package:vet_pulse/data/database/database_tables.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    try {
      final dbPath = await databaseFactory.getDatabasesPath();
      final file = File('$dbPath/vet_pulse.db');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
    await DatabaseHelper.instance.database;
  });

  group('VetPulse Production Licensing, Empty DB & Device Security Tests', () {
    late LicenseService licenseService;

    setUp(() async {
      Get.reset();
      licenseService = LicenseService();
      await licenseService.init();
      Get.put<LicenseService>(licenseService);
    });

    test('1. Fresh installation has 100% empty database (0 demo records)', () async {
      final db = await DatabaseHelper.instance.database;

      // Check users table: only single lead doctor admin user exists
      final userCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.tableUsers}'),
      );
      expect(userCount, equals(1));

      final users = await db.query(DatabaseTables.tableUsers);
      expect(users.first['username'], equals('admin'));
      expect(users.first['role'], equals('lead_doctor'));

      // Check all other clinic, patient, and financial tables: must be strictly 0
      final tablesToCheck = [
        DatabaseTables.tableClinicInfo,
        DatabaseTables.tableOwners,
        DatabaseTables.tablePets,
        DatabaseTables.tablePetWeights,
        DatabaseTables.tableMedicines,
        DatabaseTables.tableConsultations,
        DatabaseTables.tablePrescriptions,
        DatabaseTables.tableSurgeries,
        DatabaseTables.tableFollowUps,
        DatabaseTables.tableExpenses,
        DatabaseTables.tableTransactions,
        DatabaseTables.tableCustomerPayments,
      ];

      for (final table in tablesToCheck) {
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $table'),
        );
        expect(count, equals(0), reason: 'Table $table must be completely empty on fresh install');
      }

      // Check license state table
      final licenseRows = await db.query(DatabaseTables.tableAppLicenseState);
      expect(licenseRows.length, equals(1));
    });

    test('2. Repeated request code calls generate distinct timestamped codes', () async {
      final fp = licenseService.deviceFingerprint.value;
      final code1 = licenseService.getDeviceRequestCode(fp);
      await Future.delayed(const Duration(milliseconds: 10));
      final code2 = licenseService.getDeviceRequestCode(fp);

      expect(code1, startsWith('VP1-'));
      expect(code2, startsWith('VP1-'));
      expect(code1, isNot(equals(code2)), reason: 'Each request code must have unique timestamp/entropy');

      final parts = code1.split('-');
      expect(parts.length, equals(4));
      expect(parts[1], equals(licenseService.cleanFingerprint));
      expect(parts[2].length, equals(16)); // TS16 (14 digits + 2 entropy)
      expect(parts[3].length, equals(4)); // CHK4
    });

    test('3. Redeeming a valid code succeeds once and fails on second reuse (Anti-Reuse)', () async {
      final futureExpiry = DateTime.now().add(const Duration(days: 30));
      final validCode = LicenseService.generateActivationCode(
        cleanFingerprint: licenseService.cleanFingerprint,
        expiryDate: futureExpiry,
      );

      // First activation succeeds
      final firstTry = await licenseService.verifyAndActivateCode(validCode);
      expect(firstTry, isTrue);
      expect(licenseService.isLicenseActive.value, isTrue);
      expect(licenseService.isExpired.value, isFalse);

      // Second activation with identical code fails (replay attack prevention)
      final secondTry = await licenseService.verifyAndActivateCode(validCode);
      expect(secondTry, isFalse);
    });

    test('4. Expired license flags expired status while preserving all clinic data', () async {
      final db = await DatabaseHelper.instance.database;

      // Insert test patient data
      final ownerId = await db.insert(DatabaseTables.tableOwners, {
        'full_name': 'مالك تجريبي لاختبار الصلاحية',
        'phone_primary': '0770000000',
      });
      final petId = await db.insert(DatabaseTables.tablePets, {
        'owner_id': ownerId,
        'name': 'طمطم',
        'species': 'cat',
      });

      // Set database state to expired with validly signed code for this device
      final expiredCode = LicenseService.generateActivationCode(
        cleanFingerprint: licenseService.cleanFingerprint,
        expiryDate: DateTime(2020, 1, 1),
      );

      await db.update(
        DatabaseTables.tableAppLicenseState,
        {
          'device_fingerprint': licenseService.deviceFingerprint.value,
          'activation_code': expiredCode,
          'expiry_date': '2020-01-01',
          'last_seen_timestamp': DateTime.now().toIso8601String(),
        },
        where: 'id = 1',
      );

      final status = await licenseService.checkLicenseValidity();
      expect(status, equals(LicenseStatus.expired));
      expect(licenseService.isExpired.value, isTrue);
      expect(licenseService.isLicenseActive.value, isFalse);

      // Verify that clinic & patient data was completely preserved
      final petCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM ${DatabaseTables.tablePets} WHERE id = ?', [petId]),
      );
      expect(petCount, equals(1));
    });

    test('5. Copying a licensed DB row to a different device fingerprint fails with LicenseStatus.deviceMismatch', () async {
      final db = await DatabaseHelper.instance.database;

      // Simulate a database copied from "Phone A" (fingerprint 111122223333)
      const foreignFingerprint = '111122223333';
      final foreignCode = LicenseService.generateActivationCode(
        cleanFingerprint: foreignFingerprint,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );

      await db.update(
        DatabaseTables.tableAppLicenseState,
        {
          'device_fingerprint': foreignFingerprint,
          'activation_code': foreignCode,
          'expiry_date': DateTime.now().add(const Duration(days: 30)).toIso8601String().substring(0, 10),
          'last_seen_timestamp': DateTime.now().toIso8601String(),
        },
        where: 'id = 1',
      );

      final status = await licenseService.checkLicenseValidity();
      expect(status, equals(LicenseStatus.deviceMismatch));
      expect(licenseService.isDeviceMismatch.value, isTrue);
      expect(licenseService.isLicenseActive.value, isFalse);

      // Verify activation_code was cleared in DB and device_fingerprint updated to live device
      final rows = await db.query(DatabaseTables.tableAppLicenseState, where: 'id = 1');
      expect(rows.first['activation_code'], isNull);
      expect(rows.first['device_fingerprint'], equals(licenseService.deviceFingerprint.value));
    });
  });
}
