import re

with open('lib/features/credit/data/credit_repository.dart', 'r') as f:
    code = f.read()

merge_target = '''  Future<void> mergeCustomers(String sourceId, String targetId) async {
    if (AppConfig.guardWrite('CreditRepository.mergeCustomers')) return;
    await _firestore.runTransaction((tx) async {
      final sourceRef = _creditsRef.doc(sourceId);
      final targetRef = _creditsRef.doc(targetId);

      final sourceDoc = await tx.get(sourceRef);
      final targetDoc = await tx.get(targetRef);

      if (!sourceDoc.exists || !targetDoc.exists) {
        throw Exception("One or both customers not found for merge.");
      }

      final sourceData = sourceDoc.data() as Map<String, dynamic>;
      final targetData = targetDoc.data() as Map<String, dynamic>;

      final sourceOutstanding = (sourceData['outstandingAmount'] as num?)?.toDouble() ?? 0.0;
      final targetOutstanding = (targetData['outstandingAmount'] as num?)?.toDouble() ?? 0.0;
      
      final sourcePendingCount = (sourceData['totalPendingTransactions'] as num?)?.toInt() ?? 0;
      final targetPendingCount = (targetData['totalPendingTransactions'] as num?)?.toInt() ?? 0;

      // Update target customer
      tx.update(targetRef, {
        'outstandingAmount': targetOutstanding + sourceOutstanding,
        'totalPendingTransactions': targetPendingCount + sourcePendingCount,
      });

      // Move transactions
      final sourceTrans = await sourceRef.collection('transactions').get();
      for (var doc in sourceTrans.docs) {
        final newTransRef = targetRef.collection('transactions').doc(doc.id);
        final data = doc.data();
        data['customerId'] = targetId; // Update customer reference
        tx.set(newTransRef, data);
        tx.delete(doc.reference);
      }

      // Move payment history
      final sourcePayments = await sourceRef.collection('payments').get();
      for (var doc in sourcePayments.docs) {
        final newPayRef = targetRef.collection('payments').doc(doc.id);
        final data = doc.data();
        data['customerId'] = targetId;
        tx.set(newPayRef, data);
        tx.delete(doc.reference);
      }

      // Delete source customer
      tx.delete(sourceRef);
    });
    
    await recalculateCustomerAccount(targetId);
  }'''

merge_replacement = '''  Future<void> mergeCustomers(String sourceId, String targetId) async {
    if (AppConfig.guardWrite('CreditRepository.mergeCustomers')) return;
    
    // Batch is much safer for moving large collections than runTransaction
    final batch = _firestore.batch();
    
    final sourceRef = _creditsRef.doc(sourceId);
    final targetRef = _creditsRef.doc(targetId);

    final sourceDoc = await sourceRef.get();
    final targetDoc = await targetRef.get();

    if (!sourceDoc.exists || !targetDoc.exists) {
      throw Exception("One or both customers not found for merge.");
    }

    final sourceData = sourceDoc.data() as Map<String, dynamic>;
    final targetData = targetDoc.data() as Map<String, dynamic>;

    final sourceOutstanding = (sourceData['outstandingAmount'] as num?)?.toDouble() ?? 0.0;
    final targetOutstanding = (targetData['outstandingAmount'] as num?)?.toDouble() ?? 0.0;
    
    final sourcePendingCount = (sourceData['totalPendingTransactions'] as num?)?.toInt() ?? 0;
    final targetPendingCount = (targetData['totalPendingTransactions'] as num?)?.toInt() ?? 0;

    // Update target customer
    batch.update(targetRef, {
      'outstandingAmount': targetOutstanding + sourceOutstanding,
      'totalPendingTransactions': targetPendingCount + sourcePendingCount,
    });

    // Move transactions
    final sourceTrans = await sourceRef.collection('transactions').get();
    for (var doc in sourceTrans.docs) {
      final newTransRef = targetRef.collection('transactions').doc(doc.id);
      final data = doc.data();
      data['customerId'] = targetId;
      batch.set(newTransRef, data);
      batch.delete(doc.reference);
    }

    // Move payment history
    final sourcePayments = await sourceRef.collection('payments').get();
    for (var doc in sourcePayments.docs) {
      final newPayRef = targetRef.collection('payments').doc(doc.id);
      final data = doc.data();
      data['customerId'] = targetId;
      batch.set(newPayRef, data);
      batch.delete(doc.reference);
    }

    // Delete source customer
    batch.delete(sourceRef);
    
    await batch.commit();
    
    await recalculateCustomerAccount(targetId);
  }'''
  
code = code.replace(merge_target, merge_replacement)

with open('lib/features/credit/data/credit_repository.dart', 'w') as f:
    f.write(code)

print("Credit repository merge patched")
