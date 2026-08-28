path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\domain\config\pricing_config.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('''    required GameSettings gameConfig,
    List<GameRound> completedRounds = const [],
  }) {
    final price = getPrice(tableType, gameType, billingType, pricingConfig);
    if (price == null) {''', '''    required GameSettings gameConfig,
    List<GameRound> completedRounds = const [],
    double? customPrice,
  }) {
    final price = customPrice ?? getPrice(tableType, gameType, billingType, pricingConfig);
    if (price == null) {''')

content = content.replace('''    final double perSecondRate =
        getPerMinutePrice(tableType, gameType, pricingConfig) / 60.0;
    final bool overtimeEnabled = gameConfig.enableOvertimeBilling;''', '''    final double perMinuteRate = (billingType == BillingType.perMinute && customPrice != null)
        ? customPrice
        : getPerMinutePrice(tableType, gameType, pricingConfig);
    final double perSecondRate = perMinuteRate / 60.0;
    final bool overtimeEnabled = gameConfig.enableOvertimeBilling;''')

content = content.replace('''    required GameSettings gameConfig,
    List<GameRound> completedRounds = const [],
  }) {
    final price = getDynamicPrice(resourcePricing, billingType, gameType);
    if (price == null) {''', '''    required GameSettings gameConfig,
    List<GameRound> completedRounds = const [],
    double? customPrice,
  }) {
    final price = customPrice ?? getDynamicPrice(resourcePricing, billingType, gameType);
    if (price == null) {''')

content = content.replace('''    final double perSecondRate =
        getDynamicPerMinutePrice(resourcePricing, gameType) / 60.0;
    final bool overtimeEnabled = gameConfig.enableOvertimeBilling;''', '''    final double perMinuteRate = (billingType == BillingType.perMinute && customPrice != null)
        ? customPrice
        : getDynamicPerMinutePrice(resourcePricing, gameType);
    final double perSecondRate = perMinuteRate / 60.0;
    final bool overtimeEnabled = gameConfig.enableOvertimeBilling;''')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
