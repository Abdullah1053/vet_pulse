import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../data/database/database_helper.dart';
import '../../data/database/database_tables.dart';

enum LicenseStatus {
  unactivated,
  active,
  expired,
  clockTampered,
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

  /// Generates the copyable user request string: `VP1-<FP12>-<YYYYMMDD>-<CHK4>`
  String getDeviceRequestCode(String formattedFingerprint) {
    final cleanFp = formattedFingerprint.replaceAll('-', '').toUpperCase();
    final now = DateTime.now();
    final ymd = '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';

    final hmac = Hmac(sha256, _secretKeyBytes);
    final chkBytes = hmac.convert(utf8.encode('$cleanFp|$ymd')).bytes;
    final chk4 = chkBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase().substring(0, 4);

    return 'VP1-$cleanFp-$ymd-$chk4';
  }

  /// Verifies an activation code and stores the license state upon success
  Future<bool> verifyAndActivateCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();

    // Code Format: VPACT-<EXPIRY_YYYYMMDD>-<NONCE4>-<SIG12>
    final parts = code.split('-');
    if (parts.length != 4 || parts[0] != 'VPACT') {
      _showFeedback(
        'كود غير صالح',
        'صيغة كود التفعيل غير صحيحة، يجب أن تبدأ بـ VPACT-',
      );
      return false;
    }

    final expiryYmd = parts[1];
    final nonce4 = parts[2];
    final sig12 = parts[3];

    final validHex12 = RegExp(r'^[0-9A-F]{12}$');
    final validYmd = RegExp(r'^\d{8}$');
    if (!validYmd.hasMatch(expiryYmd) || nonce4.length != 4 || !validHex12.hasMatch(sig12)) {
      _showFeedback(
        'كود غير صالح',
        'أجزاء كود التفعيل غير مكتملة أو غير صالحة',
      );
      return false;
    }

    // 1. Verify Signature matches current device's fingerprint (constant-time)
    final hmac = Hmac(sha256, _secretKeyBytes);
    final expectedSigBytes = hmac.convert(utf8.encode('$cleanFingerprint|$expiryYmd|$nonce4')).bytes;
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

    // 2. Verify SHA-256 hash is NOT in used_codes_json
    final db = await DatabaseHelper.instance.database;
    final rowList = await db.query(DatabaseTables.tableAppLicenseState, limit: 1);
    List<dynamic> usedCodes = [];
    if (rowList.isNotEmpty && rowList.first['used_codes_json'] != null) {
      try {
        usedCodes = jsonDecode(rowList.first['used_codes_json'] as String) as List<dynamic>;
      } catch (_) {
        usedCodes = [];
      }
    }

    final codeHash = sha256.convert(utf8.encode(code)).toString().toUpperCase();
    if (usedCodes.contains(codeHash)) {
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

    // Update persistent state
    usedCodes.add(codeHash);
    final nowIso = DateTime.now().toIso8601String();

    await db.update(
      DatabaseTables.tableAppLicenseState,
      {
        'activation_code': code,
        'activated_at': nowIso,
        'expiry_date': formattedExpiryIso,
        'last_seen_timestamp': nowIso,
        'used_codes_json': jsonEncode(usedCodes),
      },
      where: 'id = 1',
    );

    // Update in-memory reactive state
    licenseStatus.value = LicenseStatus.active;
    isLicenseActive.value = true;
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

  /// Checks persistent database state, clock-rollback tampering, and expiration date
  Future<LicenseStatus> checkLicenseValidity() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query(DatabaseTables.tableAppLicenseState, limit: 1);

    if (res.isEmpty) {
      final fp = deviceFingerprint.value.isNotEmpty ? deviceFingerprint.value : await getDeviceFingerprint();
      deviceFingerprint.value = fp;
      deviceRequestCode.value = getDeviceRequestCode(fp);

      final nowIso = DateTime.now().toIso8601String();
      await db.insert(DatabaseTables.tableAppLicenseState, {
        'id': 1,
        'onboarding_completed': 0,
        'clinic_setup_completed': 0,
        'device_fingerprint': fp,
        'activation_code': null,
        'activated_at': null,
        'expiry_date': null,
        'last_seen_timestamp': nowIso,
        'used_codes_json': '[]',
      });

      onboardingCompleted.value = false;
      clinicSetupCompleted.value = false;
      isLicenseActive.value = false;
      isExpired.value = false;
      isClockTampered.value = false;
      licenseStatus.value = LicenseStatus.unactivated;
      return LicenseStatus.unactivated;
    }

    final row = res.first;
    onboardingCompleted.value = (row['onboarding_completed'] as int? ?? 0) == 1;
    clinicSetupCompleted.value = (row['clinic_setup_completed'] as int? ?? 0) == 1;

    final actCode = row['activation_code'] as String?;
    final expiry = row['expiry_date'] as String?;
    final lastSeen = row['last_seen_timestamp'] as String?;

    if (actCode == null || actCode.isEmpty || expiry == null || expiry.isEmpty) {
      isLicenseActive.value = false;
      isExpired.value = false;
      isClockTampered.value = false;
      licenseStatus.value = LicenseStatus.unactivated;
      return LicenseStatus.unactivated;
    }

    // Clock Tamper Detection (check if clock was turned back > 6 hours)
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
    String? nonce,
  }) {
    final cleanFp = cleanFingerprint.replaceAll('-', '').toUpperCase();
    final ymd = expiryDate.year >= 9999
        ? '99991231'
        : '${expiryDate.year.toString().padLeft(4, '0')}'
            '${expiryDate.month.toString().padLeft(2, '0')}'
            '${expiryDate.day.toString().padLeft(2, '0')}';

    final nonce4 = (nonce ?? '9A7F').toUpperCase().padLeft(4, '0').substring(0, 4);

    final hmac = Hmac(sha256, _secretKeyBytes);
    final sigBytes = hmac.convert(utf8.encode('$cleanFp|$ymd|$nonce4')).bytes;
    final sig12 = sigBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase()
        .substring(0, 12);

    return 'VPACT-$ymd-$nonce4-$sig12';
  }
}
