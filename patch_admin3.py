import re

with open('lib/features/settings/presentation/screens/administrative_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the three _buildRateOverviewTile calls inside the Pricing Customization card
content = re.sub(
    r"children: \[\s*_buildRateOverviewTile\(\s*'Snooker \(Per Min / 1h\)',\s*'',\s*\),\s*_buildRateOverviewTile\(\s*'Indian Pool \(Per Frame / 1h\)',\s*'',\s*\),\s*_buildRateOverviewTile\(\s*'American Pool \(Per Frame / 1h\)',\s*'',\s*\),\s*\]",
    "children: [],",
    content
)

with open('lib/features/settings/presentation/screens/administrative_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
