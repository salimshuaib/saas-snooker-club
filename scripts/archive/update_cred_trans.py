import re

def update_append_trans():
    path = 'lib/features/credit/data/credit_repository.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    old_func = """  Future<void> appendCreditToTransaction({
    required Transaction transaction,
    required String customerName,
    required double amount,
    required CreditTransactionType type,
    required String referenceId,
    required String title,
    String? subtitle,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.appendCreditToTransaction')) return;
    final query = await _creditsRef.where('name', isEqualTo: customerName).limit(1).get();
    final existingCustomerDoc = query.docs.isEmpty ? null : query.docs.first;

    final customerRef = existingCustomerDoc != null 
        ? _creditsRef.doc(existingCustomerDoc.id) 
        : _creditsRef.doc();

    if (existingCustomerDoc != null) {
      transaction.update(customerRef, {
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
      transaction.set(customerRef, newCustomer.toMap());
    }

    final transRef = customerRef.collection('transactions').doc();
    final creditTrans = CreditTransaction(
      id: transRef.id,
      customerId: customerRef.id,
      type: type,
      referenceId: referenceId,
      amount: amount,
      paidAmount: 0.0,
      remainingAmount: amount,
      status: CreditTransactionStatus.pending,
      date: DateTime.now(),
      title: title,
      subtitle: subtitle,
    );
    transaction.set(transRef, creditTrans.toMap());
  }"""
  
    new_func = """  Future<void> appendCreditToTransaction({
    required Transaction transaction,
    required String customerName,
    required double amount,
    required CreditTransactionType type,
    required String referenceId,
    required String title,
    String? subtitle,
    PaymentMethod? paymentMethod,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.appendCreditToTransaction')) return;
    final query = await _creditsRef.where('name', isEqualTo: customerName).limit(1).get();
    final existingCustomerDoc = query.docs.isEmpty ? null : query.docs.first;

    final customerRef = existingCustomerDoc != null 
        ? _creditsRef.doc(existingCustomerDoc.id) 
        : _creditsRef.doc();

    final isCredit = paymentMethod == null || paymentMethod == PaymentMethod.credit;

    if (existingCustomerDoc != null) {
      transaction.update(customerRef, {
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
      transaction.set(customerRef, newCustomer.toMap());
    }

    final transRef = customerRef.collection('transactions').doc();
    final creditTrans = CreditTransaction(
      id: transRef.id,
      customerId: customerRef.id,
      type: type,
      referenceId: referenceId,
      amount: amount,
      paidAmount: isCredit ? 0.0 : amount,
      remainingAmount: isCredit ? amount : 0.0,
      status: isCredit ? CreditTransactionStatus.pending : CreditTransactionStatus.paid,
      date: DateTime.now(),
      title: title,
      subtitle: subtitle,
      paymentMethod: paymentMethod,
    );
    transaction.set(transRef, creditTrans.toMap());
  }"""
  
    content = content.replace(old_func, new_func)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    update_append_trans()
