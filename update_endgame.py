import re

def update_end_game():
    path = 'lib/features/games/data/games_repository.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # The block starting at `if (session.playerPaymentMethods != null` up to the end of that block.
    # We want to replace it.
    old_block = """    if (session.playerPaymentMethods != null &&
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
                  'T.P. Match Split Liability (â‚¹${amount.toStringAsFixed(2)})',
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
      );
    }"""
    
    new_block = """    // Record ALL payments (Cash, UPI, Credit) into Player Profiles
    final creditRepo = CreditRepository(_db);
    
    if (session.playerPaymentMethods != null && session.playerPaymentMethods!.isNotEmpty) {
      // Split payments
      for (final entry in session.playerPaymentMethods!.entries) {
        final customerName = entry.key;
        final pMethod = entry.value;
        final amount = session.playerLiabilities?[customerName] ?? 0.0;
        if (amount > 0) {
          await creditRepo.appendCreditToBatch(
            batch: batch,
            customerName: customerName,
            amount: amount,
            type: CreditTransactionType.game,
            referenceId: session.id,
            title: 'Game on Table ${session.tableName}',
            subtitle: 'Split Payment (â‚¹${amount.toStringAsFixed(2)})',
            paymentMethod: pMethod,
          );
        }
      }
    } else if (session.paidBy != null && session.paidBy!.isNotEmpty && session.paymentMethod != null) {
      // Single payer pays the full bill
      await creditRepo.appendCreditToBatch(
        batch: batch,
        customerName: session.paidBy!,
        amount: session.grandTotal ?? 0.0,
        type: CreditTransactionType.game,
        referenceId: session.id,
        title: 'Game on Table ${session.tableName}',
        paymentMethod: session.paymentMethod,
      );
    }"""
    content = content.replace(old_block, new_block)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    update_end_game()
