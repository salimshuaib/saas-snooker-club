import 'package:snooker_club/core/models/currency.dart';

/// Helper class for formatting amounts with the selected currency.
class CurrencyHelper {
  CurrencyHelper._();

  /// Format a numeric amount with the given currency.
  static String format(double amount, Currency currency) {
    final formatted = amount.toStringAsFixed(2);
    return '${currency.symbol} $formatted';
  }

  /// Format without decimals for whole numbers.
  static String formatWhole(double amount, Currency currency) {
    if (amount == amount.roundToDouble()) {
      return '${currency.symbol} ${amount.toInt()}';
    }
    return format(amount, currency);
  }

  /// Format with compact notation (e.g., 1.2K, 5.3M).
  static String formatCompact(double amount, Currency currency) {
    if (amount >= 1000000) {
      return '${currency.symbol} ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${currency.symbol} ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatWhole(amount, currency);
  }
}
