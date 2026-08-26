import os
import re

def fix_credit_repo_transactions():
    path = 'lib/features/credit/data/credit_repository.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    old_logic = """    final isCredit = paymentMethod == null || paymentMethod == PaymentMethod.credit;
    
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
    }

    final transRef = customerRef.collection('transactions').doc();
    final transaction = CreditTransaction(
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
    batch.set(transRef, transaction.toMap());"""
    
    new_logic = """    final isCredit = paymentMethod == null || paymentMethod == PaymentMethod.credit;
    
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
    }

    final transRef = customerRef.collection('transactions').doc();
    final transaction = CreditTransaction(
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
      subtitle: subtitle != null ? subtitle + (isCredit ? '' : ' - Paid via ${paymentMethod!.displayName}') : (isCredit ? null : 'Paid via ${paymentMethod!.displayName}'),
    );
    batch.set(transRef, transaction.toMap());"""
    
    content = content.replace(old_logic, new_logic)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_credit_repo_transactions()
