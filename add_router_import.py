import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

import_stmt = "import 'package:snooker_club/core/routes/app_router.dart';"
if import_stmt not in text:
    text = text.replace("import 'package:snooker_club/core/theme/app_colors.dart';", "import 'package:snooker_club/core/theme/app_colors.dart';\n" + import_stmt)
    
with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
