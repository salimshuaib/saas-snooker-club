import re

def update_credit_repo():
    path = 'lib/features/credit/data/credit_repository.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Update appendCreditToBatch signature
    old_sig = """  Future<void> appendCreditToBatch({
    required WriteBatch batch,
    required String customerName,
    required double amount,
    required CreditTransactionType type,
    required String referenceId,
    required String title,
    String? subtitle,
    bool isTransfer = false,
  }) async {"""
  
    new_sig = """  Future<void> appendCreditToBatch({
    required WriteBatch batch,
    required String customerName,
    required double amount,
    required CreditTransactionType type,
    required String referenceId,
    required String title,
    String? subtitle,
    bool isTransfer = false,
    PaymentMethod? paymentMethod,
  }) async {"""
    content = content.replace(old_sig, new_sig)
    
    # Check if payment is actual credit or cash/UPI
    old_customer_update = """    if (existingCustomer != null) {
      batch.update(customerRef, {
        'outstandingAmount': FieldValue.increment(amount),
        'totalPendingTransactions': FieldValue.increment(1),
        'lastTransactionDate': Timestamp.now(),
      });
    } else {
      final newCustomer = PlayerProfile(
        id: customerRef.id,
        name: customerName,
        outstandingAmount: amount,
        totalPendingTransactions: 1,
        lastTransactionDate: DateTime.now(),
      );
      batch.set(customerRef, newCustomer.toMap());
    }"""
    
    new_customer_update = """    final isCredit = paymentMethod == null || paymentMethod == PaymentMethod.credit;
    
    if (existingCustomer != null) {
      batch.update(customerRef, {
        if (isCredit) 'outstandingAmount': FieldValue.increment(amount),
        if (isCredit) 'totalPendingTransactions': FieldValue.increment(1),
        'lastTransactionDate': Timestamp.now(),
      });
    } else {
      final newCustomer = PlayerProfile(
        id: customerRef.id,
        name: customerName,
        outstandingAmount: isCredit ? amount : 0.0,
        totalPendingTransactions: isCredit ? 1 : 0,
        lastTransactionDate: DateTime.now(),
      );
      batch.set(customerRef, newCustomer.toMap());
    }"""
    content = content.replace(old_customer_update, new_customer_update)
    
    # Update transaction creation
    old_transaction = """    final transaction = CreditTransaction(
      id: transRef.id,
      customerId: customerRef.id,
      type: type,
      referenceId: referenceId,
      amount: amount,
      remainingAmount: amount,
      date: DateTime.now(),
      title: title,
      subtitle: subtitle,
    );"""
    
    new_transaction = """    final transaction = CreditTransaction(
      id: transRef.id,
      customerId: customerRef.id,
      type: type,
      referenceId: referenceId,
      amount: amount,
      remainingAmount: isCredit ? amount : 0.0,
      paidAmount: isCredit ? 0.0 : amount,
      status: isCredit ? CreditTransactionStatus.pending : CreditTransactionStatus.paid,
      date: DateTime.now(),
      title: title,
      subtitle: subtitle,
      paymentMethod: paymentMethod,
    );"""
    content = content.replace(old_transaction, new_transaction)
    
    # Update the recursive call for transfers
    old_transfer = """    await appendCreditToBatch(
      batch: batch,
      customerName: newCustomerName,
      amount: amount,
      type: type,
      referenceId: referenceId,
      title: title,
      subtitle: subtitle,
      isTransfer: true,
    );"""
    
    new_transfer = """    await appendCreditToBatch(
      batch: batch,
      customerName: newCustomerName,
      amount: amount,
      type: type,
      referenceId: referenceId,
      title: title,
      subtitle: subtitle,
      isTransfer: true,
      paymentMethod: paymentMethod,
    );"""
    content = content.replace(old_transfer, new_transfer)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    update_credit_repo()
