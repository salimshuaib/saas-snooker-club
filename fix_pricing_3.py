import re

with open('lib/features/games/domain/config/pricing_config.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 4. In getPerMinutePrice:
content = re.sub(
    r"if \(gameType == GameType\.race\)\s*\{\s*switch \(tableType\)\s*\{\s*case TableType\.snooker:\s*return pricingConfig\.snookerRacePerMinute;\s*case TableType\.indianPool:\s*return pricingConfig\.indianPoolRacePerMinute;\s*case TableType\.americanPool:\s*return pricingConfig\.americanPoolRacePerMinute;\s*default:\s*return pricingConfig\.snookerRacePerMinute;\s*\}\s*\}\s*else\s*if\s*\(gameType == GameType\.rummy && tableType == TableType\.snooker\)\s*\{\s*return pricingConfig\.snookerRummyPerMinute;\s*\}",
    "",
    content
)

# 5. In getPrice:
content = re.sub(
    r"if \(gameType == GameType\.race && billingType == BillingType\.perMinute\)\s*\{\s*key = 'racePerMinute';\s*\}\s*else\s*if\s*\(gameType == GameType\.rummy &&\s*billingType == BillingType\.perMinute\)\s*\{\s*key = 'rummyPerMinute';\s*\}\s*else\s*if\s*\(billingType == BillingType\.customMinute\)\s*\{",
    "if (billingType == BillingType.customMinute) {",
    content
)


with open('lib/features/games/domain/config/pricing_config.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("done")
