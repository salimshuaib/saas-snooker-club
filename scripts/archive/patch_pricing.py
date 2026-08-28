path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\domain\config\pricing_config.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    '    final double perSecondRate = getPerMinutePrice(tableType, gameType, pricingConfig) / 60.0;',
    '    final double perSecondRate = (customPrice ?? getPerMinutePrice(tableType, gameType, pricingConfig)) / 60.0;'
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
