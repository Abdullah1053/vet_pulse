import 'package:flutter_test/flutter_test.dart';
import 'package:vet_pulse/core/utils/yemeni_phone_validator.dart';

void main() {
  group('YemeniPhoneValidator Tests', () {
    test('Validates valid Yemeni mobile numbers across all supported networks', () {
      expect(YemeniPhoneValidator.validate('771234567'), isNull); // Yemen Mobile
      expect(YemeniPhoneValidator.validate('781234567'), isNull); // Yemen Mobile 4G
      expect(YemeniPhoneValidator.validate('731234567'), isNull); // YOU (MTN)
      expect(YemeniPhoneValidator.validate('711234567'), isNull); // SabaFon
      expect(YemeniPhoneValidator.validate('701234567'), isNull); // Y Telecom

      expect(YemeniPhoneValidator.isValid('771234567'), isTrue);
      expect(YemeniPhoneValidator.isValid('781234567'), isTrue);
      expect(YemeniPhoneValidator.isValid('731234567'), isTrue);
      expect(YemeniPhoneValidator.isValid('711234567'), isTrue);
      expect(YemeniPhoneValidator.isValid('701234567'), isTrue);
    });

    test('Rejects invalid phone numbers with wrong prefixes', () {
      expect(YemeniPhoneValidator.validate('721234567'), isNotNull);
      expect(YemeniPhoneValidator.validate('791234567'), isNotNull);
      expect(YemeniPhoneValidator.validate('051234567'), isNotNull);
      expect(YemeniPhoneValidator.validate('123456789'), isNotNull);

      expect(YemeniPhoneValidator.isValid('721234567'), isFalse);
    });

    test('Rejects numbers with invalid length', () {
      expect(YemeniPhoneValidator.validate('77123456'), isNotNull); // 8 digits
      expect(YemeniPhoneValidator.validate('7712345678'), isNotNull); // 10 digits
      expect(YemeniPhoneValidator.validate(''), isNotNull);
      expect(YemeniPhoneValidator.validate(null), isNotNull);
    });

    test('Handles optional phone number validation', () {
      expect(YemeniPhoneValidator.validate('', isRequired: false), isNull);
      expect(YemeniPhoneValidator.validate(null, isRequired: false), isNull);
      expect(YemeniPhoneValidator.validate('   ', isRequired: false), isNull);
      expect(YemeniPhoneValidator.validate('771234567', isRequired: false), isNull);
      expect(YemeniPhoneValidator.validate('721234567', isRequired: false), isNotNull);
    });

    test('cleanDigits strips non-digits and international codes properly', () {
      expect(YemeniPhoneValidator.cleanDigits('+967 771-234-567'), equals('771234567'));
      expect(YemeniPhoneValidator.cleanDigits('00967771234567'), equals('771234567'));
      expect(YemeniPhoneValidator.cleanDigits('0771234567'), equals('771234567'));
      expect(YemeniPhoneValidator.cleanDigits('771234567'), equals('771234567'));
    });

    test('formatWithCountryCode formats number with +967 prefix', () {
      expect(YemeniPhoneValidator.formatWithCountryCode('771234567'), equals('+967771234567'));
      expect(YemeniPhoneValidator.formatWithCountryCode('+967771234567'), equals('+967771234567'));
      expect(YemeniPhoneValidator.formatWithCountryCode('0771234567'), equals('+967771234567'));
    });
  });
}
