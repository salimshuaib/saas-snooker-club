import sys

path = 'lib/features/games/presentation/screens/combined_settlement_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add dart:math import
if 'import \'dart:math\' as math;' not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'dart:math' as math;")

# 2. Add _playerPaymentSplits state
content = content.replace('bool _isProcessing = false;', '''bool _isProcessing = false;
  Map<PaymentMethod, double> _playerPaymentSplits = {};''')

# 3. Patch _confirmSettlement
old_confirm = '''      for (final bill in billsToSettle) {
        await repo.settlePendingBill(
          bill,
          paymentMethod: _paymentMethod,
          paidBy: widget.customerName,
          playerPaymentSplits: null, // No complex splits for combined billing yet
        );
      }'''

new_confirm = '''      Map<PaymentMethod, double> remainingPool = Map.from(_playerPaymentSplits);
      bool isSplit = remainingPool.keys.length > 1;

      for (final bill in billsToSettle) {
        final amount = bill.finalAmount ?? bill.grandTotal ?? 0.0;
        
        Map<String, Map<PaymentMethod, double>>? splitsForThisBill;
        PaymentMethod methodForThisBill = _paymentMethod;
        
        if (isSplit) {
          double amountLeftToAssign = amount;
          Map<PaymentMethod, double> currentBillSplits = {};
          
          for (final method in remainingPool.keys.toList()) {
             if (amountLeftToAssign <= 0.01) break;
             
             final poolAmount = remainingPool[method]!;
             if (poolAmount <= 0) continue;
             
             final take = math.min(amountLeftToAssign, poolAmount);
             currentBillSplits[method] = take;
             remainingPool[method] = poolAmount - take;
             amountLeftToAssign -= take;
          }
          
          splitsForThisBill = { widget.customerName: currentBillSplits };
        } else if (_playerPaymentSplits.isNotEmpty) {
           methodForThisBill = _playerPaymentSplits.keys.first;
        }

        await repo.settlePendingBill(
          bill,
          paymentMethod: methodForThisBill,
          paidBy: widget.customerName,
          playerPaymentSplits: splitsForThisBill,
        );
      }'''
content = content.replace(old_confirm, new_confirm)

# 4. Patch UI
old_ui = '''                      Text(
                        'Total to Pay',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '\u20b9${total.toStringAsFixed(0)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Gap(24),
                  SegmentedButton<PaymentMethod>(
                    segments: const [
                      ButtonSegment(
                        value: PaymentMethod.cash,
                        label: Text('Cash'),
                        icon: Icon(Icons.money),
                      ),
                      ButtonSegment(
                        value: PaymentMethod.upi,
                        label: Text('UPI / QR'),
                        icon: Icon(Icons.qr_code),
                      ),
                      ButtonSegment(
                        value: PaymentMethod.credit,
                        label: Text('Credit / Khata'),
                        icon: Icon(Icons.account_balance_wallet),
                      ),
                    ],
                    selected: {_paymentMethod},
                    onSelectionChanged: (Set<PaymentMethod> newSelection) {
                      setState(() {
                        _paymentMethod = newSelection.first;
                      });
                    },
                    style: const ButtonStyle(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.standard,
                    ),
                  ),
                  const Gap(24),'''

new_ui = '''                      Text(
                        'Total to Pay',
                        style: theme.textTheme.titleMedium,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\u20b9${total.toStringAsFixed(0)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Gap(8),
                          TextButton.icon(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (ctx) => PlayerSplitPaymentSheet(
                                  playerName: widget.customerName,
                                  totalLiability: total,
                                  initialSplits: _playerPaymentSplits.isNotEmpty 
                                    ? _playerPaymentSplits 
                                    : {_paymentMethod: total},
                                  onSplitsSaved: (newSplits) {
                                    setState(() {
                                      _playerPaymentSplits = newSplits;
                                    });
                                  },
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.call_split, size: 16),
                            label: const Text('Payment Breakdown', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Gap(24),
                  Builder(
                    builder: (context) {
                      final isSplit = _playerPaymentSplits.keys.length > 1;
                      if (isSplit) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _playerPaymentSplits.entries
                                .map((e) => '${e.value.toStringAsFixed(e.value.truncateToDouble() == e.value ? 0 : 2)} ${e.key.displayName}')
                                .join(' + '),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      
                      return SegmentedButton<PaymentMethod>(
                        segments: const [
                          ButtonSegment(value: PaymentMethod.cash, label: Text('Cash'), icon: Icon(Icons.money)),
                          ButtonSegment(value: PaymentMethod.upi, label: Text('UPI / QR'), icon: Icon(Icons.qr_code)),
                          ButtonSegment(value: PaymentMethod.credit, label: Text('Credit / Khata'), icon: Icon(Icons.account_balance_wallet)),
                        ],
                        selected: _playerPaymentSplits.isNotEmpty ? {_playerPaymentSplits.keys.first} : {_paymentMethod},
                        onSelectionChanged: (Set<PaymentMethod> newSelection) {
                          setState(() {
                            _paymentMethod = newSelection.first;
                            _playerPaymentSplits = { newSelection.first: total };
                          });
                        },
                        style: const ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.standard,
                        ),
                      );
                    }
                  ),
                  const Gap(24),'''

content = content.replace(old_ui, new_ui)

# 5. Fix QR Code UPI check
old_qr = '''                  if (_paymentMethod == PaymentMethod.upi &&
                      appSettings != null &&
                      appSettings.business.upiId != null &&
                      appSettings.business.upiId!.isNotEmpty)'''

new_qr = '''                  if ((_playerPaymentSplits.containsKey(PaymentMethod.upi) || _paymentMethod == PaymentMethod.upi) &&
                      appSettings != null &&
                      appSettings.business.upiId != null &&
                      appSettings.business.upiId!.isNotEmpty)'''

content = content.replace(old_qr, new_qr)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched split payment breakdown button')
