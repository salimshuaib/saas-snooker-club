import sys

path = 'lib/features/games/presentation/screens/combined_settlement_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
import_stmt = "import 'package:snooker_club/core/utils/billing_utils.dart';"
if import_stmt not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_stmt)

# Update _totalSelectedAmount
old_total = '''  double get _totalSelectedAmount {
    return widget.initialBills
        .where((b) => _selectedBillIds.contains(b.id))
        .fold(0.0, (sum, b) => sum + (b.finalAmount ?? b.grandTotal ?? 0.0));
  }'''
new_total = '''  double get _totalSelectedAmount {
    final unrounded = widget.initialBills
        .where((b) => _selectedBillIds.contains(b.id))
        .fold(0.0, (sum, b) => sum + (b.finalAmount ?? b.grandTotal ?? 0.0));
    return BillingUtils.roundAmount(unrounded);
  }'''
content = content.replace(old_total, new_total)

# Update _confirmSettlement
old_confirm = '''      for (final bill in billsToSettle) {
        final amount = bill.finalAmount ?? bill.grandTotal ?? 0.0;'''
new_confirm = '''      final unroundedTotal = billsToSettle.fold(0.0, (sum, b) => sum + (b.finalAmount ?? b.grandTotal ?? 0.0));
      final roundedTotal = BillingUtils.roundAmount(unroundedTotal);
      final totalRounding = roundedTotal - unroundedTotal;

      for (int i = 0; i < billsToSettle.length; i++) {
        var bill = billsToSettle[i];
        var amount = bill.finalAmount ?? bill.grandTotal ?? 0.0;

        // Apply all rounding adjustment to the last bill so the sum of bills exactly matches the rounded total
        if (i == billsToSettle.length - 1) {
          amount += totalRounding;
          bill = bill.copyWith(
            finalAmount: amount,
            roundedAmount: amount,
          );
        }'''
content = content.replace(old_confirm, new_confirm)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched combined_settlement_screen.dart')
