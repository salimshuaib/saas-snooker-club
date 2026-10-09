import re

with open('lib/features/settings/presentation/screens/settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern to remove the Row containing _buildTableCountBadge and the Gap(16) after it
pattern = re.compile(
    r"\s*Row\(\s*mainAxisAlignment: MainAxisAlignment\.spaceEvenly,\s*children: \[\s*_buildTableCountBadge\([\s\S]*?\](?:,\s*)?\s*\),\s*const Gap\(16\),",
    re.MULTILINE
)

new_content = pattern.sub("", content)

with open('lib/features/settings/presentation/screens/settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)
