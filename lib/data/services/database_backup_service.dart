import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../database/database_helper.dart';
import '../models/backup_log_model.dart';
import '../repositories/backup_repository.dart';
import '../../core/services/license_service.dart';

class DatabaseBackupInfo {
  final String path;
  final String fileName;
  final int sizeBytes;
  final DateTime lastModified;
  final String backupType;

  DatabaseBackupInfo({
    required this.path,
    String? fileName,
    required this.sizeBytes,
    required this.lastModified,
    this.backupType = 'internal',
  }) : fileName = fileName ?? p.basename(path);

  /// Path to the directory containing this backup file
  String get directoryPath => p.dirname(path);

  /// Short display path (last 2 segments, e.g. 'app_flutter/vet_pulse_backups')
  String get shortDirectoryPath {
    final parts = p.split(directoryPath);
    if (parts.length <= 2) return parts.join('/');
    return parts.sublist(parts.length - 2).join('/');
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get formattedDate {
    return DateFormat('yyyy-MM-dd HH:mm').format(lastModified);
  }
}

class BackupConfig {
  final String? externalDestinationPath;
  final bool autoBackupEnabled;
  final String autoBackupFrequency; // 'daily', 'weekly'
  final String? lastAutoBackupDate;

  BackupConfig({
    this.externalDestinationPath,
    this.autoBackupEnabled = false,
    this.autoBackupFrequency = 'daily',
    this.lastAutoBackupDate,
  });

  Map<String, dynamic> toMap() => {
    'externalDestinationPath': externalDestinationPath,
    'autoBackupEnabled': autoBackupEnabled,
    'autoBackupFrequency': autoBackupFrequency,
    'lastAutoBackupDate': lastAutoBackupDate,
  };

  factory BackupConfig.fromMap(Map<String, dynamic> map) => BackupConfig(
    externalDestinationPath: map['externalDestinationPath'] as String?,
    autoBackupEnabled: map['autoBackupEnabled'] as bool? ?? false,
    autoBackupFrequency: map['autoBackupFrequency'] as String? ?? 'daily',
    lastAutoBackupDate: map['lastAutoBackupDate'] as String?,
  );
}

class DatabaseBackupService {
  DatabaseBackupService._internal();
  static final DatabaseBackupService instance = DatabaseBackupService._internal();
  final BackupRepository _backupRepo = BackupRepository();

  /// Gets dedicated directory for internal backups
  Future<Directory> getInternalBackupsDirectory() async {
    Directory docsDir;
    try {
      docsDir = await getApplicationDocumentsDirectory();
    } catch (_) {
      final dbPath = await DatabaseHelper.instance.getDatabaseFilePath();
      docsDir = Directory(p.dirname(dbPath));
    }

    final backupDir = Directory(p.join(docsDir.path, 'vet_pulse_backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir;
  }

  /// Returns current active database info (size, path, last modified)
  Future<DatabaseBackupInfo?> getDatabaseInfo() async {
    try {
      final dbPath = await DatabaseHelper.instance.getDatabaseFilePath();
      final file = File(dbPath);
      if (await file.exists()) {
        final stat = await file.stat();
        return DatabaseBackupInfo(
          path: dbPath,
          sizeBytes: stat.size,
          lastModified: stat.modified,
          backupType: 'active',
        );
      }
    } catch (e) {
      debugPrint('Error getting database info: $e');
    }
    return null;
  }

  // --- INTERNAL BACKUP (النسخ الاحتياطي الداخلي) ---

  /// Creates a manual or automated internal backup saved locally
  Future<BackupLogModel> createInternalBackup({bool isScheduled = false}) async {
    final now = DateTime.now();
    final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final dateSuffix = DateFormat('yyyy_MM_dd_HHmmss').format(now);
    final backupFileName = 'vet_pulse_internal_$dateSuffix.db';

    try {
      await DatabaseHelper.instance.flushWal();
      final dbPath = await DatabaseHelper.instance.getDatabaseFilePath();
      final sourceFile = File(dbPath);

      if (!await sourceFile.exists()) {
        throw Exception('ملف قاعدة البيانات النشطة غير موجود على الجهاز');
      }

      final backupDir = await getInternalBackupsDirectory();
      final targetPath = p.join(backupDir.path, backupFileName);

      final copiedFile = await sourceFile.copy(targetPath);
      final fileSize = await copiedFile.length();

      final log = BackupLogModel(
        backupName: backupFileName,
        filePath: targetPath,
        sizeBytes: fileSize,
        backupType: isScheduled ? 'scheduled' : 'internal',
        destination: 'التخزين الداخلي: مجلد vet_pulse_backups',
        status: 'success',
        createdAt: nowStr,
      );

      await logBackupEvent(log);
      return log;
    } catch (e) {
      final failLog = BackupLogModel(
        backupName: backupFileName,
        filePath: '',
        sizeBytes: 0,
        backupType: isScheduled ? 'scheduled' : 'internal',
        destination: 'التخزين الداخلي للتطبيق',
        status: 'failed',
        errorMessage: e.toString(),
        createdAt: nowStr,
      );
      await logBackupEvent(failLog);
      rethrow;
    }
  }

  /// Lists all internal backups available in the local backup directory
  Future<List<DatabaseBackupInfo>> listInternalBackups() async {
    try {
      final backupDir = await getInternalBackupsDirectory();
      if (!await backupDir.exists()) return [];

      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.db'))
          .cast<File>()
          .toList();

      final List<DatabaseBackupInfo> list = [];
      for (final file in files) {
        final stat = await file.stat();
        list.add(DatabaseBackupInfo(
          path: file.path,
          fileName: p.basename(file.path),
          sizeBytes: stat.size,
          lastModified: stat.modified,
          backupType: 'internal',
        ));
      }

      // Sort newest first
      list.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      return list;
    } catch (e) {
      debugPrint('Error listing internal backups: $e');
      return [];
    }
  }

  /// Deletes an internal backup file safely
  Future<bool> deleteInternalBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting backup: $e');
    }
    return false;
  }

  // --- EXTERNAL BACKUP (النسخ الاحتياطي الخارجي) ---

  /// Exports backup to an external destination (USB Flash drive, external folder, or file picker)
  Future<BackupLogModel> exportExternalBackup({String? destinationDirectory}) async {
    final now = DateTime.now();
    final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    final dateSuffix = DateFormat('yyyy_MM_dd_HHmmss').format(now);
    final defaultFileName = 'vet_pulse_external_$dateSuffix.db';

    try {
      await DatabaseHelper.instance.flushWal();
      final dbPath = await DatabaseHelper.instance.getDatabaseFilePath();
      final sourceFile = File(dbPath);

      if (!await sourceFile.exists()) {
        throw Exception('ملف قاعدة البيانات غير موجود على الجهاز');
      }

      final bytes = await sourceFile.readAsBytes();
      final fileSize = bytes.length;

      String? targetPath;

      if (destinationDirectory != null &&
          destinationDirectory.isNotEmpty &&
          !destinationDirectory.startsWith('/document/') &&
          !destinationDirectory.startsWith('content://') &&
          await Directory(destinationDirectory).exists()) {
        targetPath = p.join(destinationDirectory, defaultFileName);
        await sourceFile.copy(targetPath);
      } else {
        final savedUri = await FilePicker.saveFile(
          dialogTitle: 'اختر موقع حفظ النسخة الاحتياطية',
          fileName: defaultFileName,
          bytes: bytes,
          type: FileType.any,
        );
        if (savedUri != null) {
          try {
            targetPath = savedUri.toFilePath(windows: Platform.isWindows);
          } catch (_) {
            targetPath = savedUri.path;
          }
        }
      }

      if (targetPath == null) {
        throw Exception('تم إلغاء عملية اختيار الوجهة الخارجية للنسخ الاحتياطي');
      }

      if (!targetPath.startsWith('/document/') && !targetPath.startsWith('content://')) {
        try {
          final file = File(targetPath);
          if (!await file.exists() || (await file.length()) == 0) {
            await file.writeAsBytes(bytes, flush: true);
          }
        } catch (e) {
          debugPrint('Notice: writing to targetPath directly failed or not needed: $e');
        }
      }

      try {
        if (!targetPath.startsWith('/document/') && !targetPath.startsWith('content://')) {
          await File(targetPath).length();
        }
      } catch (_) {
        // Fallback safely to fileSize
      }

      final log = BackupLogModel(
        backupName: defaultFileName,
        filePath: targetPath,
        sizeBytes: fileSize,
        backupType: 'external',
        destination: targetPath,
        status: 'success',
        createdAt: nowStr,
      );

      await logBackupEvent(log);
      return log;
    } catch (e) {
      final failLog = BackupLogModel(
        backupName: defaultFileName,
        filePath: '',
        sizeBytes: 0,
        backupType: 'external',
        destination: destinationDirectory ?? 'وجهة خارجية',
        status: 'failed',
        errorMessage: e.toString(),
        createdAt: nowStr,
      );
      await logBackupEvent(failLog);
      rethrow;
    }
  }

  /// Exports backup via file picker (compatibility method)
  Future<String?> exportBackupToFilePicker() async {
    final log = await exportExternalBackup();
    return log.filePath;
  }

  /// Shares backup file using system share sheet (Google Drive, WhatsApp, Bluetooth, etc.)
  Future<bool> shareBackupViaSystem() async {
    await DatabaseHelper.instance.flushWal();
    final dbPath = await DatabaseHelper.instance.getDatabaseFilePath();
    final sourceFile = File(dbPath);

    if (!await sourceFile.exists()) {
      throw Exception('ملف قاعدة البيانات غير موجود على الجهاز');
    }

    final bytes = await sourceFile.readAsBytes();
    final dateSuffix = DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now());
    final defaultFileName = 'vet_pulse_backup_$dateSuffix.db';

    await Printing.sharePdf(
      bytes: bytes,
      filename: defaultFileName,
    );
    return true;
  }

  // --- RESTORE BACKUP (استعادة النسخة الاحتياطية مع التحقق من الصلاحيات) ---

  /// Restores database with mandatory role and safety checks
  Future<String> restoreFromFile(
    String backupFilePath, {
    String userRole = 'lead_doctor',
  }) async {
    // 1. Role Permission Guard: Only lead doctor or authorized admin can restore
    if (userRole != 'lead_doctor' && userRole != 'admin') {
      throw Exception('عذراً، عملية استعادة النسخة الاحتياطية تتطلب صلاحيات الطبيب المسؤول (Lead Doctor) حصرياً لحماية بيانات العيادة.');
    }

    final backupFile = File(backupFilePath);
    if (!await backupFile.exists()) {
      throw Exception('ملف النسخة الاحتياطية غير موجود: $backupFilePath');
    }

    final fileSize = await backupFile.length();
    if (fileSize < 100) {
      throw Exception('الملف فارغ أو تالف وغير صالح كقاعدة بيانات');
    }

    // 2. Validate SQLite Header ("SQLite format 3\0")
    final headerBytes = await backupFile.openRead(0, 16).first;
    const expectedHeader = [
      0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, 0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00
    ];
    bool isValidSqlite = headerBytes.length >= 16;
    if (isValidSqlite) {
      for (int i = 0; i < 16; i++) {
        if (headerBytes[i] != expectedHeader[i]) {
          isValidSqlite = false;
          break;
        }
      }
    }

    if (!isValidSqlite) {
      throw Exception('الملف المحدد ليس ملف قاعدة بيانات SQLite صالح لتطبيق نبض البيطري');
    }

    final nowStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    try {
      // Step 1: Close active database cleanly
      await DatabaseHelper.instance.close();

      // Step 2: Target path
      final activeDbPath = await DatabaseHelper.instance.getDatabaseFilePath();

      // Remove any leftover WAL/SHM journal files
      final walFile = File('$activeDbPath-wal');
      if (await walFile.exists()) await walFile.delete();
      final shmFile = File('$activeDbPath-shm');
      if (await shmFile.exists()) await shmFile.delete();

      // Step 3: Overwrite with backup
      await backupFile.copy(activeDbPath);

      // Step 4: Reopen database and verify integrity
      final newDb = await DatabaseHelper.instance.database;
      final integrityRes = await newDb.rawQuery('PRAGMA integrity_check;');
      final status = integrityRes.isNotEmpty ? integrityRes.first.values.first.toString() : '';

      if (status != 'ok') {
        throw Exception('فشل فحص سلامة البيانات المستعادة: $status');
      }

      // Step 5: Verify cryptographic device identity on restored database
      try {
        await LicenseService.to.checkLicenseValidity();
      } catch (e) {
        debugPrint('License verification error after restore: $e');
      }

      // Log success in audit table
      await logBackupEvent(BackupLogModel(
        backupName: p.basename(backupFilePath),
        filePath: backupFilePath,
        sizeBytes: fileSize,
        backupType: 'restore',
        destination: 'قاعدة البيانات النشطة (تمت الاستعادة بنجاح)',
        status: 'success',
        createdAt: nowStr,
      ));

      return 'تمت استعادة قاعدة البيانات بنجاح (${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB)';
    } catch (e) {
      await logBackupEvent(BackupLogModel(
        backupName: p.basename(backupFilePath),
        filePath: backupFilePath,
        sizeBytes: fileSize,
        backupType: 'restore',
        destination: 'قاعدة البيانات النشطة',
        status: 'failed',
        errorMessage: e.toString(),
        createdAt: nowStr,
      ));
      rethrow;
    }
  }

  /// Restores database from a user-selected backup file (.db)
  Future<String> restoreFromBackupPicker({String userRole = 'lead_doctor'}) async {
    final pickedFiles = await FilePickerPlatform.instance.pickFiles(
      dialogTitle: 'اختر ملف النسخة الاحتياطية (.db)',
      type: FileType.any,
    );

    if (pickedFiles.isEmpty) {
      throw Exception('تم إلغاء عملية الاستعادة');
    }

    final pickedPath = pickedFiles.first.path;
    if (pickedPath == null || pickedPath.isEmpty) {
      throw Exception('تعذر قراءة مسار الملف المحدد');
    }

    return await restoreFromFile(pickedPath, userRole: userRole);
  }

  // --- LOGGING & AUDIT TRAIL (سجل عمليات النسخ والتدقيق) ---

  /// Records backup or restore event in tableBackupLogs
  Future<void> logBackupEvent(BackupLogModel log) async {
    try {
      await _backupRepo.insertBackupLog(log);
    } catch (e) {
      debugPrint('Error inserting backup log: $e');
    }
  }

  /// Retrieves all backup and restore logs
  Future<List<BackupLogModel>> getBackupLogs() async {
    try {
      return await _backupRepo.getBackupLogs();
    } catch (e) {
      debugPrint('Error getting backup logs: $e');
      return [];
    }
  }

  // --- CONFIGURATION PERSISTENCE ---

  Future<File> _getConfigFile() async {
    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      final dbPath = await DatabaseHelper.instance.getDatabaseFilePath();
      dir = Directory(p.dirname(dbPath));
    }
    return File(p.join(dir.path, 'vet_pulse_backup_config.json'));
  }

  /// Loads current backup configuration
  Future<BackupConfig> getBackupConfig() async {
    try {
      final file = await _getConfigFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final map = jsonDecode(content) as Map<String, dynamic>;
        return BackupConfig.fromMap(map);
      }
    } catch (e) {
      debugPrint('Error reading backup config: $e');
    }
    return BackupConfig();
  }

  /// Saves backup configuration
  Future<void> saveBackupConfig(BackupConfig config) async {
    try {
      final file = await _getConfigFile();
      await file.writeAsString(jsonEncode(config.toMap()));
    } catch (e) {
      debugPrint('Error saving backup config: $e');
    }
  }
}
