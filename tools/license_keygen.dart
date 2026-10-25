import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

const String kSecretKey = 'VETPULSE_HMAC_SECRET_KEY_2026_SA_YE_SECURE_AUTH';

void main(List<String> args) {
  stdout.writeln('===============================================================');
  stdout.writeln('🛡️  VetPulse Cryptographic License Key Generator (Developer CLI)');
  stdout.writeln('===============================================================');

  if (args.isEmpty) {
    stdout.writeln('Usage:');
    stdout.writeln('  dart run tools/license_keygen.dart <DEVICE_REQUEST_CODE> <DAYS_VALID>');
    stdout.writeln('');
    stdout.writeln('Examples:');
    stdout.writeln('  dart run tools/license_keygen.dart VP1-8F3A9C120B4E-20261025-A1B2 30      (30-day trial)');
    stdout.writeln('  dart run tools/license_keygen.dart VP1-8F3A9C120B4E-20261025-A1B2 365     (1-year subscription)');
    stdout.writeln('  dart run tools/license_keygen.dart VP1-8F3A9C120B4E-20261025-A1B2 lifetime(Permanent license)');
    stdout.writeln('===============================================================');
    exit(1);
  }

  final rawRequestCode = args[0].trim().toUpperCase();
  final daysArg = args.length > 1 ? args[1].trim().toLowerCase() : '30';

  String cleanFingerprint;
  String? requestYmd;

  if (rawRequestCode.startsWith('VP1-')) {
    final parts = rawRequestCode.split('-');
    if (parts.length != 4) {
      stderr.writeln('❌ Error: Invalid Device Request Code format.');
      exit(1);
    }
    cleanFingerprint = parts[1];
    requestYmd = parts[2];
    final chk4 = parts[3];

    // Verify request checksum
    final hmac = Hmac(sha256, utf8.encode(kSecretKey));
    final expectedChkBytes = hmac.convert(utf8.encode('$cleanFingerprint|$requestYmd')).bytes;
    final expectedChk4 = expectedChkBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase()
        .substring(0, 4);

    if (chk4 != expectedChk4) {
      stdout.writeln('⚠️  Warning: Request HMAC checksum does not match secret key.');
    } else {
      stdout.writeln('✅ Verified Request Checksum: Authentic VetPulse Device Request.');
    }
  } else {
    cleanFingerprint = rawRequestCode.replaceAll('-', '');
  }

  if (cleanFingerprint.length != 12) {
    stderr.writeln('❌ Error: Device Fingerprint must be 12 hex characters (got ${cleanFingerprint.length}).');
    exit(1);
  }

  final bool isLifetime = daysArg == '0' || daysArg == 'lifetime' || daysArg == 'forever' || daysArg == 'permanent';
  final int days = isLifetime ? 9999 : (int.tryParse(daysArg) ?? 30);

  final DateTime now = DateTime.now();
  final DateTime expiryDate = isLifetime ? DateTime(9999, 12, 31) : now.add(Duration(days: days));

  final expiryYmd = isLifetime
      ? '99991231'
      : '${expiryDate.year.toString().padLeft(4, '0')}'
          '${expiryDate.month.toString().padLeft(2, '0')}'
          '${expiryDate.day.toString().padLeft(2, '0')}';

  // 4-character random/fixed nonce
  final nonce4 = '9A7F';

  final hmac = Hmac(sha256, utf8.encode(kSecretKey));
  final sigBytes = hmac.convert(utf8.encode('$cleanFingerprint|$expiryYmd|$nonce4')).bytes;
  final sig12 = sigBytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase()
      .substring(0, 12);

  final activationCode = 'VPACT-$expiryYmd-$nonce4-$sig12';

  stdout.writeln('');
  stdout.writeln('📱 Device Fingerprint : $cleanFingerprint');
  if (requestYmd != null) {
    stdout.writeln('📅 Request Date       : $requestYmd');
  }
  stdout.writeln('⏳ Validity Period    : ${isLifetime ? 'دائم (Lifetime / مدى الحياة)' : '$days يوم ($days Days)'}');
  stdout.writeln('🛑 Expiry Date (ISO)  : ${isLifetime ? '9999-12-31' : expiryDate.toIso8601String().substring(0, 10)}');
  stdout.writeln('');
  stdout.writeln('===============================================================');
  stdout.writeln('🔑 ACTIVATION CODE TO SEND TO CLIENT:');
  stdout.writeln('   $activationCode');
  stdout.writeln('===============================================================');
  stdout.writeln('');
  stdout.writeln('📋 WhatsApp Reply Message Template:');
  stdout.writeln('---------------------------------------------------------------');
  stdout.writeln('أهلاً بكم في VetPulse للرعاية البيطرية المتقدمة.');
  stdout.writeln('تم توثيق جهازكم وتوليد كود التفعيل المعتمد بنجاح:');
  stdout.writeln('');
  stdout.writeln(activationCode);
  stdout.writeln('');
  stdout.writeln('مدة الصلاحية: ${isLifetime ? 'ترخيص دائم مدى الحياة' : '$days يوم حتى ${expiryDate.toIso8601String().substring(0, 10)}'}');
  stdout.writeln('يرجى نسخ الكود ولصقه في شاشة التفعيل بالنظام.');
  stdout.writeln('---------------------------------------------------------------');
}
