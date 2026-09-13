import os

filepath = 'lib/features/games/presentation/screens/bill_details_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

import_stmt = "import 'package:snooker_club/core/providers/app_providers.dart';"
if import_stmt not in text:
    text = text.replace("import 'package:snooker_club/core/providers/club_scope_provider.dart';", "import 'package:snooker_club/core/providers/club_scope_provider.dart';\n" + import_stmt)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
