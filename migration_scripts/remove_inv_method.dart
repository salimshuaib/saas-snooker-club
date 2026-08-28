import 'dart:io';

void main() {
  var file = File(
    'lib/features/analytics/presentation/widgets/inventory_and_product_analytics_section.dart',
  );
  var content = file.readAsStringSync();

  var startStr = "Widget _buildInventoryInsightsCard(";
  var startIndex = content.indexOf(startStr);

  if (startIndex != -1) {
    content = content.substring(0, startIndex);
    content += "}\n";
    file.writeAsStringSync(content);
  }
}
