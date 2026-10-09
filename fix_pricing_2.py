import re

with open('lib/features/games/domain/config/pricing_config.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. In getPerMinutePrice:
# if (gameType == GameType.race) { ... } else if (gameType == GameType.rummy) { ... } else { key = 'perMinute'; }
content = re.sub(
    r"if \(gameType == GameType\.race\)\s*\{\s*key = 'racePerMinute';\s*\}\s*else\s*if\s*\(gameType == GameType\.rummy\)\s*\{\s*key = 'rummyPerMinute';\s*\}\s*else\s*\{\s*key = 'perMinute';\s*\}",
    "key = 'perMinute';",
    content
)

# 2. In getPrice:
# if (gameType == GameType.race) { ... } else if (gameType == GameType.rummy) { ... }
content = re.sub(
    r"if \(gameType == GameType\.race\)\s*\{\s*if\s*\(billingType != BillingType\.perMinute\)\s*return null;\s*switch\s*\(tableType\)\s*\{\s*case TableType\.snooker:\s*return fallbackConfig\.snookerRacePerMinute;\s*case TableType\.indianPool:\s*return fallbackConfig\.indianPoolRacePerMinute;\s*case TableType\.americanPool:\s*return fallbackConfig\.americanPoolRacePerMinute;\s*default:\s*return fallbackConfig\.snookerRacePerMinute;\s*\}\s*\}\s*else\s*if\s*\(gameType == GameType\.rummy\)\s*\{\s*if\s*\(billingType != BillingType\.perMinute \|\|\s*tableType != TableType\.snooker\)\s*return null;\s*return fallbackConfig\.snookerRummyPerMinute;\s*\}",
    "",
    content
)

# 3. In _supportedBillingTypesInternal
content = re.sub(
    r"if \(gameType == GameType\.race\)\s*\{\s*if\s*\(table\.billingOptions!\['racePerMinute'\]\?\.enabled == true\)\s*\{\s*types\.add\(BillingType\.perMinute\);\s*\}\s*return types;\s*\}\s*else\s*if\s*\(gameType == GameType\.rummy\)\s*\{\s*if\s*\(table\.billingOptions!\['rummyPerMinute'\]\?\.enabled == true\)\s*\{\s*types\.add\(BillingType\.perMinute\);\s*\}\s*return types;\s*\}",
    "",
    content
)

content = re.sub(
    r"if \(gameType == GameType\.race \|\| gameType == GameType\.rummy\)\s*\{\s*return \[BillingType\.perMinute\];\s*\}",
    "",
    content
)


with open('lib/features/games/domain/config/pricing_config.dart', 'w', encoding='utf-8') as f:
    f.write(content)
