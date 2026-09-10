import re

path = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix encoding issues!
content = content.replace('Ã¢â€šÂ¹', '₹')
content = content.replace('â,¹', '₹')
content = content.replace('â”€â”€', '──')
content = content.replace('Ã¢â€šÂ', '') # Cleanup any remaining weird chars

find_discount = r"""                    // ── Discount ──\s*const Gap\(12\),\s*Row\(\s*mainAxisAlignment: MainAxisAlignment\.spaceBetween,\s*children: \[\s*Text\('Discount \(Game\)', style: theme\.textTheme\.titleSmall\),\s*Row\(\s*mainAxisSize: MainAxisSize\.min,\s*children: \[\s*SizedBox\(\s*width: 80,\s*child: TextFormField\(\s*controller: _discountPercentController,\s*keyboardType: TextInputType\.number,\s*textAlign: TextAlign\.right,\s*decoration: InputDecoration\(\s*suffixText: '%',\s*isDense: true,\s*contentPadding: const EdgeInsets\.symmetric\(horizontal: 8, vertical: 8\),\s*border: OutlineInputBorder\(borderRadius: BorderRadius\.circular\(8\)\),\s*\),\s*onChanged: \(val\) \{\s*final percent = double\.tryParse\(val\) \?\? 0\.0;\s*final amount = \(_gameCharge \* \(percent / 100\)\);\s*setState\(\(\) \{\s*_discountAmount = amount;\s*_discountController\.text = amount == 0 \? '' : amount\.toStringAsFixed\(0\);\s*\}\);\s*_initializeLiabilities\(\);\s*\},\s*\),\s*\),\s*const Gap\(8\),\s*SizedBox\(\s*width: 100,\s*child: TextFormField\(\s*controller: _discountController,\s*keyboardType: TextInputType\.number,\s*textAlign: TextAlign\.right,\s*decoration: InputDecoration\(\s*prefixText: '₹',\s*isDense: true,\s*contentPadding: const EdgeInsets\.symmetric\(horizontal: 12, vertical: 8\),\s*border: OutlineInputBorder\(borderRadius: BorderRadius\.circular\(8\)\),\s*\),\s*onChanged: \(val\) \{\s*final amount = double\.tryParse\(val\) \?\? 0\.0;\s*final percent = _gameCharge > 0 \? \(amount / _gameCharge\) \* 100 : 0\.0;\s*setState\(\(\) \{\s*_discountAmount = amount;\s*_discountPercentController\.text = percent == 0 \? '' : percent\.toStringAsFixed\(1\);\s*\}\);\s*_initializeLiabilities\(\);\s*\},\s*\),\s*\),\s*\],\s*\),\s*\],\s*\),"""

replace_discount = """                    // ── Discount ──
                    const Gap(16),
                    Text('Discount (Game Charge)', style: theme.textTheme.titleSmall),
                    const Gap(12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _discountPercentController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Percentage',
                              suffixText: '%',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (val) {
                              final percent = double.tryParse(val) ?? 0.0;
                              final amount = (_gameCharge * (percent / 100));
                              setState(() {
                                _discountAmount = amount;
                                _discountController.text = amount == 0 ? '' : amount.toStringAsFixed(0);
                              });
                              _initializeLiabilities();
                            },
                          ),
                        ),
                        const Gap(16),
                        Expanded(
                          child: TextFormField(
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              prefixText: '₹',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (val) {
                              final amount = double.tryParse(val) ?? 0.0;
                              final percent = _gameCharge > 0 ? (amount / _gameCharge) * 100 : 0.0;
                              setState(() {
                                _discountAmount = amount;
                                _discountPercentController.text = percent == 0 ? '' : percent.toStringAsFixed(1);
                              });
                              _initializeLiabilities();
                            },
                          ),
                        ),
                      ],
                    ),"""

content = re.sub(find_discount, replace_discount, content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated billing screen!")
