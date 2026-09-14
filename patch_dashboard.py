import os
import re

filepath = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add the import for desktop layout at the top
import_statement = "import 'package:snooker_club/features/dashboard/presentation/screens/desktop_dashboard_layout.dart';\n"
if import_statement not in text:
    # insert after standard flutter imports
    text = text.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_statement)

# 2. Find the build method and intercept isDesktop
# The start of return Scaffold(
# We will inject the check right before it.
target_str = "    return Scaffold("
injection = """    final isDesktopTop = MediaQuery.sizeOf(context).width > 800;
    if (isDesktopTop) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0D14),
        body: DesktopDashboardLayout(employeeName: employeeName),
      );
    }

    return Scaffold("""

text = text.replace(target_str, injection)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
print("SUCCESS")
