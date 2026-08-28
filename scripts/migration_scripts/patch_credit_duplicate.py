import re

with open('lib/features/credit/data/credit_repository.dart', 'r') as f:
    code = f.read()

# Fix appendCreditToBatch signature
target_1 = '''  Future<void> appendCreditToBatch({
    required WriteBatch batch,
    required String customerName,
    required double amount,
    required CreditTransactionType type,
    required String referenceId,
    required String title,
    String? subtitle,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.appendCreditToBatch')) return;
    
    // Duplicate Credit Protection (Phase 3)
    final existingGlobal = await _firestore.collectionGroup('transactions')
        .where('referenceId', isEqualTo: referenceId)
        .limit(1)
        .get();
    if (existingGlobal.docs.isNotEmpty) {
      throw Exception('A credit transaction for this source already exists.');
    }'''

replacement_1 = '''  Future<void> appendCreditToBatch({
    required WriteBatch batch,
    required String customerName,
    required double amount,
    required CreditTransactionType type,
    required String referenceId,
    required String title,
    String? subtitle,
    bool isTransfer = false,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.appendCreditToBatch')) return;
    
    // Duplicate Credit Protection (Phase 3)
    if (!isTransfer) {
      final existingGlobal = await _firestore.collectionGroup('transactions')
          .where('referenceId', isEqualTo: referenceId)
          .limit(1)
          .get();
      if (existingGlobal.docs.isNotEmpty) {
        throw Exception('A credit transaction for this source already exists.');
      }
    }'''
code = code.replace(target_1, replacement_1)

# Fix transferCreditTransaction
target_2 = '''    await appendCreditToBatch(
      batch: batch,
      customerName: newCustomerName,
      amount: amount,
      type: type,
      referenceId: referenceId,
      title: title,
      subtitle: subtitle,
    );'''

replacement_2 = '''    await appendCreditToBatch(
      batch: batch,
      customerName: newCustomerName,
      amount: amount,
      type: type,
      referenceId: referenceId,
      title: title,
      subtitle: subtitle,
      isTransfer: true,
    );'''
code = code.replace(target_2, replacement_2)

with open('lib/features/credit/data/credit_repository.dart', 'w') as f:
    f.write(code)

print("Credit repository duplicate protection patched")
