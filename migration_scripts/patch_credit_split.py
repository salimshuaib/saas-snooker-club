import re

with open('lib/features/credit/data/credit_repository.dart', 'r') as f:
    code = f.read()

target_1 = '''    // Duplicate Credit Protection (Phase 3)
    if (!isTransfer) {
      final existingGlobal = await _firestore.collectionGroup('transactions')
          .where('referenceId', isEqualTo: referenceId)
          .limit(1)
          .get();
      if (existingGlobal.docs.isNotEmpty) {
        throw Exception('A credit transaction for this source already exists.');
      }
    }

    // We must find the customer first. Since this is a batch, we can await reads before committing.
    final existingCustomer = await getCustomerByName(customerName);'''

replacement_1 = '''    // We must find the customer first. Since this is a batch, we can await reads before committing.
    final existingCustomer = await getCustomerByName(customerName);

    // Duplicate Credit Protection (Phase 3)
    if (!isTransfer && existingCustomer != null) {
      final existingTx = await _transactionsRef(existingCustomer.id)
          .where('referenceId', isEqualTo: referenceId)
          .limit(1)
          .get();
      if (existingTx.docs.isNotEmpty) {
        throw Exception('A credit transaction for this source already exists for this customer.');
      }
    }'''
code = code.replace(target_1, replacement_1)

target_2 = '''    // Duplicate Credit Protection (Phase 3)
    final existingGlobal = await _firestore.collectionGroup('transactions')
        .where('referenceId', isEqualTo: referenceId)
        .limit(1)
        .get();
    if (existingGlobal.docs.isNotEmpty) {
      throw Exception('A credit transaction for this source already exists.');
    }

    final existingCustomer = await getCustomerByName(customerName);'''

replacement_2 = '''    final existingCustomer = await getCustomerByName(customerName);

    // Duplicate Credit Protection (Phase 3)
    if (existingCustomer != null) {
      final existingTx = await _transactionsRef(existingCustomer.id)
          .where('referenceId', isEqualTo: referenceId)
          .limit(1)
          .get();
      if (existingTx.docs.isNotEmpty) {
        throw Exception('A credit transaction for this source already exists for this customer.');
      }
    }'''
code = code.replace(target_2, replacement_2)

with open('lib/features/credit/data/credit_repository.dart', 'w') as f:
    f.write(code)

print("Credit repository duplicate check fixed for split bills")
