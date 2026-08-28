path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\dashboard\presentation\screens\running_tables_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('''      final breakdown = TablePricingConfig.calculateCharge(
        tableType: table.type,
        gameType: game.gameType,
        billingType: game.billingType,
        activeSeconds: seconds,
        framesPlayed: math.max(game.framesPlayed, game.totalFrames),
        pricingConfig: game.pricingSnapshot ?? appSettings.pricing,
        gameConfig: game.gameSettingsSnapshot ?? appSettings.game,
        completedRounds: game.rounds,
      );''', '''      final breakdown = TablePricingConfig.calculateCharge(
        tableType: table.type,
        gameType: game.gameType,
        billingType: game.billingType,
        activeSeconds: seconds,
        framesPlayed: math.max(game.framesPlayed, game.totalFrames),
        pricingConfig: game.pricingSnapshot ?? appSettings.pricing,
        gameConfig: game.gameSettingsSnapshot ?? appSettings.game,
        completedRounds: game.rounds,
        customPrice: game.customPrice,
      );''')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
