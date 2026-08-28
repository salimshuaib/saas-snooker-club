import re

def fix_remove_credit():
    path = 'lib/features/credit/data/credit_repository.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    old_remove = """  Future<void> removeCreditFromBatch({
    required WriteBatch batch,
    required String referenceId,
    required String customerName,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.removeCreditFromBatch')) return;
    final customer = await getCustomerByName(customerName);
    if (customer == null) return;
    
    final transSnap = await _transactionsRef(customer.id).where('referenceId', isEqualTo: referenceId).get();
    for (final doc in transSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final statusStr = data['status'] as String? ?? '';
      if (statusStr == CreditTransactionStatus.paid.name || statusStr == CreditTransactionStatus.partiallyPaid.name) {
        throw Exception('Cannot convert or remove credit for this transaction as it has already received a payment.');
      }
      final originalAmount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      
      batch.delete(doc.reference);
      batch.update(_creditsRef.doc(customer.id), {
        'outstandingAmount': FieldValue.increment(-originalAmount),
        'totalPendingTransactions': FieldValue.increment(-1),
      });
    }
  }"""
  
    new_remove = """  Future<void> removeCreditFromBatch({
    required WriteBatch batch,
    required String referenceId,
    required String customerName,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.removeCreditFromBatch')) return;
    final customer = await getCustomerByName(customerName);
    if (customer == null) return;
    
    final transSnap = await _transactionsRef(customer.id).where('referenceId', isEqualTo: referenceId).get();
    for (final doc in transSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final isCredit = data['paymentMethod'] == null || data['paymentMethod'] == 'credit';
      
      if (isCredit) {
        final statusStr = data['status'] as String? ?? '';
        if (statusStr == CreditTransactionStatus.paid.name || statusStr == CreditTransactionStatus.partiallyPaid.name) {
          throw Exception('Cannot convert or remove credit for this transaction as it has already received a payment.');
        }
      }
      
      final originalAmount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      batch.delete(doc.reference);
      
      if (isCredit) {
        batch.update(_creditsRef.doc(customer.id), {
          'outstandingAmount': FieldValue.increment(-originalAmount),
          'totalPendingTransactions': FieldValue.increment(-1),
        });
      }
    }
  }"""
    content = content.replace(old_remove, new_remove)
    
    old_remove_record = """      final statusStr = data['status'] as String? ?? '';
      if (statusStr == CreditTransactionStatus.paid.name || statusStr == CreditTransactionStatus.partiallyPaid.name) {
        // Skip removing paid/partially paid credits
        continue;
      }
      
      final customerRef = doc.reference.parent.parent!;
      affectedCustomerIds.add(customerRef.id);
      
      final originalAmount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      batch.delete(doc.reference);
      
      batch.update(customerRef, {
        'outstandingAmount': FieldValue.increment(-originalAmount),
        'totalPendingTransactions': FieldValue.increment(-1),
      });"""
      
    new_remove_record = """      final isCredit = data['paymentMethod'] == null || data['paymentMethod'] == 'credit';
      
      if (isCredit) {
        final statusStr = data['status'] as String? ?? '';
        if (statusStr == CreditTransactionStatus.paid.name || statusStr == CreditTransactionStatus.partiallyPaid.name) {
          // Skip removing paid/partially paid credits
          continue;
        }
      }
      
      final customerRef = doc.reference.parent.parent!;
      affectedCustomerIds.add(customerRef.id);
      
      final originalAmount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      batch.delete(doc.reference);
      
      if (isCredit) {
        batch.update(customerRef, {
          'outstandingAmount': FieldValue.increment(-originalAmount),
          'totalPendingTransactions': FieldValue.increment(-1),
        });
      }"""
    content = content.replace(old_remove_record, new_remove_record)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_remove_credit()
