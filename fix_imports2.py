import os

filepath = 'lib/features/games/presentation/screens/bill_details_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("import 'package:snooker_club/core/providers/app_providers.dart';", "import 'package:snooker_club/features/settings/providers/settings_providers.dart';")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
