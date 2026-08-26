import 'dart:io';

void main() {
  var file = File('lib/features/analytics/providers/analytics_providers.dart');
  var content = file.readAsStringSync();

  // 1. Add AppColors import if missing
  if (!content.contains('core/theme/app_colors.dart')) {
    content = "import 'package:snooker_club/core/theme/app_colors.dart';\n" + content;
  }

  // 2. Fix GameStatus.completed -> TableStatus.completed
  content = content.replaceAll('g.status != GameStatus.completed', 'g.status != TableStatus.completed');

  // 3. Fix PaymentStatus.pending -> 'pending'
  content = content.replaceAll("g.paymentStatus == PaymentStatus.pending", "g.paymentStatus == 'pending'");

  // 4. Fix split payments logic (playerPaymentMethods / playerLiabilities)
  var splitStr = '''if (g.playerPaymentMethods.isNotEmpty) {
      for (final kv in g.playerPaymentMethods.entries) {
        final amount = kv.value;
        if (amount == null) continue;
        if (kv.key == PaymentMethod.cash.name) cashCollected += amount;
        else if (kv.key == PaymentMethod.upi.name) upiCollected += amount;
        else if (kv.key == PaymentMethod.credit.name) creditCreated += amount;
      }
    }''';
  var newSplitStr = '''if (g.playerPaymentMethods != null && g.playerPaymentMethods!.isNotEmpty) {
      for (final kv in g.playerPaymentMethods!.entries) {
        final amount = g.playerLiabilities?[kv.key] ?? 0.0;
        if (kv.value == PaymentMethod.cash) cashCollected += amount;
        else if (kv.value == PaymentMethod.upi) upiCollected += amount;
        else if (kv.value == PaymentMethod.credit) creditCreated += amount;
      }
    }''';
  content = content.replaceFirst(splitStr, newSplitStr);

  // 5. Fix QuickSale isPaid
  content = content.replaceAll('if (!q.isPaid) continue;', '');

  // 6. Fix GameOrder totalPrice -> quantity * pricePerUnit
  content = content.replaceAll('item.totalPrice', '(item.quantity * item.pricePerUnit)');

  // 7. Remove dead code in trendMap peak hours
  content = content.replaceAll('int i = e.key;', 'final i = e.key;');

  // 8. Fix g.grandTotal nullability
  content = content.replaceAll('totalBilled += g.grandTotal;', 'totalBilled += (g.grandTotal ?? 0.0);');
  content = content.replaceAll('totalGameBilled += g.grandTotal;', 'totalGameBilled += (g.grandTotal ?? 0.0);');
  content = content.replaceAll('cashCollected += g.grandTotal;', 'cashCollected += (g.grandTotal ?? 0.0);');
  content = content.replaceAll('upiCollected += g.grandTotal;', 'upiCollected += (g.grandTotal ?? 0.0);');
  content = content.replaceAll('creditCreated += g.grandTotal;', 'creditCreated += (g.grandTotal ?? 0.0);');

  // 9. Fix pricingMode -> billingType and nullable g.grandTotal in Game modes
  // (We already patched this, but some ?? 0.0 might be missing in cat maps)
  content = content.replaceAll('totalBilled: cat.totalBilled + g.grandTotal,', 'totalBilled: cat.totalBilled + (g.grandTotal ?? 0.0),');
  content = content.replaceAll('averageTransactionValue: (cat.totalBilled + g.grandTotal) / (cat.transactionCount + 1),', 'averageTransactionValue: (cat.totalBilled + (g.grandTotal ?? 0.0)) / (cat.transactionCount + 1),');
  
  content = content.replaceAll('totalBilled: tbl.totalBilled + g.grandTotal,', 'totalBilled: tbl.totalBilled + (g.grandTotal ?? 0.0),');
  content = content.replaceAll('averageSessionValue: (tbl.totalBilled + g.grandTotal) / (tbl.sessionsCount + 1),', 'averageSessionValue: (tbl.totalBilled + (g.grandTotal ?? 0.0)) / (tbl.sessionsCount + 1),');

  content = content.replaceAll('trendMap[label] = (trendMap[label] ?? 0) + g.grandTotal;', 'trendMap[label] = (trendMap[label] ?? 0) + (g.grandTotal ?? 0.0);');

  file.writeAsStringSync(content);
  print('Analytics patched for errors');
}
