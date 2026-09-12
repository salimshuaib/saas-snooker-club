class BillingUtils {
  static double roundAmount(double amount) {
    if (amount <= 0) return 0.0;
    
    // Convert to cents to avoid floating point precision issues
    final cents = (amount * 100).round();
    final remainderCents = cents % 1000;
    final baseCents = cents - remainderCents;
    
    if (remainderCents == 0) {
      return baseCents / 100.0;
    }
    
    if (remainderCents <= 700) {
      return (baseCents + 500) / 100.0;
    } else {
      return (baseCents + 1000) / 100.0;
    }
  }
}
