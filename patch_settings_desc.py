import re

with open('lib/features/settings/presentation/screens/settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

pattern2 = re.compile(
    r"\s*Padding\(\s*padding: const EdgeInsets\.symmetric\(vertical: 4\),\s*child: Text\(\s*'Active club pool and snooker tables deployed across the facility:',\s*style: theme\.textTheme\.bodyMedium\?\.copyWith\(\s*color: theme\.colorScheme\.onSurfaceVariant,\s*\),\s*\),\s*\),\s*const Gap\(8\),",
    re.MULTILINE
)
new_content = pattern2.sub("", content)

with open('lib/features/settings/presentation/screens/settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(new_content)
