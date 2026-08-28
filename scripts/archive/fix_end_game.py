import os
import re

def fix_end_game():
    path = 'lib/features/games/data/games_repository.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find the block where it records playerPaymentMethods and paidBy
    old_credit_block = """    if (session.playerPaymentMethods != null &&
        session.playerPaymentMethods!.values.contains(PaymentMethod.credit)) {
      final creditRepo = CreditRepository(_db);
      for (final entry in session.playerPaymentMethods!.entries) {
        if (entry.value == PaymentMethod.credit) {
          final customerName = entry.key;
          final amount = session.playerLiabilities?[customerName] ?? 0.0;
          if (amount > 0) {
            await creditRepo.appendCreditToBatch(
              batch: batch,
              customerName: customerName,
              amount: amount,
              type: CreditTransactionType.game,
              referenceId: session.id,
              title: 'Game on Table ${session.tableName}',
              subtitle:
                  'T.P. Match Split Liability (₹${amount.toStringAsFixed(2)})',
            );
          }
        }
      }
    } else if (session.paymentMethod == PaymentMethod.credit &&
        session.paidBy != null) {
      final creditRepo = CreditRepository(_db);
      await creditRepo.appendCreditToBatch(
        batch: batch,
        customerName: session.paidBy!,
        amount: session.grandTotal ?? 0.0,
        type: CreditTransactionType.game,
        referenceId: session.id,
        title: 'Game on Table ${session.tableName}',
        subtitle: 'Billed Amount: ₹${session.grandTotal?.toStringAsFixed(2)}',
      );
    }"""
    
    new_credit_block = """    final creditRepo = CreditRepository(_db);
    if (session.playerPaymentMethods != null) {
      for (final entry in session.playerPaymentMethods!.entries) {
        final customerName = entry.key;
        final amount = session.playerLiabilities?[customerName] ?? 0.0;
        final method = entry.value;
        if (amount > 0) {
          await creditRepo.appendCreditToBatch(
            batch: batch,
            customerName: customerName,
            customerId: session.playerIdentities?[customerName],
            amount: amount,
            type: CreditTransactionType.game,
            referenceId: session.id,
            title: 'Game on Table ${session.tableName}',
            subtitle: 'Split Liability (₹${amount.toStringAsFixed(2)})',
            paymentMethod: method,
          );
        }
      }
    } else if (session.paymentMethod != null && session.paidBy != null) {
      await creditRepo.appendCreditToBatch(
        batch: batch,
        customerName: session.paidBy!,
        customerId: session.playerIdentities?[session.paidBy!],
        amount: session.grandTotal ?? 0.0,
        type: CreditTransactionType.game,
        referenceId: session.id,
        title: 'Game on Table ${session.tableName}',
        subtitle: 'Billed Amount: ₹${session.grandTotal?.toStringAsFixed(2)}',
        paymentMethod: session.paymentMethod,
      );
    }"""
    
    content = content.replace(old_credit_block.replace("₹", "â‚¹"), new_credit_block.replace("₹", "â‚¹"))

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_end_game()
