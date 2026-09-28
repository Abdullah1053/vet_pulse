import 'package:intl/intl.dart';

enum ExpiryStatus {
  expired,
  nearExpiry, // < 30 days
  valid,
}

class ArabicDateHelper {
  ArabicDateHelper._();

  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _arabicReadableFormat = DateFormat('yyyy/MM/dd', 'ar');
  static final DateFormat _timeFormat = DateFormat('hh:mm a', 'ar');

  static String formatIso(DateTime date) => _isoDateFormat.format(date);

  static String formatReadable(DateTime date) {
    try {
      return _arabicReadableFormat.format(date);
    } catch (_) {
      return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    }
  }

  static String formatTime(DateTime dateTime) {
    try {
      return _timeFormat.format(dateTime);
    } catch (_) {
      return '${dateTime.hour}:${dateTime.minute}';
    }
  }

  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// Calculates expiration status of a medicine or batch
  static ExpiryStatus checkExpiryStatus(DateTime expiryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);

    if (target.isBefore(today)) {
      return ExpiryStatus.expired;
    }

    final diffDays = target.difference(today).inDays;
    if (diffDays <= 30) {
      return ExpiryStatus.nearExpiry;
    }

    return ExpiryStatus.valid;
  }

  /// Returns remaining days or passed days
  static int daysDifference(DateTime targetDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(targetDate.year, targetDate.month, targetDate.day);
    return target.difference(today).inDays;
  }

  /// Formats appointment / follow-up timing relative label
  static String getRelativeDayLabel(DateTime targetDate) {
    final diff = daysDifference(targetDate);
    if (diff < 0) {
      return 'متأخرة منذ ${diff.abs()} يوم';
    } else if (diff == 0) {
      return 'اليوم';
    } else if (diff == 1) {
      return 'غداً';
    } else if (diff == 2) {
      return 'بعد يومين';
    } else {
      return 'بعد $diff أيام';
    }
  }
}
