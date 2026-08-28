import re

def modify_qs_repo(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'Future<void> createQuickSale' in content and 'createdByUserId: currentStaff?.id,' not in content:
        create_idx = content.find('Future<void> createQuickSale')
        if create_idx != -1:
            save_idx = content.find('await docRef.set(sale.toMap());', create_idx)
            if save_idx != -1:
                replacement = """final updatedSale = sale.copyWith(
      createdByUserId: currentStaff?.id,
      createdByName: currentStaff?.name,
      updatedByUserId: currentStaff?.id,
      updatedByName: currentStaff?.name,
    );
    await docRef.set(updatedSale.toMap());"""
                content = content.replace('await docRef.set(sale.toMap());', replacement, 1)

    if 'Future<void> updateQuickSale' in content and 'updatedByUserId: currentStaff?.id,' not in content:
        update_idx = content.find('Future<void> updateQuickSale')
        if update_idx != -1:
            save_idx = content.find('await _salesRef.doc(sale.id).update(sale.toMap());', update_idx)
            if save_idx != -1:
                replacement = """final updatedSale = sale.copyWith(
      updatedByUserId: currentStaff?.id,
      updatedByName: currentStaff?.name,
    );
    await _salesRef.doc(updatedSale.id).update(updatedSale.toMap());"""
                content = content.replace('await _salesRef.doc(sale.id).update(sale.toMap());', replacement, 1)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    modify_qs_repo('lib/features/quick_sales/data/quick_sales_repository.dart')
    print("Done")
