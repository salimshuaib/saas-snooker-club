import 'package:intl/intl.dart';

/// DateTime utility extensions.
extension DateExtensions on DateTime {
  /// Format as 'dd MMM yyyy' (e.g., '13 Jul 2026')
  String get formatted => DateFormat('dd MMM yyyy').format(this);

  /// Format as 'dd/MM/yyyy'
  String get shortFormatted => DateFormat('dd/MM/yyyy').format(this);

  /// Format as 'hh:mm a' (e.g., '02:30 PM')
  String get timeFormatted => DateFormat('hh:mm a').format(this);

  /// Format as 'dd MMM yyyy, hh:mm a'
  String get fullFormatted => DateFormat('dd MMM yyyy, hh:mm a').format(this);

  /// Format as 'EEEE, dd MMM yyyy' (e.g., 'Sunday, 13 Jul 2026')
  String get dayFormatted => DateFormat('EEEE, dd MMM yyyy').format(this);

  /// Format as 'MMM yyyy' (e.g., 'Jul 2026')
  String get monthFormatted => DateFormat('MMM yyyy').format(this);

  /// Check if this date is today.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if this date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if this date is tomorrow.
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Get start of day (00:00:00).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get end of day (23:59:59).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  /// Get a relative label.
  String get relativeLabel {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';
    return formatted;
  }
}
