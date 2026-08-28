path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\widgets\game_setup_sheet.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

custom_price_ui = '''
                if (_gameType == GameType.standard && _billingType == BillingType.perMinute) ...[
                  const Gap(24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Set Custom Price', style: theme.textTheme.labelMedium),
                      Switch(
                        value: _isCustomPrice,
                        onChanged: (val) {
                          setState(() {
                            _isCustomPrice = val;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_isCustomPrice) ...[
                    const Gap(8),
                    AppTextField(
                      controller: _customPriceController,
                      hint: 'Custom price per hour',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ],
'''

content = content.replace('                if (_gameType == GameType.standard && _billingType == BillingType.perFrame) ...[', custom_price_ui + '\n                if (_gameType == GameType.standard && _billingType == BillingType.perFrame) ...[')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
