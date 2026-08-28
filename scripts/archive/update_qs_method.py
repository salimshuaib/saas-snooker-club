import re

def update_qs_method():
    path = 'lib/features/quick_sales/data/quick_sales_repository.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    old_block = """    if (newPaymentMethod == PaymentMethod.credit && oldMethod != PaymentMethod.credit) {
      await creditRepo.appendCreditToBatch(
        batch: batch,
        customerName: finalCustomerName,
        amount: sale.totalAmount,
        type: CreditTransactionType.quickSale,
        referenceId: sale.id,
        title: 'Quick Sale Order',
      );
    } else if (oldMethod == PaymentMethod.credit && newPaymentMethod != PaymentMethod.credit) {
      await creditRepo.removeCreditFromBatch(
        batch: batch,
        referenceId: sale.id, 
        customerName: sale.customerName ?? 'Unknown'
      );
    }"""
  
    new_block = """    if (sale.customerName != null && sale.customerName!.isNotEmpty) {
      await creditRepo.removeCreditFromBatch(
        batch: batch,
        referenceId: sale.id,
        customerName: sale.customerName!,
      );
    }
    
    if (finalCustomerName.isNotEmpty && finalCustomerName != 'Guest') {
      await creditRepo.appendCreditToBatch(
        batch: batch,
        customerName: finalCustomerName,
        amount: sale.totalAmount,
        type: CreditTransactionType.quickSale,
        referenceId: sale.id,
        title: 'Quick Sale Order',
        paymentMethod: newPaymentMethod,
      );
    }"""
    content = content.replace(old_block, new_block)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    update_qs_method()
