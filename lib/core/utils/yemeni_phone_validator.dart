/// Shared validator and formatter for Yemeni Mobile Phone Numbers (+967).
class YemeniPhoneValidator {
  YemeniPhoneValidator._();

  /// Supported Yemeni Mobile Network Operators:
  /// - 77: Yemen Mobile (CDMA / VoLTE)
  /// - 78: Yemen Mobile (4G LTE)
  /// - 73: YOU (formerly MTN Yemen)
  /// - 71: SabaFon
  /// - 70: Y Telecom
  static const List<String> validPrefixes = ['77', '78', '73', '71', '70'];

  /// Fixed Country Code
  static const String countryCode = '+967';

  /// Extracts the 9 local subscriber digits from any input variation
  /// (e.g. "+967771234567", "00967771234567", "0771234567", "771234567").
  static String cleanDigits(String? raw) {
    if (raw == null) return '';
    var cleaned = raw.replaceAll(RegExp(r'\D'), '');

    if (cleaned.startsWith('00967')) {
      cleaned = cleaned.substring(5);
    } else if (cleaned.startsWith('967')) {
      cleaned = cleaned.substring(3);
    }

    if (cleaned.startsWith('0') && cleaned.length > 9) {
      cleaned = cleaned.substring(1);
    }

    return cleaned;
  }

  /// Form field validator for Yemeni phone numbers.
  static String? validate(String? value, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'رقم الهاتف مطلوب' : null;
    }

    final digits = cleanDigits(value);

    if (digits.isEmpty) {
      return isRequired ? 'رقم الهاتف مطلوب' : null;
    }

    if (digits.length != 9) {
      return 'رقم الهاتف اليمني يجب أن يتكون من 9 أرقام بالضبط';
    }

    final prefix = digits.substring(0, 2);
    if (!validPrefixes.contains(prefix)) {
      return 'يجب أن يبدأ الرقم برمز شبكة يمنية معتمد (77، 78، 73، 71، 70)';
    }

    return null;
  }

  /// Checks if the input is a valid Yemeni phone number.
  static bool isValid(String? value, {bool isRequired = true}) {
    return validate(value, isRequired: isRequired) == null;
  }

  /// Standardizes the number to international format: +967XXXXXXXXX
  static String formatWithCountryCode(String raw) {
    final digits = cleanDigits(raw);
    if (digits.length == 9) {
      return '$countryCode$digits';
    }
    final trimmed = raw.trim();
    if (trimmed.startsWith(countryCode)) return trimmed;
    return '$countryCode$trimmed';
  }
}
