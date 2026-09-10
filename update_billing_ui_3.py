import sys

path = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix encoding
content = content.replace('Ã¢â€šÂ¹', '₹')
content = content.replace('â,¹', '₹')
content = content.replace('â”€â”€', '──')

start_str = "const Gap(12),"
start_idx = content.find("Text('Discount (Game)', style: theme.textTheme.titleSmall),")
if start_idx == -1:
    print("Cannot find Text('Discount (Game)...")
    sys.exit(1)

# Backtrack to the Gap(12) before it
start_idx = content.rfind(start_str, 0, start_idx)

end_str = "const Divider(height: 16),"
end_idx = content.find(end_str, start_idx)

if start_idx == -1 or end_idx == -1:
    print("Failed to find discount bounds")
    sys.exit(1)

replace_ui = """const Gap(16),
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
                    ),
                    """

content = content[:start_idx] + replace_ui + content[end_idx:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated perfectly")
