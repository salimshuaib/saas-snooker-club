import 'dart:io';
void main() {
  var file = File('lib/features/quick_sales/data/quick_sales_repository.dart');
  var content = file.readAsStringSync();
  content = content.replaceAll('_salesRef.doc', '_quickSalesRef.doc');
  file.writeAsStringSync(content);
}
