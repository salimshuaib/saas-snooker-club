import re

with open('lib/features/settings/presentation/screens/administrative_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("children: [],,", "children: [],")

with open('lib/features/settings/presentation/screens/administrative_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
