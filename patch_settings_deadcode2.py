import re

with open('lib/features/settings/presentation/screens/settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

pattern = re.compile(
    r"\s*Widget _buildTableCountBadge\([\s\S]*?\)\s*\{\s*return Container\([\s\S]*?\);\s*\}",
    re.MULTILINE
)
new_content = pattern.sub("", content)

with open('lib/features/settings/presentation/screens/settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)
