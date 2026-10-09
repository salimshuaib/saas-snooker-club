import sys

path = 'lib/features/games/presentation/screens/pending_bills_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

old_nav = "context.push('${RouteNames.history}/${bill.id}');"
new_nav = """Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BillDetailsScreen(session: bill)),
          );"""

if old_nav in content:
    content = content.replace(old_nav, new_nav)
    # Ensure it's imported
    import_stmt = "import 'package:snooker_club/features/games/presentation/screens/bill_details_screen.dart';"
    if import_stmt not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_stmt)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Patched navigation")
else:
    print("WARNING: Could not find old_nav")
