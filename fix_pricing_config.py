import os

def fix_pricing_config():
    path = 'lib/features/games/domain/config/pricing_config.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. getPrice signature and logic
    old_get_price = """  /// Returns the price for a given table type and billing type.
  /// Returns null if the combination is not supported.
  static double? getPrice(TableType tableType, BillingType billingType, PricingSettings pricingConfig) {
    switch (tableType) {
      case TableType.snooker:
        switch (billingType) {
          case BillingType.perMinute:
            return pricingConfig.snookerPerMinute;
          case BillingType.halfHour:
            return pricingConfig.snookerHalfHour;
          case BillingType.oneHour:
            return pricingConfig.snookerOneHour;
          case BillingType.perFrame:
            return null; // Snooker does not support per-frame
        }
      case TableType.indianPool:
        switch (billingType) {
          case BillingType.perFrame:
            return pricingConfig.indianPoolPerFrame;
          case BillingType.halfHour:
            return pricingConfig.indianPoolHalfHour;
          case BillingType.oneHour:
            return pricingConfig.indianPoolOneHour;
          case BillingType.perMinute:
            return null; // Indian Pool does not support per-minute
        }
      case TableType.americanPool:
        switch (billingType) {
          case BillingType.perFrame:
            return pricingConfig.americanPoolPerFrame;
          case BillingType.perMinute:
            return pricingConfig.americanPoolPerMinute;
          case BillingType.halfHour:
            return pricingConfig.americanPoolHalfHour;
          case BillingType.oneHour:
            return pricingConfig.americanPoolOneHour;
        }
    }
  }"""
    
    new_get_price = """  /// Returns the price for a given table type, game type, and billing type.
  /// Returns null if the combination is not supported.
  static double? getPrice(TableType tableType, GameType gameType, BillingType billingType, PricingSettings pricingConfig) {
    if (gameType == GameType.race) {
      if (billingType != BillingType.perMinute) return null;
      switch (tableType) {
        case TableType.snooker: return pricingConfig.snookerRacePerMinute;
        case TableType.indianPool: return pricingConfig.indianPoolRacePerMinute;
        case TableType.americanPool: return pricingConfig.americanPoolRacePerMinute;
      }
    } else if (gameType == GameType.rummy) {
      if (billingType != BillingType.perMinute || tableType != TableType.snooker) return null;
      return pricingConfig.snookerRummyPerMinute;
    }

    switch (tableType) {
      case TableType.snooker:
        switch (billingType) {
          case BillingType.perMinute:
            return pricingConfig.snookerPerMinute;
          case BillingType.halfHour:
            return pricingConfig.snookerHalfHour;
          case BillingType.oneHour:
            return pricingConfig.snookerOneHour;
          case BillingType.perFrame:
            return null; // Snooker does not support per-frame
        }
      case TableType.indianPool:
        switch (billingType) {
          case BillingType.perFrame:
            return pricingConfig.indianPoolPerFrame;
          case BillingType.perMinute:
            return pricingConfig.indianPoolPerMinute; // Fixed: Indian Pool now supports per-minute
          case BillingType.halfHour:
            return pricingConfig.indianPoolHalfHour;
          case BillingType.oneHour:
            return pricingConfig.indianPoolOneHour;
        }
      case TableType.americanPool:
        switch (billingType) {
          case BillingType.perFrame:
            return pricingConfig.americanPoolPerFrame;
          case BillingType.perMinute:
            return pricingConfig.americanPoolPerMinute;
          case BillingType.halfHour:
            return pricingConfig.americanPoolHalfHour;
          case BillingType.oneHour:
            return pricingConfig.americanPoolOneHour;
        }
    }
  }"""
    
    content = content.replace(old_get_price, new_get_price)
    
    # 2. getPerMinutePrice
    old_per_min = """  /// Returns the per minute price for a table type (used for overtime).
  static double getPerMinutePrice(TableType tableType, PricingSettings pricingConfig) {
    switch (tableType) {
      case TableType.snooker:
        return pricingConfig.snookerPerMinute;
      case TableType.indianPool:
        return pricingConfig.indianPoolPerMinute;
      case TableType.americanPool:
        return pricingConfig.americanPoolPerMinute;
    }
  }"""
    
    new_per_min = """  /// Returns the per minute price for a table type and game type (used for overtime).
  static double getPerMinutePrice(TableType tableType, GameType gameType, PricingSettings pricingConfig) {
    if (gameType == GameType.race) {
      switch (tableType) {
        case TableType.snooker: return pricingConfig.snookerRacePerMinute;
        case TableType.indianPool: return pricingConfig.indianPoolRacePerMinute;
        case TableType.americanPool: return pricingConfig.americanPoolRacePerMinute;
      }
    } else if (gameType == GameType.rummy && tableType == TableType.snooker) {
      return pricingConfig.snookerRummyPerMinute;
    }
    switch (tableType) {
      case TableType.snooker: return pricingConfig.snookerPerMinute;
      case TableType.indianPool: return pricingConfig.indianPoolPerMinute;
      case TableType.americanPool: return pricingConfig.americanPoolPerMinute;
    }
  }"""
    
    content = content.replace(old_per_min, new_per_min)
    
    # 3. supportedBillingTypes
    old_supported = """  /// Returns all billing types supported by a given table type.
  static List<BillingType> supportedBillingTypes(TableType tableType) {
    switch (tableType) {
      case TableType.snooker:
        return [BillingType.perMinute, BillingType.halfHour, BillingType.oneHour];
      case TableType.indianPool:
        return [BillingType.perFrame, BillingType.halfHour, BillingType.oneHour];
      case TableType.americanPool:
        return [BillingType.perFrame, BillingType.perMinute, BillingType.halfHour, BillingType.oneHour];
    }
  }"""
    
    new_supported = """  /// Returns all billing types supported by a given table type and game type.
  static List<BillingType> supportedBillingTypes(TableType tableType, GameType gameType) {
    if (gameType == GameType.race || gameType == GameType.rummy) {
      return [BillingType.perMinute];
    }
    switch (tableType) {
      case TableType.snooker:
        return [BillingType.perMinute, BillingType.halfHour, BillingType.oneHour];
      case TableType.indianPool:
        return [BillingType.perFrame, BillingType.perMinute, BillingType.halfHour, BillingType.oneHour]; // Fixed: Indian pool now supports per-minute
      case TableType.americanPool:
        return [BillingType.perFrame, BillingType.perMinute, BillingType.halfHour, BillingType.oneHour];
    }
  }"""
    
    content = content.replace(old_supported, new_supported)
    
    # 4. calculateCharge signature and logic
    old_calc = """  static GameChargeBreakdown calculateCharge({
    required TableType tableType,
    required BillingType billingType,
    required int activeSeconds,
    required int framesPlayed,
    required PricingSettings pricingConfig,
    required GameSettings gameConfig,
    List<GameRound> completedRounds = const [],
  }) {
    final price = getPrice(tableType, billingType, pricingConfig);
    if (price == null) {
      return const GameChargeBreakdown(
        baseCharge: 0,
        overtimeMinutes: 0,
        overtimeCharge: 0,
      );
    }

    final double perSecondRate = getPerMinutePrice(tableType, pricingConfig) / 60.0;"""
    
    new_calc = """  static GameChargeBreakdown calculateCharge({
    required TableType tableType,
    required GameType gameType,
    required BillingType billingType,
    required int activeSeconds,
    required int framesPlayed,
    required PricingSettings pricingConfig,
    required GameSettings gameConfig,
    List<GameRound> completedRounds = const [],
  }) {
    final price = getPrice(tableType, gameType, billingType, pricingConfig);
    if (price == null) {
      return const GameChargeBreakdown(
        baseCharge: 0,
        overtimeMinutes: 0,
        overtimeCharge: 0,
      );
    }

    final double perSecondRate = getPerMinutePrice(tableType, gameType, pricingConfig) / 60.0;"""
    
    content = content.replace(old_calc, new_calc)
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_pricing_config()
