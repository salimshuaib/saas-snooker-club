path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\domain\config\pricing_config.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

new_get_price = '''      case TableType.americanPool:
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
      case TableType.ps5:
        switch (billingType) {
          case BillingType.halfHour: return pricingConfig.ps5HalfHour;
          case BillingType.oneHour: return pricingConfig.ps5OneHour;
          default: return null;
        }
      case TableType.pc:
        switch (billingType) {
          case BillingType.halfHour: return pricingConfig.pcHalfHour;
          case BillingType.oneHour: return pricingConfig.pcOneHour;
          default: return null;
        }
      case TableType.carrom:
        switch (billingType) {
          case BillingType.halfHour: return pricingConfig.carromHalfHour;
          case BillingType.oneHour: return pricingConfig.carromOneHour;
          default: return null;
        }
      case TableType.foosball:
        switch (billingType) {
          case BillingType.halfHour: return pricingConfig.foosballHalfHour;
          case BillingType.oneHour: return pricingConfig.foosballOneHour;
          default: return null;
        }
      case TableType.chess:
        switch (billingType) {
          case BillingType.halfHour: return pricingConfig.chessHalfHour;
          case BillingType.oneHour: return pricingConfig.chessOneHour;
          default: return null;
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
    }'''

content = content.replace('''      case TableType.americanPool:
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
    }''', new_get_price)


new_supported_billing = '''      case TableType.americanPool:
        return [BillingType.perFrame, BillingType.perMinute, BillingType.halfHour, BillingType.oneHour];
      case TableType.ps5:
      case TableType.pc:
      case TableType.carrom:
      case TableType.foosball:
      case TableType.chess:
        return [BillingType.halfHour, BillingType.oneHour];
      default:
        return [BillingType.perMinute, BillingType.halfHour, BillingType.oneHour];
    }'''

content = content.replace('''      case TableType.americanPool:
        return [BillingType.perFrame, BillingType.perMinute, BillingType.halfHour, BillingType.oneHour];
      default:
        return [BillingType.perMinute, BillingType.halfHour, BillingType.oneHour];
    }''', new_supported_billing)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
