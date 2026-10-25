import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vet_pulse/core/services/license_service.dart';
import 'package:vet_pulse/data/database/database_helper.dart';

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

  group('Cryptographic Licensing & Activation Tests', () {
    late LicenseService licenseService;

    setUp(() async {
      Get.reset();
      licenseService = LicenseService();
      await licenseService.init();
      Get.put<LicenseService>(licenseService);
    });

    test('Device fingerprint is correctly formatted (12 hex chars, XXXX-XXXX-XXXX)', () async {
      final fp = await licenseService.getDeviceFingerprint();
      expect(fp, matches(r'^[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}$'));
      expect(licenseService.cleanFingerprint.length, equals(12));
    });

    test('Device request code has correct format and authentic checksum', () {
      final reqCode = licenseService.getDeviceRequestCode(licenseService.deviceFingerprint.value);
      expect(reqCode, startsWith('VP1-'));
      final parts = reqCode.split('-');
      expect(parts.length, equals(4));
      expect(parts[1], equals(licenseService.cleanFingerprint));
      expect(parts[2].length, equals(8)); // YYYYMMDD
      expect(parts[3].length, equals(4)); // CHK4
    });

    test('Valid activation code activates license successfully', () async {
      final futureExpiry = DateTime.now().add(const Duration(days: 30));
      final validCode = LicenseService.generateActivationCode(
        cleanFingerprint: licenseService.cleanFingerprint,
        expiryDate: futureExpiry,
      );

      final activated = await licenseService.verifyAndActivateCode(validCode);
      expect(activated, isTrue);
      expect(licenseService.isLicenseActive.value, isTrue);
      expect(licenseService.isExpired.value, isFalse);
      expect(licenseService.remainingDays.value, greaterThan(0));
    });

    test('Cannot reuse previously used activation code (replay attack prevention)', () async {
      final futureExpiry = DateTime.now().add(const Duration(days: 30));
      final validCode = LicenseService.generateActivationCode(
        cleanFingerprint: licenseService.cleanFingerprint,
        expiryDate: futureExpiry,
      );

      // Attempt second activation with the same code
      final secondTry = await licenseService.verifyAndActivateCode(validCode);
      expect(secondTry, isFalse);
    });

    test('Activation code bound to another device is rejected', () async {
      const foreignDeviceFingerprint = 'A1B2C3D4E5F6';
      final foreignCode = LicenseService.generateActivationCode(
        cleanFingerprint: foreignDeviceFingerprint,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );

      final activated = await licenseService.verifyAndActivateCode(foreignCode);
      expect(activated, isFalse);
    });

    test('Already expired activation code is rejected', () async {
      final expiredDate = DateTime.now().subtract(const Duration(days: 5));
      final expiredCode = LicenseService.generateActivationCode(
        cleanFingerprint: licenseService.cleanFingerprint,
        expiryDate: expiredDate,
        nonce: 'EX01',
      );

      final activated = await licenseService.verifyAndActivateCode(expiredCode);
      expect(activated, isFalse);
    });

    test('Lifetime activation code sets lifetime flag and activates license', () async {
      final lifetimeDate = DateTime(9999, 12, 31);
      final lifetimeCode = LicenseService.generateActivationCode(
        cleanFingerprint: licenseService.cleanFingerprint,
        expiryDate: lifetimeDate,
        nonce: 'LIFE',
      );

      final activated = await licenseService.verifyAndActivateCode(lifetimeCode);
      expect(activated, isTrue);
      expect(licenseService.isLifetime.value, isTrue);
      expect(licenseService.isLicenseActive.value, isTrue);
    });
  });
}
