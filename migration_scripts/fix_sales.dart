import 'dart:io';

void main() {
  var file = File('lib/features/quick_sales/data/quick_sales_repository.dart');
  var content = file.readAsStringSync();

  var startIndex = content.indexOf('Future<void> updateQuickSalePaymentMethod');
  if (startIndex == -1) {
    print('Start not found');
    return;
  }
  
  var before = content.substring(0, startIndex);

  var replacement = '''Future<void> updateQuickSalePaymentMethod({
    required QuickSale sale,
    required PaymentMethod newPaymentMethod,
    String? newCustomerName,
    required String employeeName,
  }) async {
    if (AppConfig.guardWrite('QuickSalesRepository.updateQuickSalePaymentMethod')) return;
    final creditRepo = CreditRepository(_firestore);
    final oldMethod = sale.paymentMethod;
    
    if (oldMethod == newPaymentMethod && sale.customerName == newCustomerName) return;

    final audit = AuditLog(
      id: '\_pay',
      editedBy: employeeName,
      timestamp: DateTime.now(),
      field: 'Payment Method',
      previousValue: oldMethod.displayName,
      newValue: newPaymentMethod.displayName,
    );
    
    final batch = _firestore.batch();
    final finalCustomerName = newCustomerName ?? sale.customerName ?? 'Guest';

    if (newPaymentMethod == PaymentMethod.credit && oldMethod != PaymentMethod.credit) {
      await creditRepo.appendCreditToBatch(
        batch: batch,
        customerName: finalCustomerName,
        amount: sale.totalAmount,
        type: CreditTransactionType.quickSale,
        referenceId: sale.id,
        title: 'Quick Sale Order',
      );
    } else if (oldMethod == PaymentMethod.credit && newPaymentMethod != PaymentMethod.credit) {
      await creditRepo.removeCreditFromBatch(
        batch: batch,
        referenceId: sale.id, 
        customerName: sale.customerName ?? 'Unknown'
      );
    }

    final updatedAuditLogs = [...sale.auditLogs, audit];
    
    final updateMap = <String, dynamic>{
      'paymentMethod': newPaymentMethod.name,
      'customerName': newPaymentMethod == PaymentMethod.credit ? newCustomerName : sale.customerName,
      'auditLogs': updatedAuditLogs.map((a) => a.toMap()).toList(),
    };
    
    if (newPaymentMethod == PaymentMethod.cash || newPaymentMethod == PaymentMethod.upi) {
      updateMap['paymentStatus'] = 'Paid';
      updateMap['paidAmount'] = sale.totalAmount;
      updateMap['remainingAmount'] = 0.0;
    } else if (newPaymentMethod == PaymentMethod.credit) {
      updateMap['paymentStatus'] = 'Outstanding';
      updateMap['paidAmount'] = 0.0;
      updateMap['remainingAmount'] = sale.totalAmount;
    }

    batch.update(_salesRef.doc(sale.id), updateMap);
    await batch.commit();
  }
}
''';

  file.writeAsStringSync(before + replacement);
  print('QuickSales repo patched correctly');
}
