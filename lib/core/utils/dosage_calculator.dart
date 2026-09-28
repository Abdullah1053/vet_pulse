/// Veterinary Dosage Calculator
/// Formula: Calculated Dose (ml or tablets) = (Pet Weight in kg × Dose Rate in mg/kg) / Concentration (mg/ml or mg/tablet)
class DosageCalculator {
  DosageCalculator._();

  /// Calculates required dose volume or units
  /// Returns null if inputs are invalid or zero/negative
  static double? calculateDose({
    required double weightKg,
    required double doseRateMgPerKg,
    required double concentrationMgPerUnit,
  }) {
    if (weightKg <= 0 || doseRateMgPerKg <= 0 || concentrationMgPerUnit <= 0) {
      return null;
    }
    final totalMgRequired = weightKg * doseRateMgPerKg;
    final doseUnits = totalMgRequired / concentrationMgPerUnit;
    return double.parse(doseUnits.toStringAsFixed(2));
  }

  /// Format friendly description for medical notes or prescription
  static String formatCalculationSummary({
    required double weightKg,
    required double doseRateMgPerKg,
    required double concentrationMgPerUnit,
    required String unitName, // e.g. "مل" or "قرص"
  }) {
    final result = calculateDose(
      weightKg: weightKg,
      doseRateMgPerKg: doseRateMgPerKg,
      concentrationMgPerUnit: concentrationMgPerUnit,
    );
    if (result == null) return '';
    final totalMg = (weightKg * doseRateMgPerKg).toStringAsFixed(1);
    return '$result $unitName (الجرعة الإجمالية: $totalMg مجم بوزن $weightKg كجم)';
  }
}
