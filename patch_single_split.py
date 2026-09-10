
import re

with open("lib/features/games/presentation/screens/billing_screen.dart", "r", encoding="utf-8") as f:
    content = f.read()

replacement = """              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Payment Method", style: theme.textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: () {
                      final player = _selectedPayers.isNotEmpty ? _selectedPayers.first : _session.allPlayers.first;
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) => PlayerSplitPaymentSheet(
                          playerName: player,
                          totalLiability: _finalTotal,
                          initialSplits: _playerPaymentSplits[player] ?? {_paymentMethod: _finalTotal},
                          onSplitsSaved: (newSplits) {
                            setState(() {
                              _playerPaymentSplits[player] = newSplits;
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
                    label: const Text("Split"),
                  ),
                ],
              ),
              const Gap(8),
              Builder(
                builder: (context) {
                  final player = _selectedPayers.isNotEmpty ? _selectedPayers.first : _session.allPlayers.first;
                  final splits = _playerPaymentSplits[player] ?? {};
                  final isSplit = splits.keys.length > 1;
                  
                  if (isSplit) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        splits.entries.map((e) => "\\u20B9${e.value.toStringAsFixed(e.value.truncateToDouble() == e.value ? 0 : 2)} ${e.key.displayName}").join(" + "),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  
                  return Row(
                    children: PaymentMethod.values.map((method) {
                      final isSelected = (splits.isEmpty && _paymentMethod == method) || (splits.isNotEmpty && splits.keys.first == method);
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _paymentMethod = method;
                            _playerPaymentSplits[player] = {method: _finalTotal};
                          }),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: method != PaymentMethod.credit ? 8 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: theme.colorScheme.outlineVariant,
                                    ),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(
                                  _paymentIcon(method),
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const Gap(4),
                                Text(
                                  method.displayName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }
              ),"""

content = re.sub(
    r"Text\('Payment Method', style: theme\.textTheme\.titleMedium\),\s*const Gap\(8\),\s*Row\(\s*children: PaymentMethod\.values\.map\(\(method\) {.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?}\)\.toList\(\),\s*\),",
    replacement,
    content,
    flags=re.DOTALL
)

with open("lib/features/games/presentation/screens/billing_screen.dart", "w", encoding="utf-8") as f:
    f.write(content)

