import sys
import re

path = 'lib/features/games/presentation/screens/combined_settlement_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Make sure we add PlayerSplitPaymentSheet
if "import 'package:snooker_club/features/games/presentation/widgets/player_split_payment_sheet.dart';" not in content:
    content = content.replace("import 'dart:math' as math;", "import 'dart:math' as math;\nimport 'package:snooker_club/features/games/presentation/widgets/player_split_payment_sheet.dart';")

# Replace from "Total to Pay" to the end of SegmentedButton
pattern = re.compile(r"Text\(\s*'Total to Pay'.*?SegmentedButton<PaymentMethod>\(.*?\}\,\s*style:\s*const\s*ButtonStyle\(\s*tapTargetSize:\s*MaterialTapTargetSize\.shrinkWrap\,\s*visualDensity:\s*VisualDensity\.standard\,\s*\)\,\s*\)\,", re.DOTALL)

new_ui = '''Text(
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
                  ),'''

content, count = pattern.subn(new_ui, content)
print(f'Replaced {count} occurrences of UI.')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
