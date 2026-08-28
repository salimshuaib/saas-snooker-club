import 'dart:io';

void main() {
  var file = File('lib/features/credit/data/credit_repository.dart');
  var content = file.readAsStringSync();

  var insertAfter =
      "Stream<List<PaymentHistory>> watchPaymentHistory(String customerId) {";
  var searchIndex = content.indexOf(insertAfter);
  if (searchIndex == -1) {
    print("Method not found");
    return;
  }
  var closingBrace = content.indexOf('}', searchIndex) + 1;
  var finalBrace = content.indexOf('}', closingBrace) + 1;

  var before = content.substring(0, finalBrace);
  var after = content.substring(finalBrace);

  var newMethod = '''

  Stream<List<PaymentHistory>> watchAllPaymentsByDate(String dateStr) {
    // Parse dateStr (yyyy-mm-dd)
    final parts = dateStr.split('-');
    if (parts.length != 3) return Stream.value([]);
    
    final year = int.tryParse(parts[0]) ?? 2024;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;
    
    final startOfDay = DateTime(year, month, day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collectionGroup('payments')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentHistory.fromMap(doc.id, doc.data()))
          .toList();
    });
  }
''';

  file.writeAsStringSync(before + newMethod + after);
  print('Credit repo patched with watchAllPaymentsByDate');
}
