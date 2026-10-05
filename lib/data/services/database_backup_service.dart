import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../database/database_helper.dart';

class DatabaseBackupInfo {
  final String path;
  final int sizeBytes;
  final DateTime lastModified;

  DatabaseBackupInfo({
    required this.path,
    required this.sizeBytes,
    required this.lastModified,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get formattedDate {
    return DateFormat('yyyy-MM-dd HH:mm').format(lastModified);
  }
}

class DatabaseBackupService {
  DatabaseBackupService._internal();
  static final DatabaseBackupService instance = DatabaseBackupService._internal();

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
        );
      }
    } catch (e) {
      debugPrint('Error getting database info: $e');
    }
    return null;
  }

  /// Exports backup file to Flash drive, chosen folder, or downloads directory
  Future<String?> exportBackupToFilePicker() async {
    await DatabaseHelper.instance.flushWal();
    final dbPath = await DatabaseHelper.instance.getDatabaseFilePath();
    final sourceFile = File(dbPath);

    if (!await sourceFile.exists()) {
      throw Exception('ملف قاعدة البيانات غير موجود على الجهاز');
    }

    final dateSuffix = DateFormat('yyyy_MM_dd_HHmm').format(DateTime.now());
    final defaultFileName = 'vet_pulse_backup_$dateSuffix.db';
    final bytes = await sourceFile.readAsBytes();

    // 1. Try native Save File Picker (Supported on Windows, Linux, macOS, modern Android)
    try {
      final uri = await FilePickerPlatform.instance.saveFile(
        dialogTitle: 'اختر موقع حفظ النسخة الاحتياطية (فلاش ميموري أو مجلد)',
        fileName: defaultFileName,
        bytes: bytes,
        mimeType: 'application/x-sqlite3',
      );

      if (uri != null) {
        try {
          return uri.toFilePath(windows: Platform.isWindows);
        } catch (_) {
          return uri.path;
        }
      }
    } catch (e) {
      debugPrint('saveFile not supported or failed: $e, trying folder picker fallback');
    }

    // 2. Fallback: Pick directory (e.g. Flash drive folder or Downloads)
    try {
      final selectedDirectory = await FilePickerPlatform.instance.getDirectoryPath(
        dialogTitle: 'اختر المجلد أو الفلاش ميموري لحفظ النسخة الاحتياطية',
      );

      if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
        final targetPath = p.join(selectedDirectory, defaultFileName);
        await sourceFile.copy(targetPath);
        return targetPath;
      }
    } catch (e) {
      debugPrint('getDirectoryPath failed: $e');
    }

    // 3. Fallback to Downloads directory
    try {
      Directory? downloadsDir = await getDownloadsDirectory();
      downloadsDir ??= await getApplicationDocumentsDirectory();

      final targetPath = p.join(downloadsDir.path, defaultFileName);
      await sourceFile.copy(targetPath);
      return targetPath;
    } catch (e) {
      debugPrint('Fallback copy failed: $e');
    }

    return null;
  }

  /// Shares backup file using system share sheet (Save to Drive, send to WhatsApp/USB/Files)
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

  /// Restores database from a user-selected backup file (.db)
  Future<String> restoreFromBackupPicker() async {
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

    return await restoreFromFile(pickedPath);
  }

  /// Validates and restores database from a specific file path
  Future<String> restoreFromFile(String backupFilePath) async {
    final backupFile = File(backupFilePath);
    if (!await backupFile.exists()) {
      throw Exception('ملف النسخة الاحتياطية غير موجود');
    }

    final fileSize = await backupFile.length();
    if (fileSize < 100) {
      throw Exception('الملف فارغ أو تالف وغير صالح كقاعدة بيانات');
    }

    // Validate SQLite Header ("SQLite format 3\0")
    final headerBytes = await backupFile.openRead(0, 16).first;
    const expectedHeader = [0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, 0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00];
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
      throw Exception('الملف المحدد ليس قاعدة بيانات SQLite صالحة لتطبيق نبض البيطري');
    }

    // Step 1: Close active database
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

    return 'تمت استعادة قاعدة البيانات بنجاح (${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB)';
  }
}
