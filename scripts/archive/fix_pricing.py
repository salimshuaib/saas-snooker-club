path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\domain\config\pricing_config.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

# getPerMinutePrice race
content = content.replace('''      switch (tableType) {
        case TableType.snooker: return pricingConfig.snookerRacePerMinute;
        case TableType.indianPool: return pricingConfig.indianPoolRacePerMinute;
        case TableType.americanPool: return pricingConfig.americanPoolRacePerMinute;
      }''', '''      switch (tableType) {
        case TableType.snooker: return pricingConfig.snookerRacePerMinute;
        case TableType.indianPool: return pricingConfig.indianPoolRacePerMinute;
        case TableType.americanPool: return pricingConfig.americanPoolRacePerMinute;
        default: return pricingConfig.snookerRacePerMinute;
      }''')

# getPerMinutePrice standard
content = content.replace('''    switch (tableType) {
      case TableType.snooker: return pricingConfig.snookerPerMinute;
      case TableType.indianPool: return pricingConfig.indianPoolPerMinute;
      case TableType.americanPool: return pricingConfig.americanPoolPerMinute;
    }''', '''    switch (tableType) {
      case TableType.snooker: return pricingConfig.snookerPerMinute;
      case TableType.indianPool: return pricingConfig.indianPoolPerMinute;
      case TableType.americanPool: return pricingConfig.americanPoolPerMinute;
      default: return pricingConfig.snookerPerMinute;
    }''')

# getPrice race
content = content.replace('''      switch (tableType) {
        case TableType.snooker: return pricingConfig.snookerRacePerMinute;
        case TableType.indianPool: return pricingConfig.indianPoolRacePerMinute;
        case TableType.americanPool: return pricingConfig.americanPoolRacePerMinute;
      }''', '''      switch (tableType) {
        case TableType.snooker: return pricingConfig.snookerRacePerMinute;
        case TableType.indianPool: return pricingConfig.indianPoolRacePerMinute;
        case TableType.americanPool: return pricingConfig.americanPoolRacePerMinute;
        default: return pricingConfig.snookerRacePerMinute;
      }''')

# getPrice standard
content = content.replace('''        case TableType.americanPool:
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
      }''', '''        case TableType.americanPool:
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
        default:
          switch (billingType) {
            case BillingType.perMinute:
              return pricingConfig.snookerPerMinute;
            case BillingType.halfHour:
              return pricingConfig.snookerHalfHour;
            case BillingType.oneHour:
              return pricingConfig.snookerOneHour;
            case BillingType.perFrame:
              return null;
          }
      }''')

# supportedBillingTypes
content = content.replace('''    switch (tableType) {
      case TableType.snooker:
        return [BillingType.perMinute, BillingType.halfHour, BillingType.oneHour];
      case TableType.indianPool:
        return [BillingType.perFrame, BillingType.perMinute, BillingType.halfHour, BillingType.oneHour]; // Fixed: Indian pool now supports per-minute
      case TableType.americanPool:
        return [BillingType.perFrame, BillingType.perMinute, BillingType.halfHour, BillingType.oneHour];
    }''', '''    switch (tableType) {
      case TableType.snooker:
        return [BillingType.perMinute, BillingType.halfHour, BillingType.oneHour];
      case TableType.indianPool:
        return [BillingType.perFrame, BillingType.perMinute, BillingType.halfHour, BillingType.oneHour]; // Fixed: Indian pool now supports per-minute
      case TableType.americanPool:
        return [BillingType.perFrame, BillingType.perMinute, BillingType.halfHour, BillingType.oneHour];
      default:
        return [BillingType.perMinute, BillingType.halfHour, BillingType.oneHour];
    }''')


with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
