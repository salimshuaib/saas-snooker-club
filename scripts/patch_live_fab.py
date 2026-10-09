import sys
import re

path = 'lib/features/games/presentation/screens/game_activity_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add the FAB
content = content.replace('      body: Builder(', '      floatingActionButton: const PendingBillsIconBadge(isFab: true),\n      body: Builder(')

# Make sure PendingBillsIconBadge is imported
if 'pending_bills_icon_badge.dart' not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:snooker_club/features/games/presentation/widgets/pending_bills_icon_badge.dart';")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched game_activity_screen.dart')
