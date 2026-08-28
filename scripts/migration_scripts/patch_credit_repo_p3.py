import re

with open('lib/features/credit/data/credit_repository.dart', 'r') as f:
    code = f.read()

# Fix 1: Add duplicate check in appendCreditToBatch
append_target = '''  Future<void> appendCreditToBatch({
    required WriteBatch batch,
    required String customerName,
    required double amount,
    required CreditTransactionType type,
    required String referenceId,
    required String title,
    String? subtitle,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.appendCreditToBatch')) return;
    // We must find the customer first. Since this is a batch, we can await reads before committing.
    final existingCustomer = await getCustomerByName(customerName);'''

append_replacement = '''  Future<void> appendCreditToBatch({
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
    }

    // We must find the customer first. Since this is a batch, we can await reads before committing.
    final existingCustomer = await getCustomerByName(customerName);'''
code = code.replace(append_target, append_replacement)


# Fix 2: Add duplicate check in addCreditRecord
add_target = '''  Future<void> addCreditRecord({
    required String customerName,
    required double amount,
    required CreditTransactionType type,
    required String referenceId,
    required String title,
    String? subtitle,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.addCreditRecord')) return;
    if (customerName.isEmpty || amount <= 0) return;
    final existingCustomer = await getCustomerByName(customerName);'''

add_replacement = '''  Future<void> addCreditRecord({
    required String customerName,
    required double amount,
    required CreditTransactionType type,
    required String referenceId,
    required String title,
    String? subtitle,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.addCreditRecord')) return;
    if (customerName.isEmpty || amount <= 0) return;
    
    // Duplicate Credit Protection (Phase 3)
    final existingGlobal = await _firestore.collectionGroup('transactions')
        .where('referenceId', isEqualTo: referenceId)
        .limit(1)
        .get();
    if (existingGlobal.docs.isNotEmpty) {
      throw Exception('A credit transaction for this source already exists.');
    }

    final existingCustomer = await getCustomerByName(customerName);'''
code = code.replace(add_target, add_replacement)

# Fix 3: Fix processPayment validation (<= 0)
process_target = '''  Future<void> processPayment({
    required CreditCustomer customer,
    required double paymentAmount,
    required PaymentMethod paymentMethod,
    required String employeeName,
    required bool isFullPayment,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.processPayment')) return;
    await _firestore.runTransaction((tx) async {
      final customerRef = _creditsRef.doc(customer.id);
      final customerDoc = await tx.get(customerRef);'''

process_replacement = '''  Future<void> processPayment({
    required CreditCustomer customer,
    required double paymentAmount,
    required PaymentMethod paymentMethod,
    required String employeeName,
    required bool isFullPayment,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.processPayment')) return;
    await _firestore.runTransaction((tx) async {
      if (paymentAmount <= 0) {
        throw Exception("Payment amount must be greater than zero.");
      }
      final customerRef = _creditsRef.doc(customer.id);
      final customerDoc = await tx.get(customerRef);'''
code = code.replace(process_target, process_replacement)

with open('lib/features/credit/data/credit_repository.dart', 'w') as f:
    f.write(code)

print("Credit repository patched for Phase 3")
