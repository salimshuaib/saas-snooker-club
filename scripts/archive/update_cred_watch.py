import re

def add_all_transactions_method():
    path = 'lib/features/credit/data/credit_repository.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find watchPendingTransactions
    old_watch = """  Stream<List<CreditTransaction>> watchPendingTransactions(String customerId) {
    return _transactionsRef(customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CreditTransaction.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .where((tx) => tx.status != CreditTransactionStatus.paid)
            .toList());
  }"""
  
    new_watch = """  Stream<List<CreditTransaction>> watchPendingTransactions(String customerId) {
    return _transactionsRef(customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CreditTransaction.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .where((tx) => tx.status != CreditTransactionStatus.paid)
            .toList());
  }

  Stream<List<CreditTransaction>> watchAllTransactions(String customerId) {
    return _transactionsRef(customerId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CreditTransaction.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }"""
    content = content.replace(old_watch, new_watch)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    add_all_transactions_method()
