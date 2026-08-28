import re

with open('lib/features/quick_sales/data/quick_sales_repository.dart', 'r') as f:
    code = f.read()

create_target = '''    await _firestore.runTransaction((transaction) async {
      // 1. Verify and deduct inventory items
      for (final item in sale.items) {
        final productRef = _firestore.collection(FirebaseConstants.inventoryCollection).doc(item.productId);
        final productDoc = await transaction.get(productRef);'''

create_replacement = '''    if (sale.paymentMethod == PaymentMethod.credit && (sale.customerName == null || sale.customerName!.isEmpty)) {
      throw Exception('Customer Name is required for Credit payments.');
    }

    await _firestore.runTransaction((transaction) async {
      // 1. Verify and deduct inventory items
      for (final item in sale.items) {
        final productRef = _firestore.collection(FirebaseConstants.inventoryCollection).doc(item.productId);
        final productDoc = await transaction.get(productRef);'''

code = code.replace(create_target, create_replacement)

# Cash/UPI state for createQuickSale
create_status_target = '''      // 2. Create the quick sale record
      final saleRef = _salesRef.doc();
      final saleData = sale.copyWith(id: saleRef.id).toMap();
      transaction.set(saleRef, saleData);'''

create_status_replacement = '''      // 2. Create the quick sale record
      final saleRef = _salesRef.doc();
      final saleData = sale.copyWith(id: saleRef.id).toMap();
      
      if (sale.paymentMethod == PaymentMethod.cash || sale.paymentMethod == PaymentMethod.upi) {
        saleData['paymentStatus'] = 'Paid';
        saleData['paidAmount'] = sale.totalAmount;
        saleData['remainingAmount'] = 0.0;
      }
      
      transaction.set(saleRef, saleData);'''
      
code = code.replace(create_status_target, create_status_replacement)

# updateQuickSalePaymentMethod
update_target = '''  Future<void> updateQuickSalePaymentMethod({
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

    // Transition TO Credit
    if (newPaymentMethod == PaymentMethod.credit) {
      await creditRepo.addCreditRecord(
        customerName: newCustomerName ?? 'Unknown',
        amount: sale.totalAmount,
        type: CreditTransactionType.quickSale,
        referenceId: sale.id,
        title: 'Quick Sale Order',
      );
    }
    // Transition FROM Credit
    else if (oldMethod == PaymentMethod.credit) {
      await creditRepo.removeCreditRecord(referenceId: sale.id, customerName: sale.customerName);
    }

    final updatedAuditLogs = [...sale.auditLogs, audit];
    await _salesRef.doc(sale.id).update({
      'paymentMethod': newPaymentMethod.name,
      'customerName': newPaymentMethod == PaymentMethod.credit ? newCustomerName : null,
      'auditLogs': updatedAuditLogs.map((a) => a.toMap()).toList(),
    });
  }'''

update_replacement = '''  Future<void> updateQuickSalePaymentMethod({
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

    // Transition TO Credit
    if (newPaymentMethod == PaymentMethod.credit) {
      await creditRepo.appendCreditToBatch(
        batch: batch,
        customerName: newCustomerName ?? 'Unknown',
        amount: sale.totalAmount,
        type: CreditTransactionType.quickSale,
        referenceId: sale.id,
        title: 'Quick Sale Order',
      );
    }
    // Transition FROM Credit
    else if (oldMethod == PaymentMethod.credit) {
      await creditRepo.removeCreditFromBatch(
        batch: batch,
        referenceId: sale.id, 
        customerName: sale.customerName ?? 'Unknown'
      );
    }

    final updatedAuditLogs = [...sale.auditLogs, audit];
    
    final updateMap = <String, dynamic>{
      'paymentMethod': newPaymentMethod.name,
      'customerName': newPaymentMethod == PaymentMethod.credit ? newCustomerName : null,
      'auditLogs': updatedAuditLogs.map((a) => a.toMap()).toList(),
    };
    
    if (newPaymentMethod == PaymentMethod.cash || newPaymentMethod == PaymentMethod.upi) {
      updateMap['paymentStatus'] = 'Paid';
      updateMap['paidAmount'] = sale.totalAmount;
      updateMap['remainingAmount'] = 0.0;
    }

    batch.update(_salesRef.doc(sale.id), updateMap);
    await batch.commit();
  }'''

code = code.replace(update_target, update_replacement)

with open('lib/features/quick_sales/data/quick_sales_repository.dart', 'w') as f:
    f.write(code)

print("Quick sales repository patched successfully")
