import re

def override_employee_name():
    path = 'lib/features/credit/data/credit_repository.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Update processPayment
    old_process = """  Future<void> processPayment({
    required PlayerProfile customer,
    required double paymentAmount,
    required PaymentMethod paymentMethod,
    required String employeeName,
    required bool isFullPayment,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.processPayment')) return;
    await _firestore.runTransaction((tx) async {"""
    
    new_process = """  Future<void> processPayment({
    required PlayerProfile customer,
    required double paymentAmount,
    required PaymentMethod paymentMethod,
    required String employeeName,
    required bool isFullPayment,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.processPayment')) return;
    employeeName = currentStaff?.name ?? employeeName;
    await _firestore.runTransaction((tx) async {"""
    content = content.replace(old_process, new_process)
    
    # 2. Update renameCustomerAndPropagate
    old_rename = """  Future<void> renameCustomerAndPropagate({
    required String customerId,
    required String oldName,
    required String newName,
    required String employeeName,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.renameCustomerAndPropagate')) return;"""
    
    new_rename = """  Future<void> renameCustomerAndPropagate({
    required String customerId,
    required String oldName,
    required String newName,
    required String employeeName,
  }) async {
    if (AppConfig.guardWrite('CreditRepository.renameCustomerAndPropagate')) return;
    employeeName = currentStaff?.name ?? employeeName;"""
    content = content.replace(old_rename, new_rename)
    
    # 3. Update removeCreditRecord
    old_remove = """  Future<void> removeCreditRecord({required String referenceId, String? customerName}) async {
    if (AppConfig.guardWrite('CreditRepository.removeCreditRecord')) return;"""
    
    new_remove = """  Future<void> removeCreditRecord({required String referenceId, String? customerName}) async {
    if (AppConfig.guardWrite('CreditRepository.removeCreditRecord')) return;"""
    # Wait, removeCreditRecord doesn't take employeeName, it doesn't create Audit logs. 

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    override_employee_name()
