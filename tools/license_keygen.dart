// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

// Exact XOR-masked HMAC key from lib/core/services/license_service.dart
const List<int> _kXorMask = [0x56, 0x7E, 0x54, 0x50, 0x32, 0x30, 0x32, 0x36];
const List<int> _kMaskedKey = [
  0x00, 0x3B, 0x00, 0x00, 0x67, 0x7C, 0x61, 0x73, 0x09, 0x36, 0x19, 0x11, 0x71, 0x6F, 0x61, 0x73,
  0x15, 0x2C, 0x11, 0x04, 0x6D, 0x7B, 0x77, 0x6F, 0x09, 0x4C, 0x64, 0x62, 0x04, 0x6F, 0x61, 0x77,
  0x09, 0x27, 0x11, 0x0F, 0x61, 0x75, 0x71, 0x63, 0x04, 0x3B, 0x0B, 0x11, 0x67, 0x64, 0x7A,
];

List<int> _reconstructSecretBytes() {
  return List<int>.generate(_kMaskedKey.length, (i) => _kMaskedKey[i] ^ _kXorMask[i % _kXorMask.length]);
}

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run tools/license_keygen.dart <DEVICE_REQUEST_CODE_OR_FP> [DAYS_VALID]');
    print('Example: dart run tools/license_keygen.dart VP1-F37E49300544-20261027-AA3C 7');
    return;
  }

  final rawInput = args[0].trim().toUpperCase();
  final int daysValid = args.length > 1 ? (int.tryParse(args[1]) ?? 30) : 30;

  // Extract 12-char fingerprint from VP1-<FP12>-<YYYYMMDD>-<CHK4> or XXXX-XXXX-XXXX
  String cleanFp;
  if (rawInput.startsWith('VP1-')) {
    final parts = rawInput.split('-');
    if (parts.length < 2 || parts[1].length != 12) {
      print('Error: Invalid VP1 request code format.');
      return;
    }
    cleanFp = parts[1];
  } else {
    cleanFp = rawInput.replaceAll('-', '');
  }

  if (cleanFp.length != 12) {
    print('Error: Device fingerprint must be 12 hex characters (got: $cleanFp).');
    return;
  }

  final DateTime expiryDate = daysValid >= 9999
      ? DateTime(9999, 12, 31)
      : DateTime.now().add(Duration(days: daysValid));

  final String ymd = expiryDate.year >= 9999
      ? '99991231'
      : '${expiryDate.year.toString().padLeft(4, '0')}'
        '${expiryDate.month.toString().padLeft(2, '0')}'
        '${expiryDate.day.toString().padLeft(2, '0')}';

  // Generate random 4-char hex nonce so every generated code is unique
  final rnd = Random.secure();
  final nonce4 = List.generate(4, (_) => rnd.nextInt(16).toRadixString(16)).join().toUpperCase();

  final hmac = Hmac(sha256, _reconstructSecretBytes());
  final sigBytes = hmac.convert(utf8.encode('$cleanFp|$ymd|$nonce4')).bytes;
  final sig12 = sigBytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join()
      .toUpperCase()
      .substring(0, 12);

  final activationCode = 'VPACT-$ymd-$nonce4-$sig12';

  print('============================================================');
  print('VetPulse License Keygen');
  print('------------------------------------------------------------');
  print('Device Fingerprint : $cleanFp');
  print('Validity           : ${daysValid >= 9999 ? "LIFETIME" : "$daysValid Days (Expires: ${ymd.substring(0,4)}-${ymd.substring(4,6)}-${ymd.substring(6,8)})"}');
  print('Activation Code    : $activationCode');
  print('============================================================');
}
