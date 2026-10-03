class BillingUtils {
  static double roundAmount(double amount) {
    if (amount <= 0) return 0.0;

    // Use exact boundary matching for 5-based increments as specified:
    // 0-2 -> 0, 3-7 -> 5, 8-12 -> 10, etc.
    // Mathematically, this is exactly: round(amount / 5.0) * 5.0
    final rounded = (amount / 5.0).round() * 5.0;
    return rounded;
  }
  static List<double> generateFinalAmountOptions(double amount, {int incrementPaise = 1000}) {
    if (amount <= 0) return [];
    
    final incrementRupees = incrementPaise / 100.0;
    
    // Using integer division on paise to avoid floating-point errors
    final amountPaise = (amount * 100).round();
    
    if (amountPaise % incrementPaise == 0) {
      return [amountPaise / 100.0];
    }
    
    final lowerPaise = (amountPaise ~/ incrementPaise) * incrementPaise;
    final upperPaise = lowerPaise + incrementPaise;
    
    return [lowerPaise / 100.0, upperPaise / 100.0];
  }
}
