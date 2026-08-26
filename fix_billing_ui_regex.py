import os
import re

path = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

c = re.sub(
    r"Text\(\s*'Grand Total',\s*style: theme.textTheme.titleMedium\?\.copyWith\(\s*fontWeight: FontWeight.w700,\s*\),\s*\),\s*Text\(\s*'[^']*?\$\{_grandTotal\.toStringAsFixed\(2\)\}',\s*style: theme.textTheme.titleLarge\?\.copyWith\(\s*color: AppColors.primary,\s*fontWeight: FontWeight.w700,\s*\),\s*\),",
    """Text(
                        'Calculated Total',
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '₹${_grandTotal.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Final Bill Amount',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: _finalAmountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            prefixText: '₹',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _customSplit.clear();
                            });
                          },
                        ),
                      ),""",
    c,
    flags=re.MULTILINE
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
