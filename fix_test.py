import re

with open('test/pricing_config_test.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the broken parameters
content = re.sub(r"overtimeGraceMinutes:.*?\n", "", content)
content = re.sub(r"matchMakingRules:.*?\n", "", content)
content = re.sub(r"allowNegativeCredit:.*?\n", "", content)
content = re.sub(r"creditLimit:.*?\n", "", content)

with open('test/pricing_config_test.dart', 'w', encoding='utf-8') as f:
    f.write(content)
