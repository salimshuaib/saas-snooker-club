import re

with open('lib/features/credit/data/credit_repository.dart', 'r') as f:
    code = f.read()

# 1. Add processPayment validation
process_payment_target = '''    await _firestore.runTransaction((transaction) async {
      final customerDoc = await transaction.get(customerRef);'''
process_payment_replacement = '''    await _firestore.runTransaction((transaction) async {
      if (paymentAmount <= 0) {
        throw Exception("Payment amount must be greater than zero.");
      }
      final customerDoc = await transaction.get(customerRef);'''
code = code.replace(process_payment_target, process_payment_replacement)

# 2. Fix recalculateCustomerAccount silent catchError
recalc_target_1 = '''        if (typeStr == CreditTransactionType.game.name) {
          uiUpdates.add(gamesCollection.doc(refId).update({
            'paymentStatus': displayStatus,
            'paidAmount': txPaid,
            'remainingAmount': txRemaining,
          }).catchError((_) {}));
        } else if (typeStr == CreditTransactionType.quickSale.name) {
          uiUpdates.add(salesCollection.doc(refId).update({
            'paymentStatus': displayStatus,
            'paidAmount': txPaid,
            'remainingAmount': txRemaining,
          }).catchError((_) {}));
        }'''
recalc_replacement_1 = '''        if (typeStr == CreditTransactionType.game.name) {
          batch.update(gamesCollection.doc(refId), {
            'paymentStatus': displayStatus,
            'paidAmount': txPaid,
            'remainingAmount': txRemaining,
          });
        } else if (typeStr == CreditTransactionType.quickSale.name) {
          batch.update(salesCollection.doc(refId), {
            'paymentStatus': displayStatus,
            'paidAmount': txPaid,
            'remainingAmount': txRemaining,
          });
        }'''
code = code.replace(recalc_target_1, recalc_replacement_1)

# And remove uiUpdates await
recalc_target_2 = '''    await batch.commit();
    await Future.wait(uiUpdates);'''
recalc_replacement_2 = '''    await batch.commit();'''
code = code.replace(recalc_target_2, recalc_replacement_2)

# 3. Fix cascadeDeleteGameCredits deletion protection
cascade_game_target = '''        if (statusStr == CreditTransactionStatus.paid.name) {
          throw Exception('Cannot delete this game because it has a paid credit transaction.');
        }'''
cascade_game_replacement = '''        if (statusStr == CreditTransactionStatus.paid.name || statusStr == CreditTransactionStatus.partiallyPaid.name) {
          throw Exception('Cannot delete this game because its credit transaction has already received a payment.');
        }'''
code = code.replace(cascade_game_target, cascade_game_replacement)

cascade_sale_target = '''        if (statusStr == CreditTransactionStatus.paid.name) {
          throw Exception('Cannot delete this quick sale because it has a paid credit transaction.');
        }'''
cascade_sale_replacement = '''        if (statusStr == CreditTransactionStatus.paid.name || statusStr == CreditTransactionStatus.partiallyPaid.name) {
          throw Exception('Cannot delete this quick sale because its credit transaction has already received a payment.');
        }'''
code = code.replace(cascade_sale_target, cascade_sale_replacement)

# 4. Add removeCreditFromBatch
remove_credit_target = '''  Future<void> removeCreditRecord({required String referenceId, String? customerName}) async {'''
remove_credit_replacement = '''  /// Appends credit removal logic to a batch
  Future<void> removeCreditFromBatch({
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
  }

  Future<void> removeCreditRecord({required String referenceId, String? customerName}) async {'''
code = code.replace(remove_credit_target, remove_credit_replacement)

# 5. Make transferCreditTransaction atomic
transfer_target = '''  Future<void> transferCreditTransaction({
    required String referenceId,
    required String oldCustomerName,
    required String newCustomerName,
    required double amount,
    required CreditTransactionType type,
    required String title,
    String? subtitle,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.transferCreditTransaction')) return;
    if (oldCustomerName.isEmpty || newCustomerName.isEmpty || oldCustomerName == newCustomerName) return;

    await removeCreditRecord(referenceId: referenceId, customerName: oldCustomerName);
    await addCreditRecord(
      customerName: newCustomerName,
      amount: amount,
      type: type,
      referenceId: referenceId,
      title: title,
      subtitle: subtitle,
    );
  }'''
transfer_replacement = '''  Future<void> transferCreditTransaction({
    required String referenceId,
    required String oldCustomerName,
    required String newCustomerName,
    required double amount,
    required CreditTransactionType type,
    required String title,
    String? subtitle,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.transferCreditTransaction')) return;
    if (oldCustomerName.isEmpty || newCustomerName.isEmpty || oldCustomerName == newCustomerName) return;

    final batch = _firestore.batch();
    
    await removeCreditFromBatch(
      batch: batch,
      referenceId: referenceId,
      customerName: oldCustomerName,
    );
    
    await appendCreditToBatch(
      batch: batch,
      customerName: newCustomerName,
      amount: amount,
      type: type,
      referenceId: referenceId,
      title: title,
      subtitle: subtitle,
    );
    
    await batch.commit();
  }'''
code = code.replace(transfer_target, transfer_replacement)

with open('lib/features/credit/data/credit_repository.dart', 'w') as f:
    f.write(code)

print("Credit repository patched successfully")
