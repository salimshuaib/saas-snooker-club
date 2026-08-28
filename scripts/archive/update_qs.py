import re

def update_quicksales():
    path = 'lib/features/quick_sales/data/quick_sales_repository.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    old_block = """      // 4. Handle Credit
      if (sale.paymentMethod == PaymentMethod.credit && sale.customerName != null && sale.customerName!.isNotEmpty) {
        final creditRepo = CreditRepository(_firestore);
        await creditRepo.appendCreditToTransaction(
          transaction: transaction,
          customerName: sale.customerName!,
          amount: sale.totalAmount,
          type: CreditTransactionType.quickSale,
          referenceId: saleRef.id, // Guarantee exact Document ID linkage
          title: 'Quick Sale Order',
          subtitle: 'Items: ${sale.items.length}',
        );
      }"""
  
    new_block = """      // 4. Handle Transaction for Player Profile
      if (sale.customerName != null && sale.customerName!.isNotEmpty) {
        final creditRepo = CreditRepository(_firestore);
        await creditRepo.appendCreditToTransaction(
          transaction: transaction,
          customerName: sale.customerName!,
          amount: sale.totalAmount,
          type: CreditTransactionType.quickSale,
          referenceId: saleRef.id, // Guarantee exact Document ID linkage
          title: 'Quick Sale Order',
          subtitle: 'Items: ${sale.items.length}',
          paymentMethod: sale.paymentMethod,
        );
      }"""
    content = content.replace(old_block, new_block)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    update_quicksales()
