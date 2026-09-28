import 'package:flutter_test/flutter_test.dart';
import 'package:vet_pulse/core/utils/dosage_calculator.dart';
import 'package:vet_pulse/core/utils/arabic_date_helper.dart';

void main() {
  group('DosageCalculator Tests', () {
    test('Calculates dose correctly based on weight, rate and concentration', () {
      // Pet weight = 10kg, Dose rate = 5mg/kg, Concentration = 50mg/ml
      // Total mg needed = 50mg -> Volume = 50 / 50 = 1.0 ml
      final dose = DosageCalculator.calculateDose(
        weightKg: 10,
        doseRateMgPerKg: 5,
        concentrationMgPerUnit: 50,
      );
      expect(dose, 1.0);
    });

    test('Returns null on invalid negative or zero values', () {
      final invalidWeight = DosageCalculator.calculateDose(
        weightKg: 0,
        doseRateMgPerKg: 5,
        concentrationMgPerUnit: 50,
      );
      expect(invalidWeight, isNull);
    });
  });

  group('ArabicDateHelper Tests', () {
    test('Correctly determines expiry status', () {
      final expired = DateTime.now().subtract(const Duration(days: 5));
      expect(ArabicDateHelper.checkExpiryStatus(expired), ExpiryStatus.expired);

      final nearExpiry = DateTime.now().add(const Duration(days: 10));
      expect(ArabicDateHelper.checkExpiryStatus(nearExpiry), ExpiryStatus.nearExpiry);

      final valid = DateTime.now().add(const Duration(days: 100));
      expect(ArabicDateHelper.checkExpiryStatus(valid), ExpiryStatus.valid);
    });

    test('Relative day labels in Arabic', () {
      final today = DateTime.now();
      expect(ArabicDateHelper.getRelativeDayLabel(today), 'اليوم');

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(ArabicDateHelper.getRelativeDayLabel(tomorrow), 'غداً');
    });
  });
}
