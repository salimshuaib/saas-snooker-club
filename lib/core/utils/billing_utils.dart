class BillingUtils {
  static double roundAmount(double amount) {
    if (amount <= 0) return 0.0;

    // Use exact boundary matching for 5-based increments as specified:
    // 0-2 -> 0, 3-7 -> 5, 8-12 -> 10, etc.
    // Mathematically, this is exactly: round(amount / 5.0) * 5.0
    final rounded = (amount / 5.0).round() * 5.0;
    return rounded;
  }
}
