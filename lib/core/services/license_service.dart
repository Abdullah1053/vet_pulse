import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../data/database/database_helper.dart';
import '../../data/database/database_tables.dart';

enum LicenseStatus {
  unactivated,
  active,
  expired,
  clockTampered,
  deviceMismatch,
}

class LicenseService extends GetxService {
  static LicenseService get to =>
      Get.isRegistered<LicenseService>() ? Get.find<LicenseService>() : Get.put(LicenseService(), permanent: true);

  // XOR-Masked Cryptographic Secret Salt & HMAC Signing Key
  static const List<int> _kXorMask = [0x56, 0x7E, 0x54, 0x50, 0x32, 0x30, 0x32, 0x36];
  static const List<int> _kMaskedKey = [
    0x00, 0x3B, 0x00, 0x00, 0x67, 0x7C, 0x61, 0x73, 0x09, 0x36, 0x19, 0x11, 0x71, 0x6F, 0x61, 0x73,
    0x15, 0x2C, 0x11, 0x04, 0x6D, 0x7B, 0x77, 0x6F, 0x09, 0x4C, 0x64, 0x62, 0x04, 0x6F, 0x61, 0x77,
    0x09, 0x27, 0x11, 0x0F, 0x61, 0x75, 0x71, 0x63, 0x04, 0x3B, 0x0B, 0x11, 0x67, 0x64, 0x7A,
  ];
  static const List<int> _kMaskedSalt = [
    0x00, 0x3B, 0x00, 0x00, 0x67, 0x7C, 0x61, 0x73, 0x09, 0x3A, 0x11, 0x06, 0x7B, 0x73, 0x77, 0x69,
    0x05, 0x3F, 0x18, 0x04, 0x6D, 0x09, 0x0B, 0x02, 0x64, 0x21, 0x07, 0x15, 0x71, 0x65, 0x60, 0x73,
    0x09, 0x36, 0x15, 0x03, 0x7A,
  ];

  static List<int> _reconstructSecretBytes(List<int> masked, List<int> mask) {
    return List<int>.generate(masked.length, (i) => masked[i] ^ mask[i % mask.length]);
  }

  static List<int> get _secretKeyBytes => _reconstructSecretBytes(_kMaskedKey, _kXorMask);
  static List<int> get _secretSaltBytes => _reconstructSecretBytes(_kMaskedSalt, _kXorMask);

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  final Rx<LicenseStatus> licenseStatus = LicenseStatus.unactivated.obs;
  final RxBool onboardingCompleted = false.obs;
  final RxBool clinicSetupCompleted = false.obs;
  final RxBool isLicenseActive = false.obs;
  final RxBool isExpired = false.obs;
  final RxBool isClockTampered = false.obs;
  final RxBool isDeviceMismatch = false.obs;
  final RxString deviceFingerprint = ''.obs;
  final RxString deviceRequestCode = ''.obs;
  final RxnString expiryDate = RxnString();
  final RxInt remainingDays = 0.obs;
  final RxBool isLifetime = false.obs;

  /// Clean 12-char uppercase hex fingerprint without dashes
  String get cleanFingerprint => deviceFingerprint.value.replaceAll('-', '').toUpperCase();

  Future<LicenseService> init() async {
    await _initializeLicense();
    return this;
  }

  Future<void> _initializeLicense() async {
    try {
      final fp = await getDeviceFingerprint();
      deviceFingerprint.value = fp;
      deviceRequestCode.value = getDeviceRequestCode(fp);

      await checkLicenseValidity();

      if (kDebugMode) {
        final testCode = generateActivationCode(
          cleanFingerprint: cleanFingerprint,
          expiryDate: DateTime.now().add(const Duration(days: 30)),
        );
        debugPrint('====================================================');
        debugPrint('🔑 [VetPulse Licensing] Device Fingerprint: $deviceFingerprint');
        debugPrint('🔑 [VetPulse Licensing] Device Request Code: ${deviceRequestCode.value}');
        debugPrint('🔑 [VetPulse Licensing] Test 30-Day Activation Code: $testCode');
        debugPrint('🔑 [VetPulse Licensing] Status: ${licenseStatus.value.name}');
        debugPrint('====================================================');
      }
    } catch (e, stack) {
      debugPrint('Error initializing LicenseService: $e\n$stack');
    }
  }

  /// Collects unique hardware identifiers and computes a 12-char fingerprint formatted as XXXX-XXXX-XXXX
  Future<String> getDeviceFingerprint() async {
    final deviceInfo = DeviceInfoPlugin();
    String rawHardware = '';

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        rawHardware = '${webInfo.userAgent}|${webInfo.vendor}|${webInfo.platform}';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        rawHardware = [
          androidInfo.id,
          androidInfo.brand,
          androidInfo.model,
          androidInfo.device,
          androidInfo.board,
          androidInfo.hardware,
        ].join('|');
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        rawHardware = '${iosInfo.identifierForVendor}|${iosInfo.model}|${iosInfo.systemName}';
      } else if (Platform.isWindows) {
        final winInfo = await deviceInfo.windowsInfo;
        rawHardware = '${winInfo.deviceId}|${winInfo.computerName}|${winInfo.numberOfCores}';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        rawHardware = '${linuxInfo.machineId}|${linuxInfo.name}|${linuxInfo.id}';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        rawHardware = '${macInfo.systemGUID}|${macInfo.computerName}|${macInfo.model}';
      } else {
        rawHardware = Platform.operatingSystem;
      }
    } catch (e) {
      debugPrint('Error collecting device info: $e');
      rawHardware = 'VETPULSE_GENERIC_FALLBACK_DEVICE';
    }

    if (rawHardware.trim().isEmpty) {
      rawHardware = 'VETPULSE_DEFAULT_HW_STRING';
    }

    final hashBytes = sha256.convert([...utf8.encode('$rawHardware|'), ..._secretSaltBytes]).bytes;
    final hexStr = hashBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
    final fp12 = hexStr.substring(0, 12);

    return '${fp12.substring(0, 4)}-${fp12.substring(4, 8)}-${fp12.substring(8, 12)}';
  }

  /// Generates the timestamped user request string: `VP1-<FP12>-<TS16>-<CHK4>`
  /// Incorporates current date & time down to the second (14 digits) + 2 hex entropy characters (ENT2).
  String getDeviceRequestCode(String formattedFingerprint) {
    final cleanFp = formattedFingerprint.replaceAll('-', '').toUpperCase();
    final now = DateTime.now();
    final ymdHms = '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    final rnd = Random.secure();
    final ent2 = rnd.nextInt(256).toRadixString(16).padLeft(2, '0').toUpperCase();
    final ts16 = '$ymdHms$ent2';

    final hmac = Hmac(sha256, _secretKeyBytes);
    final chkBytes = hmac.convert(utf8.encode('$cleanFp|$ts16')).bytes;
    final chk4 = chkBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase().substring(0, 4);

    return 'VP1-$cleanFp-$ts16-$chk4';
  }

  /// Refreshes the cached deviceRequestCode with current timestamp
  String refreshDeviceRequestCode() {
    final fp = deviceFingerprint.value.isNotEmpty ? deviceFingerprint.value : cleanFingerprint;
    final code = getDeviceRequestCode(fp);
    deviceRequestCode.value = code;
    return code;
  }

  // --- SECONDARY LOCAL LEDGER (license_ledger.json) ---

  Future<File?> _getLedgerFile() async {
    try {
      Directory dir;
      try {
        dir = await getApplicationSupportDirectory();
      } catch (_) {
        try {
          dir = await getApplicationDocumentsDirectory();
        } catch (_) {
          dir = Directory.current;
        }
      }
      return File(p.join(dir.path, 'license_ledger.json'));
    } catch (e) {
      debugPrint('License ledger path note: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _readLedger() async {
    try {
      final file = await _getLedgerFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        final decoded = jsonDecode(content);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('Error reading license ledger: $e');
    }
    return {'used_hashes': <dynamic>[], 'used_tokens': <dynamic>[]};
  }

  Future<void> _recordToLedger(String codeHash, String reqToken6) async {
    try {
      final ledger = await _readLedger();
      final List<dynamic> hashes = List.from(ledger['used_hashes'] as List? ?? []);
      final List<dynamic> tokens = List.from(ledger['used_tokens'] as List? ?? []);

      if (!hashes.contains(codeHash)) hashes.add(codeHash);
      if (!tokens.contains(reqToken6)) tokens.add(reqToken6);

      ledger['used_hashes'] = hashes;
      ledger['used_tokens'] = tokens;

      final file = await _getLedgerFile();
      if (file != null) {
        await file.writeAsString(jsonEncode(ledger));
      }
    } catch (e) {
      debugPrint('Error writing to license ledger: $e');
    }
  }

  /// Verifies an activation code and stores the license state upon success
  Future<bool> verifyAndActivateCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();

    // Code Format: VPACT-<EXPIRY_YYYYMMDD>-<REQ_TOKEN6>-<SIG12>
    final parts = code.split('-');
    if (parts.length != 4 || parts[0] != 'VPACT') {
      _showFeedback(
        'كود غير صالح',
        'صيغة كود التفعيل غير صحيحة، يجب أن تبدأ بـ VPACT-',
      );
      return false;
    }

    final expiryYmd = parts[1];
    final reqToken6 = parts[2];
    final sig12 = parts[3];

    final validHex12 = RegExp(r'^[0-9A-F]{12}$');
    final validAlphanumeric6 = RegExp(r'^[0-9A-Z]{6}$');
    final validYmd = RegExp(r'^\d{8}$');
    if (!validYmd.hasMatch(expiryYmd) || !validAlphanumeric6.hasMatch(reqToken6) || !validHex12.hasMatch(sig12)) {
      _showFeedback(
        'كود غير صالح',
        'أجزاء كود التفعيل غير مكتملة أو غير صالحة',
      );
      return false;
    }

    // 1. Live Device Signature Verification (constant-time)
    final liveFp = await getDeviceFingerprint();
    final liveCleanFp = liveFp.replaceAll('-', '').toUpperCase();

    final hmac = Hmac(sha256, _secretKeyBytes);
    final expectedSigBytes = hmac.convert(utf8.encode('$liveCleanFp|$expiryYmd|$reqToken6')).bytes;
    final expectedSig12 = expectedSigBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase()
        .substring(0, 12);

    if (!_constantTimeEquals(sig12, expectedSig12)) {
      _showFeedback(
        'فشل التفعيل',
        'كود التفعيل غير مخصص لهذا الجهاز ومقفل على بصمة جهاز آخر',
      );
      return false;
    }

    // 2. Anti-Reuse Check: Verify SHA-256 hash AND reqToken6 in DB AND license_ledger.json
    final codeHash = sha256.convert(utf8.encode(code)).toString().toUpperCase();

    final db = await DatabaseHelper.instance.database;
    final rowList = await db.query(DatabaseTables.tableAppLicenseState, limit: 1);
    List<dynamic> usedCodesInDb = [];
    if (rowList.isNotEmpty && rowList.first['used_codes_json'] != null) {
      try {
        usedCodesInDb = jsonDecode(rowList.first['used_codes_json'] as String) as List<dynamic>;
      } catch (_) {
        usedCodesInDb = [];
      }
    }

    final ledger = await _readLedger();
    final usedHashesInLedger = List<dynamic>.from(ledger['used_hashes'] as List? ?? []);
    final usedTokensInLedger = List<dynamic>.from(ledger['used_tokens'] as List? ?? []);

    final isUsed = usedCodesInDb.contains(codeHash) ||
        usedCodesInDb.contains(reqToken6) ||
        usedHashesInLedger.contains(codeHash) ||
        usedTokensInLedger.contains(reqToken6);

    if (isUsed) {
      _showFeedback(
        'كود مستخدم مسبقاً',
        'تم استخدام كود التفعيل هذا مسبقاً ولا يمكن تكرار استخدامه بعد انتهاء مدته',
      );
      return false;
    }

    // 3. Verify expiry date
    String formattedExpiryIso;
    bool lifetime = false;
    if (expiryYmd == '99991231') {
      formattedExpiryIso = '9999-12-31';
      lifetime = true;
    } else {
      final year = int.tryParse(expiryYmd.substring(0, 4));
      final month = int.tryParse(expiryYmd.substring(4, 6));
      final day = int.tryParse(expiryYmd.substring(6, 8));

      if (year == null || month == null || day == null) {
        _showFeedback('فشل التفعيل', 'تاريخ انتهاء الترخيص في الكود غير صالح');
        return false;
      }

      final expiryDt = DateTime(year, month, day, 23, 59, 59);
      if (expiryDt.isBefore(DateTime.now())) {
        _showFeedback(
          'كود منتهي',
          'كود التفعيل المدخل منتهي الصلاحية بالفعل',
        );
        return false;
      }

      formattedExpiryIso =
          '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    }

    // Update persistent state in DB and file ledger
    usedCodesInDb.add(codeHash);
    usedCodesInDb.add(reqToken6);
    await _recordToLedger(codeHash, reqToken6);

    final nowIso = DateTime.now().toIso8601String();

    await db.update(
      DatabaseTables.tableAppLicenseState,
      {
        'device_fingerprint': liveFp,
        'activation_code': code,
        'activated_at': nowIso,
        'expiry_date': formattedExpiryIso,
        'last_seen_timestamp': nowIso,
        'used_codes_json': jsonEncode(usedCodesInDb),
      },
      where: 'id = 1',
    );

    // Update in-memory reactive state
    deviceFingerprint.value = liveFp;
    licenseStatus.value = LicenseStatus.active;
    isLicenseActive.value = true;
    isDeviceMismatch.value = false;
    isExpired.value = false;
    isClockTampered.value = false;
    isLifetime.value = lifetime;
    expiryDate.value = formattedExpiryIso;
    _computeRemainingDays(formattedExpiryIso, lifetime);

    _showFeedback(
      'تم التفعيل بنجاح! 🎉',
      lifetime
          ? 'تم توثيق ترخيص النظام الدائم للعيادة'
          : 'تم تفعيل النسخة حتى $formattedExpiryIso (متبقي ${remainingDays.value} يوم)',
      duration: const Duration(seconds: 4),
    );

    return true;
  }

  void _showFeedback(String title, String message, {Duration? duration}) {
    if (Get.context != null) {
      try {
        Get.snackbar(
          title,
          message,
          snackPosition: SnackPosition.BOTTOM,
          duration: duration ?? const Duration(seconds: 3),
        );
      } catch (_) {}
    }
  }

  /// Checks persistent database state, cryptographic device identity verification, clock tampering, and expiration
  Future<LicenseStatus> checkLicenseValidity() async {
    final liveFp = await getDeviceFingerprint();
    final liveCleanFp = liveFp.replaceAll('-', '').toUpperCase();
    deviceFingerprint.value = liveFp;

    final db = await DatabaseHelper.instance.database;
    final res = await db.query(DatabaseTables.tableAppLicenseState, limit: 1);

    if (res.isEmpty) {
      final reqCode = getDeviceRequestCode(liveFp);
      deviceRequestCode.value = reqCode;

      final nowIso = DateTime.now().toIso8601String();
      await db.insert(DatabaseTables.tableAppLicenseState, {
        'id': 1,
        'onboarding_completed': 0,
        'clinic_setup_completed': 0,
        'device_fingerprint': liveFp,
        'activation_code': null,
        'activated_at': null,
        'expiry_date': null,
        'last_seen_timestamp': nowIso,
        'used_codes_json': '[]',
      });

      onboardingCompleted.value = false;
      clinicSetupCompleted.value = false;
      isLicenseActive.value = false;
      isDeviceMismatch.value = false;
      isExpired.value = false;
      isClockTampered.value = false;
      licenseStatus.value = LicenseStatus.unactivated;
      return LicenseStatus.unactivated;
    }

    final row = res.first;
    onboardingCompleted.value = (row['onboarding_completed'] as int? ?? 0) == 1;
    clinicSetupCompleted.value = (row['clinic_setup_completed'] as int? ?? 0) == 1;

    final storedFp = (row['device_fingerprint'] as String? ?? '').trim();
    final storedCleanFp = storedFp.replaceAll('-', '').toUpperCase();
    final actCode = row['activation_code'] as String?;
    final expiry = row['expiry_date'] as String?;
    final lastSeen = row['last_seen_timestamp'] as String?;

    // Refresh request code with live fingerprint
    if (deviceRequestCode.value.isEmpty) {
      deviceRequestCode.value = getDeviceRequestCode(liveFp);
    }

    // If no activation code exists yet
    if (actCode == null || actCode.isEmpty || expiry == null || expiry.isEmpty) {
      if (storedFp.isEmpty) {
        await db.update(
          DatabaseTables.tableAppLicenseState,
          {'device_fingerprint': liveFp},
          where: 'id = 1',
        );
      }
      isLicenseActive.value = false;
      isDeviceMismatch.value = false;
      isExpired.value = false;
      isClockTampered.value = false;
      licenseStatus.value = LicenseStatus.unactivated;
      return LicenseStatus.unactivated;
    }

    // 3. Cryptographic Device Identity Verification
    bool signatureValid = false;
    final parts = actCode.split('-');
    if (parts.length == 4 && parts[0] == 'VPACT') {
      final expiryYmd = parts[1];
      final reqToken6 = parts[2];
      final sig12 = parts[3];

      final hmac = Hmac(sha256, _secretKeyBytes);
      final expectedSigBytes = hmac.convert(utf8.encode('$liveCleanFp|$expiryYmd|$reqToken6')).bytes;
      final expectedSig12 = expectedSigBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase()
          .substring(0, 12);

      signatureValid = _constantTimeEquals(sig12, expectedSig12);
    }

    final bool fingerprintMatches = storedCleanFp == liveCleanFp;

    if (!fingerprintMatches || !signatureValid) {
      // Detected database copy or restored backup from a different device!
      isDeviceMismatch.value = true;
      isLicenseActive.value = false;
      licenseStatus.value = LicenseStatus.deviceMismatch;

      // Update device_fingerprint to liveFp and clear activation_code
      // (preserving used_codes_json and preserving 100% of all clinic, patient, surgery, inventory, and financial tables)
      await db.update(
        DatabaseTables.tableAppLicenseState,
        {
          'device_fingerprint': liveFp,
          'activation_code': null,
          'last_seen_timestamp': DateTime.now().toIso8601String(),
        },
        where: 'id = 1',
      );

      return LicenseStatus.deviceMismatch;
    }

    // Device identity is confirmed
    isDeviceMismatch.value = false;

    // 4. Expiration & Clock Tampering Verification
    final now = DateTime.now();
    if (lastSeen != null && lastSeen.isNotEmpty) {
      final lastSeenDt = DateTime.tryParse(lastSeen);
      if (lastSeenDt != null) {
        final diff = now.difference(lastSeenDt);
        if (diff.inMinutes < -360) {
          isClockTampered.value = true;
          isLicenseActive.value = false;
          licenseStatus.value = LicenseStatus.clockTampered;
          return LicenseStatus.clockTampered;
        }
      }
    }

    // Update last seen timestamp
    await db.update(
      DatabaseTables.tableAppLicenseState,
      {'last_seen_timestamp': now.toIso8601String()},
      where: 'id = 1',
    );

    // Expiration check
    final lifetime = expiry == '9999-12-31';
    isLifetime.value = lifetime;
    expiryDate.value = expiry;

    final todayStr = now.toIso8601String().substring(0, 10);
    if (!lifetime && todayStr.compareTo(expiry) > 0) {
      isExpired.value = true;
      isLicenseActive.value = false;
      licenseStatus.value = LicenseStatus.expired;
      remainingDays.value = 0;
      return LicenseStatus.expired;
    }

    // Active
    isLicenseActive.value = true;
    isExpired.value = false;
    isClockTampered.value = false;
    licenseStatus.value = LicenseStatus.active;
    _computeRemainingDays(expiry, lifetime);
    return LicenseStatus.active;
  }

  void _computeRemainingDays(String expiryIso, bool lifetime) {
    if (lifetime) {
      remainingDays.value = 9999;
      return;
    }
    try {
      final parts = expiryIso.split('-');
      final expDt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]), 23, 59, 59);
      final now = DateTime.now();
      final diffDays = expDt.difference(now).inDays + 1;
      remainingDays.value = diffDays > 0 ? diffDays : 0;
    } catch (_) {
      remainingDays.value = 0;
    }
  }

  Future<void> completeOnboarding() async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      DatabaseTables.tableAppLicenseState,
      {'onboarding_completed': 1},
      where: 'id = 1',
    );
    onboardingCompleted.value = true;
  }

  Future<void> completeClinicSetup() async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      DatabaseTables.tableAppLicenseState,
      {'clinic_setup_completed': 1},
      where: 'id = 1',
    );
    clinicSetupCompleted.value = true;
  }

  /// Helper used by developer keygen tool and test generator
  static String generateActivationCode({
    required String cleanFingerprint,
    required DateTime expiryDate,
    String? reqToken,
  }) {
    final cleanFp = cleanFingerprint.replaceAll('-', '').toUpperCase();
    final ymd = expiryDate.year >= 9999
        ? '99991231'
        : '${expiryDate.year.toString().padLeft(4, '0')}'
            '${expiryDate.month.toString().padLeft(2, '0')}'
            '${expiryDate.day.toString().padLeft(2, '0')}';

    final reqToken6 = (reqToken ?? _generateRandomToken6()).toUpperCase().padLeft(6, '0').substring(0, 6);

    final hmac = Hmac(sha256, _secretKeyBytes);
    final sigBytes = hmac.convert(utf8.encode('$cleanFp|$ymd|$reqToken6')).bytes;
    final sig12 = sigBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase()
        .substring(0, 12);

    return 'VPACT-$ymd-$reqToken6-$sig12';
  }

  static String _generateRandomToken6() {
    final rnd = Random.secure();
    return List.generate(6, (_) => rnd.nextInt(16).toRadixString(16)).join().toUpperCase();
  }
}
