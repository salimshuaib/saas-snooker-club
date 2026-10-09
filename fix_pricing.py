import sys

with open('lib/features/games/domain/config/pricing_config.dart', 'r', encoding='utf-8') as f:
    c = f.read()

# Normalize newlines
c = c.replace('\r\n', '\n')

s1 = '''    if (gameType == GameType.race) {
      switch (tableType) {
        case TableType.snooker:
          return pricingConfig.snookerRacePerMinute;

        case TableType.indianPool:
          return pricingConfig.indianPoolRacePerMinute;

        case TableType.americanPool:
          return pricingConfig.americanPoolRacePerMinute;

        default:
          return pricingConfig.snookerRacePerMinute;
      }
    } else if (gameType == GameType.rummy && tableType == TableType.snooker) {
      return pricingConfig.snookerRummyPerMinute;
    }

'''
c = c.replace(s1, "")

s2 = '''      if (gameType == GameType.race && billingType == BillingType.perMinute) {
        key = 'racePerMinute';
      } else if (gameType == GameType.rummy &&
          billingType == BillingType.perMinute) {
        key = 'rummyPerMinute';
      } else if (billingType == BillingType.customMinute) {'''
c = c.replace(s2, "      if (billingType == BillingType.customMinute) {")

s3 = '''    if (gameType == GameType.race) {
      if (billingType != BillingType.perMinute) return null;
      switch (tableType) {
        case TableType.snooker:
          return fallbackConfig.snookerRacePerMinute;

        case TableType.indianPool:
          return fallbackConfig.indianPoolRacePerMinute;

        case TableType.americanPool:
          return fallbackConfig.americanPoolRacePerMinute;

        default:
          return fallbackConfig.snookerRacePerMinute;
      }
    } else if (gameType == GameType.rummy) {
      if (billingType != BillingType.perMinute ||
          tableType != TableType.snooker)
        return null;

      return fallbackConfig.snookerRummyPerMinute;
    }

'''
c = c.replace(s3, "")

s4 = '''      if (gameType == GameType.race) {
        if (table.billingOptions!['racePerMinute']?.enabled == true) {
          types.add(BillingType.perMinute);
        }
        return types;
      } else if (gameType == GameType.rummy) {
        if (table.billingOptions!['rummyPerMinute']?.enabled == true) {
          types.add(BillingType.perMinute);
        }
        return types;
      }

'''
c = c.replace(s4, "")

s5 = '''    if (gameType == GameType.race || gameType == GameType.rummy) {
      return [BillingType.perMinute];
    }

'''
c = c.replace(s5, "")

with open('lib/features/games/domain/config/pricing_config.dart', 'w', encoding='utf-8') as f:
    f.write(c)

print('pricing_config.dart fixed')
