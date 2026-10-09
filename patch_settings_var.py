import re

with open('lib/features/settings/presentation/screens/settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = re.sub(
    r"\s*final tables = ref\.watch\(resolvedTablesProvider\);",
    "",
    content
)

with open('lib/features/settings/presentation/screens/settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
