import 'dart:io';

void main() {
  var file = File('lib/features/analytics/providers/analytics_providers.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll(
    'else perMinBilled += g.grandTotal;',
    'else perMinBilled += (g.grandTotal ?? 0.0);',
  );
  file.writeAsStringSync(content);
}
