import os
import re

def fix_credit_repo():
    path = 'lib/features/credit/data/credit_repository.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    old_sig = """  Future<void> appendCreditToBatch({
    required WriteBatch batch,
    required String customerName,
    required double amount,
    required CreditTransactionType type,
    required String referenceId,
    required String title,
    String? subtitle,
    bool isTransfer = false,
    PaymentMethod? paymentMethod,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.appendCreditToBatch')) return;
    
    // We must find the customer first. Since this is a batch, we can await reads before committing.
    final existingCustomer = await getCustomerByName(customerName);"""
    
    new_sig = """  Future<void> appendCreditToBatch({
    required WriteBatch batch,
    required String customerName,
    String? customerId,
    required double amount,
    required CreditTransactionType type,
    required String referenceId,
    required String title,
    String? subtitle,
    bool isTransfer = false,
    PaymentMethod? paymentMethod,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.appendCreditToBatch')) return;
    
    PlayerProfile? existingCustomer;
    if (customerId != null) {
      final doc = await _creditsRef.doc(customerId).get();
      if (doc.exists) {
        existingCustomer = PlayerProfile.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
    }
    
    if (existingCustomer == null) {
      existingCustomer = await getCustomerByName(customerName);
    }"""
    
    content = content.replace(old_sig, new_sig)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_credit_repo()
