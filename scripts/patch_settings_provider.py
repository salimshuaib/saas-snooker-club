import sys
import re

path = 'lib/features/games/presentation/screens/combined_settlement_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("package:snooker_club/features/settings/providers/settings_provider.dart", "package:snooker_club/features/settings/providers/settings_providers.dart")
content = content.replace("ref.watch(settingsProvider).asData?.value", "ref.watch(appSettingsProvider)")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Patched appSettingsProvider")
