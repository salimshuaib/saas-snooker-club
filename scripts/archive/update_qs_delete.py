import re

def modify_delete_qs(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    delete_target = "transaction.delete(saleRef);"
    audit_injection = """transaction.delete(saleRef);
          
          // Audit Log for Deletion
          final auditRef = _firestore.collection('audit_logs').doc();
          transaction.set(auditRef, {
            'id': auditRef.id,
            'action': 'Quick Sale Deleted',
            'recordId': sale.id,
            'module': 'QuickSales',
            'userId': currentStaff?.id ?? 'Unknown',
            'userName': currentStaff?.name ?? 'Admin',
            'timestamp': FieldValue.serverTimestamp(),
          });"""

    if "Audit Log for Deletion" not in content:
        content = content.replace(delete_target, audit_injection)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    modify_delete_qs('lib/features/quick_sales/data/quick_sales_repository.dart')
    print("Done")
