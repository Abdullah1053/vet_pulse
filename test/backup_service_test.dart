import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vet_pulse/data/database/demo_data_seeder.dart';
import 'package:vet_pulse/data/services/database_backup_service.dart';

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
    await DemoDataSeeder.resetDemoData();
  });

  group('DatabaseBackupService Tests', () {
    final service = DatabaseBackupService.instance;

    test('getDatabaseInfo returns active database info', () async {
      final info = await service.getDatabaseInfo();
      expect(info, isNotNull);
      expect(info!.sizeBytes, greaterThan(0));
      expect(info.formattedSize, isNotEmpty);
    });

    test('createInternalBackup creates backup file and logs success', () async {
      final log = await service.createInternalBackup();
      expect(log.status, equals('success'));
      expect(log.backupType, equals('internal'));
      expect(log.sizeBytes, greaterThan(0));
      expect(File(log.filePath).existsSync(), isTrue);

      // Verify log was persisted in tableBackupLogs
      final logs = await service.getBackupLogs();
      expect(logs.any((l) => l.backupName == log.backupName), isTrue);
    });

    test('listInternalBackups returns existing internal backups', () async {
      final list = await service.listInternalBackups();
      expect(list, isNotEmpty);
      expect(list.first.sizeBytes, greaterThan(0));
      expect(list.first.fileName, contains('vet_pulse_internal_'));
    });

    test('restoreFromFile rejects unauthorized user roles', () async {
      final list = await service.listInternalBackups();
      expect(list, isNotEmpty);

      expect(
        () async => await service.restoreFromFile(
          list.first.path,
          userRole: 'assistant_nurse',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('restoreFromFile succeeds with lead_doctor role', () async {
      final list = await service.listInternalBackups();
      expect(list, isNotEmpty);

      final result = await service.restoreFromFile(
        list.first.path,
        userRole: 'lead_doctor',
      );
      expect(result, contains('تمت استعادة'));
    });

    test('restoreFromFile fails cleanly on invalid/corrupted file', () async {
      final tempDir = Directory.systemTemp;
      final corruptFile = File('${tempDir.path}/corrupt_test.db');
      await corruptFile.writeAsString('THIS IS NOT A VALID SQLITE DATABASE');

      expect(
        () async => await service.restoreFromFile(
          corruptFile.path,
          userRole: 'lead_doctor',
        ),
        throwsA(isA<Exception>()),
      );

      if (await corruptFile.exists()) {
        await corruptFile.delete();
      }
    });

    test('deleteInternalBackup removes file', () async {
      final log = await service.createInternalBackup();
      expect(File(log.filePath).existsSync(), isTrue);

      final deleted = await service.deleteInternalBackup(log.filePath);
      expect(deleted, isTrue);
      expect(File(log.filePath).existsSync(), isFalse);
    });
  });
}
