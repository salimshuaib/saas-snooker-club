import 'dart:io';

void main() {
  var file = File('lib/features/analytics/providers/analytics_providers.dart');
  var content = file.readAsStringSync();

  // Replace gameCategory with tableType.displayName
  content = content.replaceAll('g.gameCategory', 'g.tableType.displayName');

  // Replace isTpGame logic
  content = content.replaceFirst(
    'if (g.isTpGame) { tpBilled += g.grandTotal; tpCount++; }',
    'if (g.matchType == MatchType.loserPays) { tpBilled += g.grandTotal ?? 0.0; tpCount++; }',
  );
  content = content.replaceFirst(
    'else { friendlyBilled += g.grandTotal; friendlyCount++; }',
    'else { friendlyBilled += g.grandTotal ?? 0.0; friendlyCount++; }',
  );

  // Replace pricingMode logic
  var oldPricingStr =
      '''if (g.pricingMode.toLowerCase().contains('frame')) perFrameBilled += g.grandTotal;
    else perMinBilled += g.grandTotal;''';
  var newPricingStr =
      '''if (g.billingType == BillingType.perFrame) perFrameBilled += g.grandTotal ?? 0.0;
    else perMinBilled += g.grandTotal ?? 0.0;''';
  content = content.replaceFirst(oldPricingStr, newPricingStr);

  // Fix nullable g.grandTotal
  content = content.replaceAll('+ g.grandTotal', '+ (g.grandTotal ?? 0.0)');

  file.writeAsStringSync(content);
}
