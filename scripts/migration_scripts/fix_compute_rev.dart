import 'dart:io';

void main() {
  var file = File('lib/features/analytics/providers/analytics_providers.dart');
  var content = file.readAsStringSync();

  // Find _computeRevenue function
  var startStr =
      "RevenueOverviewData _computeRevenue(List<GameSession> games, List<QuickSale> quickSales, List<PaymentHistory> payments, double outstanding) {";
  var endStr = "  return RevenueOverviewData(";

  var startIndex = content.indexOf(startStr);
  var endIndex = content.indexOf(endStr);

  var newFunc =
      '''RevenueOverviewData _computeRevenue(List<GameSession> games, List<QuickSale> quickSales, List<PaymentHistory> payments, double outstanding) {
  double totalBilled = 0;
  double totalGameBilled = 0;
  double totalQuickSaleBilled = 0;
  double cashCollected = 0;
  double upiCollected = 0;
  double creditCreated = 0;
  double creditCollected = 0;

  for (final g in games) {
    if (g.status != TableStatus.available || g.paymentStatus == 'pending') continue;
    
    totalBilled += (g.grandTotal ?? 0.0);
    totalGameBilled += (g.grandTotal ?? 0.0);
    
    final ppm = g.playerPaymentMethods;
    if (ppm != null && ppm.isNotEmpty) {
      for (final kv in ppm.entries) {
        final amount = g.playerLiabilities?[kv.key] ?? 0.0;
        if (kv.value == PaymentMethod.cash) cashCollected += amount;
        else if (kv.value == PaymentMethod.upi) upiCollected += amount;
        else if (kv.value == PaymentMethod.credit) creditCreated += amount;
      }
    } else {
      final method = g.paymentMethod ?? PaymentMethod.cash;
      if (method == PaymentMethod.cash) cashCollected += (g.grandTotal ?? 0.0);
      else if (method == PaymentMethod.upi) upiCollected += (g.grandTotal ?? 0.0);
      else if (method == PaymentMethod.credit) creditCreated += (g.grandTotal ?? 0.0);
    }
  }

  for (final q in quickSales) {
    totalBilled += q.totalAmount;
    totalQuickSaleBilled += q.totalAmount;
    
    final method = q.paymentMethod;
    if (method == PaymentMethod.cash) cashCollected += q.totalAmount;
    else if (method == PaymentMethod.upi) upiCollected += q.totalAmount;
    else if (method == PaymentMethod.credit) creditCreated += q.totalAmount;
  }

  for (final p in payments) {
    creditCollected += p.amountPaid;
  }

''';

  if (startIndex != -1 && endIndex != -1) {
    content = content.replaceRange(startIndex, endIndex, newFunc);
  }

  // Also fix the perMinBilled += g.grandTotal ?? 0.0; issue which was missing a parens
  content = content.replaceAll(
    'else perMinBilled += g.grandTotal ?? 0.0;',
    'else perMinBilled += (g.grandTotal ?? 0.0);',
  );

  // And the Unused local variable i
  content = content.replaceAll('final i = e.key;', '');

  file.writeAsStringSync(content);
}
