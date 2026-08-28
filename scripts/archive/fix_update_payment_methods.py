import os
import re

def fix_update_payment_methods():
    path = 'lib/features/games/data/games_repository.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Block 1: Split payments
    old_block_1 = """          if (newMethod == PaymentMethod.credit) {
            await creditRepo.appendCreditToBatch(
              batch: batch,
              customerName: player,
              amount: amount,
              type: CreditTransactionType.game,
              referenceId: session.id,
              title: 'Game on Table ${session.tableName}',
              subtitle: 'T.P. Match Split Liability (Rs. $amount)',
            );
          } else if (oldMethod == PaymentMethod.credit) {"""
          
    new_block_1 = """          // Unconditionally append since appendCreditToBatch now handles all payment methods
          await creditRepo.appendCreditToBatch(
            batch: batch,
            customerName: player,
            customerId: session.playerIdentities?[player],
            amount: amount,
            type: CreditTransactionType.game,
            referenceId: session.id,
            title: 'Game on Table ${session.tableName}',
            subtitle: 'Split Liability (₹${amount.toStringAsFixed(2)})',
            paymentMethod: newMethod,
          );
          if (oldMethod == PaymentMethod.credit && newMethod != PaymentMethod.credit) {"""
          
    content = content.replace(old_block_1, new_block_1)
    
    # Block 2: Single payments
    old_block_2 = """        if (newPaymentMethod == PaymentMethod.credit) {
          await creditRepo.appendCreditToBatch(
            batch: batch,
            customerName: newPaidBy ?? 'Unknown',
            amount: session.grandTotal ?? 0.0,
            type: CreditTransactionType.game,
            referenceId: session.id,
            title: 'Game on Table ${session.tableName}',
          );
        } else if (oldMethod == PaymentMethod.credit) {"""
        
    new_block_2 = """        await creditRepo.appendCreditToBatch(
          batch: batch,
          customerName: newPaidBy ?? 'Unknown',
          customerId: newPaidBy != null ? session.playerIdentities?[newPaidBy] : null,
          amount: session.grandTotal ?? 0.0,
          type: CreditTransactionType.game,
          referenceId: session.id,
          title: 'Game on Table ${session.tableName}',
          paymentMethod: newPaymentMethod,
        );
        if (oldMethod == PaymentMethod.credit && newPaymentMethod != PaymentMethod.credit) {"""
        
    content = content.replace(old_block_2, new_block_2)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_update_payment_methods()
