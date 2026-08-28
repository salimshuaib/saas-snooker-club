import re

def inject_identity():
    path = 'lib/features/quick_sales/data/quick_sales_repository.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    enrich_sale = """  QuickSale _enrichWithStaff(QuickSale sale, bool isCreate) {
    final staff = currentStaff;
    if (staff == null) return sale;
    
    if (isCreate) {
      return sale.copyWith(
        createdByUserId: staff.id,
        createdByName: staff.name,
      );
    } else {
      return sale.copyWith(
        updatedByUserId: staff.id,
        updatedByName: staff.name,
      );
    }
  }"""
  
    if "_enrichWithStaff" not in content:
        content = content.replace("CollectionReference get _inventoryRef =>\n      _firestore.collection(FirebaseConstants.inventoryCollection);", "CollectionReference get _inventoryRef =>\n      _firestore.collection(FirebaseConstants.inventoryCollection);\n\n" + enrich_sale)

    old_create = """  Future<void> createQuickSale(QuickSale sale) async {
    if (AppConfig.guardWrite('QuickSalesRepository.createQuickSale')) return;
    await _firestore.runTransaction((transaction) async {"""
    
    new_create = """  Future<void> createQuickSale(QuickSale sale) async {
    if (AppConfig.guardWrite('QuickSalesRepository.createQuickSale')) return;
    final enrichedSale = _enrichWithStaff(sale, true);
    await _firestore.runTransaction((transaction) async {"""
    content = content.replace(old_create, new_create)
    
    # In runTransaction, it uses `sale`. Replace `sale` with `enrichedSale`.
    # Wait, the rest of the function uses `sale`. Let's just shadow the variable inside the function.
    new_create2 = """  Future<void> createQuickSale(QuickSale sale) async {
    if (AppConfig.guardWrite('QuickSalesRepository.createQuickSale')) return;
    sale = _enrichWithStaff(sale, true);
    await _firestore.runTransaction((transaction) async {"""
    # Re-replace
    content = content.replace(new_create, new_create2)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    inject_identity()
