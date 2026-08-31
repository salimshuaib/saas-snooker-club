import re

with open('lib/features/settings/presentation/screens/administrative_settings_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("_buildInfoTile('Club Name', settings.business.clubName),", 
"_buildInfoTile('Club Name', settings.business.clubName),\n                _buildInfoTile('Booking Link Slug', settings.business.slug?.isNotEmpty == true ? settings.business.slug! : 'Not set'),")

with open('lib/features/settings/presentation/screens/administrative_settings_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
