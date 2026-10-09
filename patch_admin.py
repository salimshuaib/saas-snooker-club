import re

with open('lib/features/settings/presentation/screens/administrative_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the three _buildRateOverviewTile calls to have empty rates.
content = re.sub(
    r"_buildRateOverviewTile\(\s*'Snooker \(Per Min / 1h\)',\s*'[^']+',\s*\)",
    "_buildRateOverviewTile(\n                'Snooker (Per Min / 1h)',\n                '',\n              )",
    content
)

content = re.sub(
    r"_buildRateOverviewTile\(\s*'Indian Pool \(Per Frame / 1h\)',\s*'[^']+',\s*\)",
    "_buildRateOverviewTile(\n                'Indian Pool (Per Frame / 1h)',\n                '',\n              )",
    content
)

content = re.sub(
    r"_buildRateOverviewTile\(\s*'American Pool \(Per Frame / 1h\)',\s*'[^']+',\s*\)",
    "_buildRateOverviewTile(\n                'American Pool (Per Frame / 1h)',\n                '',\n              )",
    content
)

with open('lib/features/settings/presentation/screens/administrative_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

