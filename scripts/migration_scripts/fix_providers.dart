import 'dart:io';

void main() {
  var file = File('lib/features/analytics/providers/analytics_providers.dart');
  var content = file.readAsStringSync();

  // Fix GameStatus.completed -> TableStatus.available
  content = content.replaceAll(
    'g.status != TableStatus.completed',
    'g.status != TableStatus.available',
  );

  // Fix pricingMode manually using regex
  content = content.replaceAll(
    RegExp(r"if \(g\.pricingMode.*?\).*?;", dotAll: true),
    "if (g.billingType == BillingType.perFrame) perFrameBilled += g.grandTotal ?? 0.0;",
  );
  content = content.replaceAll(
    RegExp(r"else perMinBilled \+= g\.grandTotal \?\? 0\.0;"),
    "else perMinBilled += g.grandTotal ?? 0.0;",
  );

  file.writeAsStringSync(content);
}
